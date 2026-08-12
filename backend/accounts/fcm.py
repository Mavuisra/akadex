"""Envoi de push notifications via Firebase Cloud Messaging."""

from __future__ import annotations

import json
import logging
import os
from typing import Any

from django.conf import settings

logger = logging.getLogger(__name__)


def _get_firebase_app():
    try:
        import firebase_admin
        from firebase_admin import credentials
    except ImportError:
        logger.warning('firebase-admin non installé')
        return None

    if firebase_admin._apps:
        return firebase_admin.get_app()

    cred_json = getattr(settings, 'FIREBASE_CREDENTIALS_JSON', '') or ''
    cred_path = getattr(settings, 'FIREBASE_CREDENTIALS_PATH', '') or ''

    if cred_json.strip():
        cred = credentials.Certificate(json.loads(cred_json))
    elif cred_path and os.path.isfile(cred_path):
        cred = credentials.Certificate(cred_path)
    else:
        logger.warning('Credentials Firebase non configurés (FIREBASE_CREDENTIALS_JSON)')
        return None

    return firebase_admin.initialize_app(cred)


def send_push_to_tokens(
    tokens: list[str],
    *,
    title: str,
    body: str,
    data: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Envoie une notification à une liste de tokens FCM."""
    if not tokens:
        return {'success': 0, 'failure': 0, 'invalid_tokens': []}

    app = _get_firebase_app()
    if app is None:
        return {
            'success': 0,
            'failure': len(tokens),
            'invalid_tokens': [],
            'error': 'not_configured',
        }

    from firebase_admin import messaging
    from firebase_admin.exceptions import FirebaseError

    payload = {k: str(v) for k, v in (data or {}).items()}
    message = messaging.MulticastMessage(
        notification=messaging.Notification(title=title, body=body),
        data=payload,
        tokens=tokens,
    )

    try:
        response = messaging.send_each_for_multicast(message, app=app)
    except FirebaseError as exc:
        logger.exception('Erreur FCM: %s', exc)
        return {
            'success': 0,
            'failure': len(tokens),
            'invalid_tokens': [],
            'error': str(exc),
        }

    invalid: list[str] = []
    for idx, item in enumerate(response.responses):
        if item.success:
            continue
        exc = item.exception
        code = getattr(exc, 'code', '') or ''
        if code in ('NOT_FOUND', 'UNREGISTERED', 'INVALID_ARGUMENT'):
            invalid.append(tokens[idx])

    return {
        'success': response.success_count,
        'failure': response.failure_count,
        'invalid_tokens': invalid,
    }


def send_push_to_user(
    user,
    *,
    title: str,
    body: str,
    data: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Envoie une push à tous les appareils d'un utilisateur."""
    from .models import PushDeviceToken

    tokens = list(
        PushDeviceToken.objects.filter(user=user).values_list('token', flat=True)
    )
    result = send_push_to_tokens(tokens, title=title, body=body, data=data)
    invalid = result.pop('invalid_tokens', [])
    if invalid:
        PushDeviceToken.objects.filter(token__in=invalid).delete()
    return result
