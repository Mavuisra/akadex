"""Logique métier paiements : sync statut + déblocage cours (idempotent)."""

from __future__ import annotations

import logging

from django.db import transaction

from academic.models import Course

from .models import CourseDeposit, CoursePurchase

logger = logging.getLogger(__name__)


def apply_remote_status(deposit: CourseDeposit, remote_status: str, item=None) -> CourseDeposit:
    """Met à jour le statut local depuis PawaPay et débloque l’accès si COMPLETED."""
    remote_status = (remote_status or '').upper()
    if isinstance(item, dict):
        deposit.pawapay_response = item

    if remote_status in ('COMPLETED', 'COMPLETE'):
        deposit.status = CourseDeposit.Status.COMPLETED
    elif remote_status in ('FAILED', 'REJECTED'):
        deposit.status = (
            CourseDeposit.Status.FAILED
            if remote_status == 'FAILED'
            else CourseDeposit.Status.REJECTED
        )
        if isinstance(item, dict):
            fr = item.get('failureReason') or item.get('rejectionReason') or {}
            if isinstance(fr, dict):
                deposit.failure_message = (
                    fr.get('failureMessage')
                    or fr.get('rejectionMessage')
                    or remote_status
                )[:500]
    elif remote_status in ('ACCEPTED', 'SUBMITTED', 'PROCESSING', 'PENDING'):
        if deposit.status != CourseDeposit.Status.COMPLETED:
            deposit.status = CourseDeposit.Status.ACCEPTED

    deposit.save(
        update_fields=[
            'status',
            'pawapay_response',
            'failure_message',
            'updated_at',
        ]
    )

    if deposit.status == CourseDeposit.Status.COMPLETED:
        grant_course_access(deposit)

    return deposit


def grant_course_access(deposit: CourseDeposit) -> list[int]:
    """Crée les CoursePurchase pour les course_ids du dépôt. Idempotent."""
    if deposit.status != CourseDeposit.Status.COMPLETED:
        return []
    if not deposit.user_id:
        logger.warning('Deposit %s COMPLETED sans user — pas d’accès.', deposit.deposit_id)
        return []

    first_grant = False
    granted: list[int] = []

    with transaction.atomic():
        locked = (
            CourseDeposit.objects.select_for_update()
            .filter(pk=deposit.pk)
            .first()
        )
        if locked is None:
            return []
        if locked.access_granted:
            return list(
                CoursePurchase.objects.filter(deposit=locked).values_list(
                    'course_id', flat=True
                )
            )

        raw_ids = locked.course_ids or []
        for raw in raw_ids:
            try:
                cid = int(raw)
            except (TypeError, ValueError):
                continue
            if not Course.objects.filter(pk=cid).exists():
                logger.warning(
                    'Deposit %s: course_id %s inconnu, ignoré.',
                    locked.deposit_id,
                    raw,
                )
                continue
            CoursePurchase.objects.get_or_create(
                user_id=locked.user_id,
                course_id=cid,
                defaults={'deposit': locked},
            )
            granted.append(cid)

        locked.access_granted = True
        locked.save(update_fields=['access_granted', 'updated_at'])
        deposit.access_granted = True
        first_grant = True
        granted_count = len(granted)
        notify_user_id = locked.user_id

    if first_grant:
        try:
            from accounts.models import AppNotification

            AppNotification.objects.create(
                user_id=notify_user_id,
                kind=AppNotification.Kind.PAYMENT,
                title='Paiement confirmé',
                message=(
                    f'Accès débloqué pour {granted_count} cours.'
                    if granted_count > 1
                    else 'Accès au cours débloqué.'
                ),
                link='/learn',
            )
        except Exception:
            logger.exception(
                'Notification paiement échouée (deposit %s)',
                deposit.deposit_id,
            )

    return granted


def deposit_public_payload(deposit: CourseDeposit, *, pawapay_status: str = '', message: str = '') -> dict:
    granted_ids = list(
        CoursePurchase.objects.filter(deposit=deposit).values_list('course_id', flat=True)
    )
    if not granted_ids and deposit.access_granted and deposit.user_id:
        granted_ids = list(
            CoursePurchase.objects.filter(
                user_id=deposit.user_id,
                course_id__in=[
                    int(x)
                    for x in (deposit.course_ids or [])
                    if str(x).isdigit()
                ],
            ).values_list('course_id', flat=True)
        )

    if not message:
        if deposit.status == CourseDeposit.Status.COMPLETED:
            message = 'Paiement confirmé. Accès aux cours débloqué.'
        elif deposit.status == CourseDeposit.Status.ACCEPTED:
            message = 'Demande envoyée. Validez le paiement sur votre téléphone.'
        elif deposit.status in (
            CourseDeposit.Status.FAILED,
            CourseDeposit.Status.REJECTED,
        ):
            message = deposit.failure_message or 'Paiement échoué.'
        else:
            message = 'Statut en attente.'

    return {
        'deposit_id': str(deposit.deposit_id),
        'local_id': str(deposit.id),
        'status': deposit.status,
        'pawapay_status': pawapay_status or deposit.status,
        'amount': str(deposit.amount),
        'currency': deposit.currency,
        'provider': deposit.provider,
        'phone': deposit.phone,
        'course_ids': deposit.course_ids or [],
        'granted_course_ids': granted_ids,
        'access_granted': deposit.access_granted,
        'failure_message': deposit.failure_message,
        'message': message,
    }
