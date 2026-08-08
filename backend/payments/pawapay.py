"""
Client PawaPay Merchant API (v1 deposits).

Le token API ne doit jamais être exposé au client Flutter :
toutes les requêtes passent par cette couche Django.
"""

from __future__ import annotations

import json
import logging
import urllib.error
import urllib.request
from datetime import datetime, timezone
from typing import Any
from uuid import uuid4

from django.conf import settings

logger = logging.getLogger(__name__)

# Opérateurs RD Congo (COD) — codes correspondent PawaPay.
PROVIDERS = {
    'vodacom_mpesa': {
        'label': 'M-Pesa (Vodacom)',
        'correspondent': 'VODACOM_MPESA_COD',
    },
    'airtel': {
        'label': 'Airtel Money',
        'correspondent': 'AIRTEL_COD',
    },
    'orange': {
        'label': 'Orange Money',
        'correspondent': 'ORANGE_COD',
    },
}


class PawaPayError(Exception):
    def __init__(self, message: str, *, status_code: int | None = None, payload: Any = None):
        super().__init__(message)
        self.status_code = status_code
        self.payload = payload


def normalize_msisdn(phone: str, country_prefix: str = '243') -> str:
    """Retourne un MSISDN digits-only (ex. 2438xxxxxxxx)."""
    digits = ''.join(c for c in phone if c.isdigit())
    if not digits:
        raise PawaPayError('Numéro de téléphone invalide.')
    if digits.startswith('00'):
        digits = digits[2:]
    if digits.startswith(country_prefix):
        return digits
    if len(digits) == 9:
        return f'{country_prefix}{digits}'
    if len(digits) == 10 and digits.startswith('0'):
        return f'{country_prefix}{digits[1:]}'
    return digits


def format_amount_usd(amount: float | str) -> str:
    value = float(amount)
    if value <= 0:
        raise PawaPayError('Le montant doit être positif.')
    # USD COD : 2 décimales max.
    return f'{value:.2f}'.rstrip('0').rstrip('.') if value == int(value) else f'{value:.2f}'


class PawaPayClient:
    def __init__(self) -> None:
        self.base_url = getattr(
            settings,
            'PAWAPAY_BASE_URL',
            'https://api.pawapay.io',
        ).rstrip('/')
        self.token = (
            getattr(settings, 'PAWAPAY_API_TOKEN', '') or ''
        ).strip().strip('"').strip("'")
        self.currency = getattr(settings, 'PAWAPAY_CURRENCY', 'USD')
        self.country = getattr(settings, 'PAWAPAY_COUNTRY', 'COD')

    def _headers(self) -> dict[str, str]:
        if not self.token:
            raise PawaPayError(
                'PawaPay non configuré (PAWAPAY_API_TOKEN manquant).',
                status_code=503,
            )
        return {
            'Authorization': f'Bearer {self.token}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        }

    def _request(self, method: str, path: str, body: dict | None = None) -> dict:
        url = f'{self.base_url}{path}'
        data = None if body is None else json.dumps(body).encode('utf-8')
        req = urllib.request.Request(
            url,
            data=data,
            headers=self._headers(),
            method=method,
        )
        try:
            with urllib.request.urlopen(req, timeout=45) as resp:
                raw = resp.read().decode('utf-8')
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as exc:
            raw = exc.read().decode('utf-8', errors='replace')
            try:
                payload = json.loads(raw) if raw else {}
            except json.JSONDecodeError:
                payload = {'raw': raw}
            message = (
                payload.get('errorMessage')
                or payload.get('rejectionMessage')
                or payload.get('message')
                or f'Erreur PawaPay HTTP {exc.code}'
            )
            if isinstance(payload.get('rejectionReason'), dict):
                message = payload['rejectionReason'].get('rejectionMessage') or message
            logger.warning('PawaPay %s %s → %s %s', method, path, exc.code, message)
            raise PawaPayError(str(message), status_code=exc.code, payload=payload) from exc
        except urllib.error.URLError as exc:
            raise PawaPayError(f'Impossible de joindre PawaPay: {exc.reason}') from exc

    def request_deposit(
        self,
        *,
        phone: str,
        provider_key: str,
        amount: float | str,
        statement: str = 'Akadex cours',
        metadata: list[dict] | None = None,
        deposit_id: str | None = None,
    ) -> dict:
        provider = PROVIDERS.get(provider_key)
        if not provider:
            raise PawaPayError('Opérateur Mobile Money inconnu.')

        msisdn = normalize_msisdn(phone)
        amount_str = format_amount_usd(amount)
        deposit_id = deposit_id or str(uuid4())
        # statementDescription : 4–22 alphanumériques + espaces
        clean_statement = ''.join(
            c for c in statement if c.isalnum() or c == ' '
        ).strip()[:22]
        if len(clean_statement) < 4:
            clean_statement = 'Akadex cours'

        body = {
            'depositId': deposit_id,
            'amount': amount_str,
            'currency': self.currency,
            'country': self.country,
            'correspondent': provider['correspondent'],
            'payer': {
                'type': 'MSISDN',
                'address': {'value': msisdn},
            },
            'customerTimestamp': datetime.now(timezone.utc)
            .replace(microsecond=0)
            .isoformat()
            .replace('+00:00', 'Z'),
            'statementDescription': clean_statement,
        }
        if metadata:
            body['metadata'] = metadata

        return self._request('POST', '/deposits', body)

    def get_deposit(self, deposit_id: str) -> dict:
        return self._request('GET', f'/deposits/{deposit_id}')
