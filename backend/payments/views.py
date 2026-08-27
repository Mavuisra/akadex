from decimal import Decimal
import uuid

from django.conf import settings
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import CourseDeposit, CoursePurchase
from .pawapay import PROVIDERS, PawaPayClient, PawaPayError
from .serializers import InitiateDepositSerializer
from .services import (
    apply_remote_status,
    deposit_public_payload,
    grant_course_access,
)


class CatalogPricingView(APIView):
    """GET /api/payments/pricing/ — tarifs catalogue (source de vérité serveur)."""

    permission_classes = [permissions.AllowAny]

    def get(self, request):
        sale = getattr(settings, 'COURSE_SALE_PRICE_USD', Decimal('15'))
        list_price = getattr(settings, 'COURSE_LIST_PRICE_USD', Decimal('29'))
        currency = getattr(settings, 'PAWAPAY_CURRENCY', 'USD')
        return Response(
            {
                'sale_price_usd': str(sale),
                'list_price_usd': str(list_price),
                'currency': currency,
            }
        )


class ProvidersView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        return Response(
            [
                {
                    'key': key,
                    'label': meta['label'],
                    'correspondent': meta['correspondent'],
                }
                for key, meta in PROVIDERS.items()
            ]
        )


class PaymentsHealthView(APIView):
    """GET /api/payments/health/ — diagnostic sans exposer le token."""

    permission_classes = [permissions.AllowAny]

    def get(self, request):
        token = (getattr(settings, 'PAWAPAY_API_TOKEN', '') or '').strip()
        configured = getattr(settings, 'PAWAPAY_BASE_URL', '')
        looks_jwt = token.count('.') == 2 and token.startswith('eyJ')
        resolved = None
        auth_ok = False
        if token:
            try:
                client = PawaPayClient()
                resolved = client.ensure_working_base()
                auth_ok = True
            except PawaPayError:
                auth_ok = False

        return Response(
            {
                'ok': bool(token) and looks_jwt and auth_ok,
                'pawapay_configured': bool(token),
                'token_looks_like_jwt': looks_jwt,
                'base_url_configured': configured,
                'base_url_resolved': resolved,
                'is_sandbox': bool(resolved and 'sandbox' in resolved),
                'currency': getattr(settings, 'PAWAPAY_CURRENCY', 'USD'),
                'country': getattr(settings, 'PAWAPAY_COUNTRY', 'COD'),
                'hint': (
                    None
                    if auth_ok
                    else (
                        'Token refusé. Doc PawaPay : token sandbox → '
                        'api.sandbox.pawapay.io ; token live → api.pawapay.io. '
                        'Dashboards séparés : dashboard.sandbox.pawapay.io vs '
                        'dashboard.pawapay.io.'
                    )
                ),
                'note': (
                    'Sandbox = pas de PIN réel sur téléphone. '
                    'Live = vrai PIN (token production requis).'
                ),
            },
            status=status.HTTP_200_OK if auth_ok else status.HTTP_503_SERVICE_UNAVAILABLE,
        )


class InitiateDepositView(APIView):
    """POST /api/payments/deposits/ — initie un dépôt PawaPay (Mobile Money)."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        ser = InitiateDepositSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        data = ser.validated_data

        client = PawaPayClient()
        if not client.token:
            return Response(
                {
                    'detail': (
                        'PawaPay non configuré sur le serveur. '
                        'Ajoute PAWAPAY_API_TOKEN dans Render → Environment '
                        '(voir backend/.env.render), puis redéploie.'
                    ),
                    'error_code': 'PAWAPAY_NOT_CONFIGURED',
                    'status': 'FAILED',
                },
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        provider_meta = PROVIDERS[data['provider']]
        deposit = CourseDeposit(
            user=request.user if request.user.is_authenticated else None,
            amount=Decimal(str(data['amount'])),
            currency=client.currency,
            phone=data['phone'],
            provider=data['provider'],
            correspondent=provider_meta['correspondent'],
            course_ids=data.get('course_ids') or [],
            status=CourseDeposit.Status.PENDING,
            deposit_id=uuid.uuid4(),
        )
        deposit.save()

        metadata = [
            {'fieldName': 'orderId', 'fieldValue': str(deposit.id)[:36]},
            {'fieldName': 'product', 'fieldValue': 'akadex-course'},
        ]
        if request.user.is_authenticated:
            metadata.append(
                {
                    'fieldName': 'customerId',
                    'fieldValue': str(request.user.id)[:36],
                }
            )

        try:
            result = client.request_deposit(
                phone=data['phone'],
                provider_key=data['provider'],
                amount=float(data['amount']),
                statement=data.get('statement') or 'Akadex cours',
                metadata=metadata,
                deposit_id=str(deposit.deposit_id),
            )
        except PawaPayError as exc:
            deposit.status = CourseDeposit.Status.FAILED
            deposit.failure_message = str(exc)[:500]
            deposit.pawapay_response = (
                exc.payload if isinstance(exc.payload, dict) else {}
            )
            deposit.save(
                update_fields=[
                    'status',
                    'failure_message',
                    'pawapay_response',
                    'updated_at',
                ]
            )
            if exc.status_code in (401, 403):
                detail = (
                    'Token PawaPay refusé (401/403). '
                    'Ton token est probablement sandbox : mets '
                    'PAWAPAY_BASE_URL=https://api.sandbox.pawapay.io sur Render '
                    '(api.pawapay.io = live uniquement).'
                )
                error_code = 'PAWAPAY_AUTH_FAILED'
                http_status = status.HTTP_503_SERVICE_UNAVAILABLE
            elif exc.status_code == 503 or not client.token:
                detail = str(exc)
                error_code = 'PAWAPAY_UNAVAILABLE'
                http_status = status.HTTP_503_SERVICE_UNAVAILABLE
            else:
                detail = str(exc)
                error_code = 'PAWAPAY_REJECTED'
                http_status = status.HTTP_400_BAD_REQUEST

            return Response(
                {
                    'detail': detail,
                    'error_code': error_code,
                    'deposit_id': str(deposit.deposit_id),
                    'status': deposit.status,
                    'pawapay': exc.payload,
                },
                status=http_status,
            )

        pawapay_status = (result.get('status') or '').upper()
        if pawapay_status == 'ACCEPTED':
            deposit.status = CourseDeposit.Status.ACCEPTED
        elif pawapay_status == 'REJECTED':
            deposit.status = CourseDeposit.Status.REJECTED
            reason = result.get('rejectionReason') or {}
            deposit.failure_message = (
                reason.get('rejectionMessage')
                or reason.get('rejectionCode')
                or 'Rejeté par PawaPay'
            )[:500]
        elif pawapay_status in ('COMPLETED', 'COMPLETE'):
            deposit.status = CourseDeposit.Status.COMPLETED
        else:
            deposit.status = CourseDeposit.Status.PENDING

        deposit.pawapay_response = result
        deposit.save()

        if deposit.status == CourseDeposit.Status.COMPLETED:
            grant_course_access(deposit)

        return Response(
            deposit_public_payload(deposit, pawapay_status=pawapay_status),
            status=status.HTTP_200_OK,
        )


class DepositStatusView(APIView):
    """GET /api/payments/deposits/<deposit_id>/ — poll statut PawaPay + grant accès."""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, deposit_id):
        try:
            deposit = CourseDeposit.objects.get(deposit_id=deposit_id)
        except CourseDeposit.DoesNotExist:
            return Response({'detail': 'Dépôt introuvable.'}, status=404)

        if (
            deposit.user_id
            and deposit.user_id != request.user.id
            and not request.user.is_staff
        ):
            return Response({'detail': 'Accès refusé.'}, status=403)

        # Déjà final : renvoyer sans rappeler PawaPay (sauf ACCEPTED à rafraîchir).
        if deposit.status == CourseDeposit.Status.COMPLETED:
            if not deposit.access_granted:
                grant_course_access(deposit)
                deposit.refresh_from_db()
            return Response(deposit_public_payload(deposit))

        if deposit.status in (
            CourseDeposit.Status.FAILED,
            CourseDeposit.Status.REJECTED,
        ):
            return Response(deposit_public_payload(deposit))

        client = PawaPayClient()
        try:
            remote = client.get_deposit(str(deposit.deposit_id))
        except PawaPayError as exc:
            return Response(
                {
                    **deposit_public_payload(deposit),
                    'detail': str(exc),
                },
                status=status.HTTP_502_BAD_GATEWAY,
            )

        item = remote
        if isinstance(remote, list) and remote:
            item = remote[0]
        remote_status = ''
        if isinstance(item, dict):
            remote_status = (item.get('status') or '').upper()

        apply_remote_status(deposit, remote_status, item if isinstance(item, dict) else None)
        deposit.refresh_from_db()
        return Response(
            deposit_public_payload(deposit, pawapay_status=remote_status)
        )


class DepositCallbackView(APIView):
    """POST /api/payments/deposits/callback/ — webhook PawaPay (AllowAny)."""

    permission_classes = [permissions.AllowAny]
    authentication_classes = []

    def post(self, request):
        data = request.data
        if not isinstance(data, dict):
            return Response({'detail': 'Payload invalide.'}, status=400)

        deposit_id = data.get('depositId') or data.get('deposit_id')
        remote_status = (data.get('status') or '').upper()
        if not deposit_id:
            return Response({'detail': 'depositId manquant.'}, status=400)

        try:
            deposit = CourseDeposit.objects.get(deposit_id=deposit_id)
        except (CourseDeposit.DoesNotExist, ValueError):
            # Toujours 200 pour éviter les retries infinis sur id inconnu.
            return Response({'ok': True, 'ignored': True})

        apply_remote_status(deposit, remote_status, data)
        return Response({'ok': True, 'status': deposit.status})


class MyPurchasedCoursesView(APIView):
    """GET /api/payments/my-courses/ — ids des cours achetés."""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        ids = list(
            CoursePurchase.objects.filter(user=request.user).values_list(
                'course_id', flat=True
            )
        )
        return Response({'course_ids': ids, 'count': len(ids)})
