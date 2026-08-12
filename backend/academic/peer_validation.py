"""Notes fac (1–5 étoiles) par les pairs avant modération admin."""

from decimal import Decimal

from django.contrib.auth import get_user_model
from django.db import transaction
from django.db.models import Avg, Count

from accounts.models import AppNotification

from .models import Document, DocumentPeerValidation
from .rewards import (
    FACULTY_PEER_VALIDATIONS_REQUIRED,
    points_for_document,
)

User = get_user_model()

MIN_SCORE = 1
MAX_SCORE = 5


class PeerValidationError(Exception):
    pass


def document_faculty_id(document: Document):
    """Faculté de référence du document (auteur, puis département)."""
    author = document.author
    if author and author.faculty_id:
        return author.faculty_id
    dept = document.department
    if dept and dept.faculty_id:
        return dept.faculty_id
    return None


def same_faculty(user, document: Document) -> bool:
    fac_doc = document_faculty_id(document)
    fac_user = user.faculty_id
    if not fac_doc or not fac_user:
        return False
    return fac_doc == fac_user


def peer_validation_count(document: Document) -> int:
    return document.peer_validations.count()


def user_rating(user, document: Document) -> int | None:
    if not user.is_authenticated:
        return None
    row = document.peer_validations.filter(validator=user).values_list(
        'score', flat=True
    ).first()
    return int(row) if row is not None else None


def user_has_peer_validated(user, document: Document) -> bool:
    return user_rating(user, document) is not None


def can_peer_validate(user, document: Document) -> bool:
    if not user.is_authenticated:
        return False
    if user.is_staff:
        return False
    if document.is_approved or document.moderation_status == 'rejected':
        return False
    if document.moderation_status not in ('pending_peers', 'pending'):
        return False
    if document.author_id and document.author_id == user.pk:
        return False
    if not same_faculty(user, document):
        return False
    if user_has_peer_validated(user, document):
        return False
    return True


def _sync_document_rating_stats(document: Document) -> None:
    agg = document.peer_validations.aggregate(
        avg=Avg('score'),
        count=Count('id'),
    )
    count = int(agg['count'] or 0)
    avg = agg['avg']
    document.rating_count = count
    document.rating_avg = Decimal(str(round(float(avg), 2))) if avg is not None else Decimal('0')
    document.save(update_fields=['rating_avg', 'rating_count', 'updated_at'])


def _notify_author_peer_milestone(
    document: Document, validator, score: int, count: int,
) -> None:
    if not document.author_id:
        return
    rater = validator.get_full_name() or validator.email
    if count >= FACULTY_PEER_VALIDATIONS_REQUIRED:
        AppNotification.objects.create(
            user_id=document.author_id,
            kind=AppNotification.Kind.GENERAL,
            title='10 notes fac reçues',
            message=(
                f'« {document.title} » a atteint {count} notes. '
                'Un administrateur Akadex va maintenant examiner ton document.'
            ),
        )
    else:
        AppNotification.objects.create(
            user_id=document.author_id,
            kind=AppNotification.Kind.GENERAL,
            title='Nouvelle note sur ton document',
            message=(
                f'{rater} a noté « {document.title} » ({score}/5). '
                f'Progression : {count}/{FACULTY_PEER_VALIDATIONS_REQUIRED} notes fac.'
            ),
        )


@transaction.atomic
def peer_rate_document(user, document: Document, score: int) -> Document:
    if score < MIN_SCORE or score > MAX_SCORE:
        raise PeerValidationError('La note doit être entre 1 et 5 étoiles.')

    if not can_peer_validate(user, document):
        raise PeerValidationError(
            'Tu ne peux pas noter ce document '
            '(faculté différente, déjà noté, ou document non éligible).',
        )

    DocumentPeerValidation.objects.create(
        document=document,
        validator=user,
        score=score,
    )

    _sync_document_rating_stats(document)

    count = peer_validation_count(document)
    update_fields = ['updated_at']

    if document.moderation_status == 'pending':
        document.moderation_status = 'pending_peers'
        update_fields.append('moderation_status')

    if count >= FACULTY_PEER_VALIDATIONS_REQUIRED:
        document.moderation_status = 'pending_admin'
        update_fields.append('moderation_status')
        _notify_author_peer_milestone(document, user, score, count)
    else:
        _notify_author_peer_milestone(document, user, score, count)

    document.save(update_fields=update_fields)
    return document


def peer_validate_document(user, document: Document, score: int = 5) -> Document:
    """Compatibilité : ancienne validation = note 5 étoiles."""
    return peer_rate_document(user, document, score)


def peer_review_queue_for(user, limit: int = 30):
    """Documents en attente de notes par les pairs (même faculté)."""
    fac_id = user.faculty_id
    if not fac_id:
        return Document.objects.none()

    qs = (
        Document.objects.filter(
            moderation_status__in=('pending_peers', 'pending'),
            is_approved=False,
        )
        .exclude(author=user)
        .exclude(peer_validations__validator=user)
        .select_related('author', 'department', 'department__faculty', 'university')
        .annotate(_peer_count=Count('peer_validations'))
    )

    from django.db.models import Q

    qs = qs.filter(
        Q(author__faculty_id=fac_id)
        | Q(department__faculty_id=fac_id),
    ).order_by('_peer_count', '-created_at')[:limit]

    return qs


def potential_points_for(document: Document) -> int:
    return points_for_document(document.doc_type)
