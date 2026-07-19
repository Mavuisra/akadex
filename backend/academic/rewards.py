"""Constantes et helpers pour le système de points / récompenses."""

from django.contrib.auth import get_user_model
from django.db.models import F

# Points accordés quand un document est validé (qualité).
DOCUMENT_APPROVAL_POINTS = {
    'support_cours': 40,
    'resume': 25,
    'fiche_revision': 30,
    'examen': 35,
    'corrige': 35,
    'tp': 30,
    'interrogation': 20,
    'tutoriel': 25,
    'livre': 50,
    'projet': 30,
    'memoire': 45,
    'default': 20,
}

WHEEL_UNLOCK_POINTS = 100

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
}


def points_for_document(doc_type: str) -> int:
    return DOCUMENT_APPROVAL_POINTS.get(
        doc_type,
        DOCUMENT_APPROVAL_POINTS['default'],
    )


def award_approval_points(document) -> int:
    """Attribue les points de validation une seule fois par document."""
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
            f'a été validée. Vous avez obtenu {pts} points. '
            'Continuez à partager des ressources de qualité pour aider '
            'la communauté universitaire.'
        ),
        points=pts,
    )
    return pts
