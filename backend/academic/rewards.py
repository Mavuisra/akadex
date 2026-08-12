"""Constantes et helpers pour le système de points / récompenses."""

from django.contrib.auth import get_user_model
from django.db.models import F

# --- Validation fac + admin ---
FACULTY_PEER_VALIDATIONS_REQUIRED = 10
WHEEL_UNLOCK_POINTS = 100
WHEEL_SPIN_COST = 100

# 10 pts : gros travaux / forte valeur pédagogique
HIGH_TIER_DOC_TYPES = frozenset({
    'tfc',
    'memoire',
    'projet_tutore',
    'resume',
})

# 5 pts : examens, TD, TP, interrogations
LOW_TIER_DOC_TYPES = frozenset({
    'examen',
    'tp',
    'corrige',
    'interrogation',
})

HIGH_TIER_POINTS = 10
LOW_TIER_POINTS = 5
DEFAULT_POINTS = 5

DOC_TYPE_LABELS = {
    'support_cours': 'PDF de cours',
    'resume': 'résumé de cours',
    'fiche_revision': 'fiche de révision',
    'examen': 'examen',
    'corrige': 'TP corrigé',
    'tp': 'TP',
    'interrogation': 'interrogation',
    'tutoriel': 'tutoriel',
    'livre': 'livre',
    'projet': 'projet',
    'memoire': 'mémoire',
    'tfc': 'TFC',
    'projet_tutore': 'projet tuteuré',
    'rapport': 'rapport de stage',
}


def points_for_document(doc_type: str) -> int:
    if doc_type in HIGH_TIER_DOC_TYPES:
        return HIGH_TIER_POINTS
    if doc_type in LOW_TIER_DOC_TYPES:
        return LOW_TIER_POINTS
    return DEFAULT_POINTS


def award_approval_points(document) -> int:
    """Attribue les points après validation admin (une seule fois)."""
    if not document.is_approved or document.points_awarded > 0:
        return 0
    if document.author_id is None:
        return 0

    pts = points_for_document(document.doc_type)
    document.points_awarded = pts
    document.save(update_fields=['points_awarded'])

    User = get_user_model()
    User.objects.filter(pk=document.author_id).update(
        reputation=F('reputation') + pts,
    )

    label = DOC_TYPE_LABELS.get(document.doc_type, 'contribution')
    from accounts.models import AppNotification

    AppNotification.objects.create(
        user_id=document.author_id,
        kind=AppNotification.Kind.DOCUMENT_APPROVED,
        title='Contribution validée',
        message=(
            f'Félicitations ! Votre contribution ({label}) « {document.title} » '
            f'a été validée par l\'équipe Akadex après validation de votre faculté. '
            f'Vous avez obtenu {pts} points.'
        ),
        points=pts,
    )
    return pts
