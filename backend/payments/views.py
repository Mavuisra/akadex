from decimal import Decimal

from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import CourseDeposit
from .pawapay import PROVIDERS, PawaPayClient, PawaPayError
from .serializers import InitiateDepositSerializer


class ProvidersView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        return Response(
            [
                {'key': key, 'label': meta['label'], 'correspondent': meta['correspondent']}
                for key, meta in PROVIDERS.items()
            ]
        )


class InitiateDepositView(APIView):
    """POST /api/payments/deposits/ — initie un dépôt PawaPay (Mobile Money)."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        ser = InitiateDepositSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        data = ser.validated_data

        client = PawaPayClient()
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
        )
        # deposit_id = PK PawaPay (UUID) — on le génère avant l’appel.
        import uuid

        deposit.deposit_id = uuid.uuid4()
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
            deposit.pawapay_response = exc.payload if isinstance(exc.payload, dict) else {}
            deposit.save(
                update_fields=[
                    'status',
                    'failure_message',
                    'pawapay_response',
                    'updated_at',
                ]
            )
            code = (
                status.HTTP_503_SERVICE_UNAVAILABLE
                if exc.status_code in (401, 403, 503)
                else status.HTTP_400_BAD_REQUEST
            )
            return Response(
                {
                    'detail': str(exc),
                    'deposit_id': str(deposit.deposit_id),
                    'status': deposit.status,
                    'pawapay': exc.payload,
                },
                status=code,
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
        else:
            deposit.status = CourseDeposit.Status.PENDING

        deposit.pawapay_response = result
        deposit.save()

        return Response(
            {
                'deposit_id': str(deposit.deposit_id),
                'local_id': str(deposit.id),
                'status': deposit.status,
                'pawapay_status': pawapay_status,
                'amount': str(deposit.amount),
                'currency': deposit.currency,
                'provider': deposit.provider,
                'phone': deposit.phone,
                'message': (
                    'Demande envoyée. Validez le paiement sur votre téléphone.'
                    if deposit.status == CourseDeposit.Status.ACCEPTED
                    else deposit.failure_message or 'Statut en attente.'
                ),
            },
            status=status.HTTP_200_OK,
        )


class DepositStatusView(APIView):
    """GET /api/payments/deposits/<deposit_id>/ — poll statut PawaPay."""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, deposit_id):
        try:
            deposit = CourseDeposit.objects.get(deposit_id=deposit_id)
        except CourseDeposit.DoesNotExist:
            return Response({'detail': 'Dépôt introuvable.'}, status=404)

        if deposit.user_id and deposit.user_id != request.user.id and not request.user.is_staff:
            return Response({'detail': 'Accès refusé.'}, status=403)

        client = PawaPayClient()
        try:
            remote = client.get_deposit(str(deposit.deposit_id))
        except PawaPayError as exc:
            return Response(
                {
                    'deposit_id': str(deposit.deposit_id),
                    'status': deposit.status,
                    'detail': str(exc),
                },
                status=status.HTTP_502_BAD_GATEWAY,
            )

        # Réponse v1 : souvent une liste [{ status, depositId, ... }]
        item = remote
        if isinstance(remote, list) and remote:
            item = remote[0]
        remote_status = ''
        if isinstance(item, dict):
            remote_status = (item.get('status') or '').upper()
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
            deposit.status = CourseDeposit.Status.ACCEPTED

        deposit.save(update_fields=['status', 'pawapay_response', 'failure_message', 'updated_at'])

        return Response(
            {
                'deposit_id': str(deposit.deposit_id),
                'status': deposit.status,
                'pawapay_status': remote_status,
                'amount': str(deposit.amount),
                'currency': deposit.currency,
                'provider': deposit.provider,
                'phone': deposit.phone,
                'failure_message': deposit.failure_message,
            }
        )
