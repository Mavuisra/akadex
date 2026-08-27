from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.mail import send_mail
from django.utils import timezone
from rest_framework import generics, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import AppNotification, PushDeviceToken
from .fcm import send_push_to_user
from .serializers import (
    AppNotificationSerializer,
    PushTokenSerializer,
    RegisterSerializer,
    UserSerializer,
)

User = get_user_model()

_PASSWORD_RESET_OK = (
    'Si un compte est associé à cette adresse, un code de réinitialisation '
    'a été envoyé.'
)


class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]


class MeView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [JSONParser, MultiPartParser, FormParser]

    def get(self, request):
        return Response(UserSerializer(request.user, context={'request': request}).data)

    def patch(self, request):
        serializer = UserSerializer(
            request.user,
            data=request.data,
            partial=True,
            context={'request': request},
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)

    def delete(self, request):
        """Suppression définitive du compte (anonymisation + désactivation)."""
        from .account_deletion import delete_user_account

        delete_user_account(request.user)
        return Response(status=status.HTTP_204_NO_CONTENT)


class ConfirmEmailView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        token = (request.data.get('token') or '').strip()
        user = request.user
        if not token or token != user.email_verification_token:
            return Response(
                {'token': 'Code de vérification invalide.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if not user.pending_email:
            return Response(
                {'detail': 'Aucune demande de changement d’e-mail en cours.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if User.objects.filter(email__iexact=user.pending_email).exclude(
            pk=user.pk
        ).exists():
            return Response(
                {'email': 'Cette adresse e-mail est déjà utilisée.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        user.email = user.pending_email
        user.pending_email = ''
        user.email_verification_token = ''
        user.save(
            update_fields=['email', 'pending_email', 'email_verification_token']
        )
        return Response(UserSerializer(user, context={'request': request}).data)


class PasswordResetRequestView(APIView):
    """Demande un code de réinitialisation (anti-énumération : toujours 200)."""

    permission_classes = [permissions.AllowAny]

    def post(self, request):
        import secrets
        from datetime import timedelta

        email = (request.data.get('email') or '').strip().lower()
        payload = {'detail': _PASSWORD_RESET_OK}

        if not email:
            return Response(
                {'email': 'Indique ton adresse e-mail.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = User.objects.filter(email__iexact=email).first()
        if user is not None:
            code = f'{secrets.randbelow(1_000_000):06d}'
            user.password_reset_token = code
            user.password_reset_expires = timezone.now() + timedelta(hours=1)
            user.save(
                update_fields=['password_reset_token', 'password_reset_expires']
            )
            subject = 'Akadex — réinitialisation du mot de passe'
            body = (
                f'Bonjour,\n\n'
                f'Ton code de réinitialisation Akadex est : {code}\n'
                f'Il expire dans 1 heure.\n\n'
                f'Si tu n’as pas demandé ce code, ignore ce message.\n'
            )
            try:
                send_mail(
                    subject,
                    body,
                    settings.DEFAULT_FROM_EMAIL,
                    [user.email],
                    fail_silently=True,
                )
            except Exception:
                pass
            # Dev / console : exposer le code pour tester sans SMTP.
            if settings.DEBUG:
                payload['dev_code'] = code

        return Response(payload)


class PasswordResetConfirmView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = (request.data.get('email') or '').strip().lower()
        token = (request.data.get('token') or '').strip()
        password = request.data.get('password') or ''
        password_confirm = request.data.get('password_confirm') or ''

        errors = {}
        if not email:
            errors['email'] = 'Indique ton adresse e-mail.'
        if not token:
            errors['token'] = 'Indique le code reçu.'
        if len(password) < 8:
            errors['password'] = 'Le mot de passe doit contenir au moins 8 caractères.'
        if password != password_confirm:
            errors['password_confirm'] = 'Les mots de passe ne correspondent pas.'
        if errors:
            return Response(errors, status=status.HTTP_400_BAD_REQUEST)

        user = User.objects.filter(email__iexact=email).first()
        if (
            user is None
            or not user.password_reset_token
            or user.password_reset_token != token
            or not user.password_reset_expires
            or user.password_reset_expires < timezone.now()
        ):
            return Response(
                {'token': 'Code invalide ou expiré.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user.set_password(password)
        user.password_reset_token = ''
        user.password_reset_expires = None
        user.save(
            update_fields=['password', 'password_reset_token', 'password_reset_expires']
        )
        return Response({'detail': 'Mot de passe mis à jour. Tu peux te connecter.'})


class UserViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = User.objects.select_related(
        'university',
        'faculty',
        'department',
        'promotion',
    )
    serializer_class = UserSerializer
    search_fields = [
        'first_name',
        'last_name',
        'postnom',
        'email',
        'username',
    ]
    filterset_fields = ['role', 'university', 'faculty', 'department', 'level']


class NotificationViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = AppNotificationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return AppNotification.objects.filter(user=self.request.user)

    @action(detail=False, methods=['get'])
    def unread_count(self, request):
        n = self.get_queryset().filter(is_read=False).count()
        return Response({'count': n})

    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        updated = self.get_queryset().filter(is_read=False).update(is_read=True)
        return Response({'updated': updated})

    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        notif = self.get_object()
        notif.is_read = True
        notif.save(update_fields=['is_read'])
        return Response(AppNotificationSerializer(notif).data)


class PushTokenView(APIView):
    """Enregistre ou supprime le token FCM de l'appareil connecté."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = PushTokenSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        token = serializer.validated_data['token']
        platform = serializer.validated_data.get(
            'platform',
            PushDeviceToken.Platform.UNKNOWN,
        )
        PushDeviceToken.objects.update_or_create(
            token=token,
            defaults={'user': request.user, 'platform': platform},
        )
        return Response({'ok': True, 'token': token[:16] + '…'})

    def delete(self, request):
        token = (request.data.get('token') or '').strip()
        qs = PushDeviceToken.objects.filter(user=request.user)
        if token:
            qs = qs.filter(token=token)
        deleted, _ = qs.delete()
        return Response({'ok': True, 'deleted': deleted})


class PushTestView(APIView):
    """Envoie une notification test à l'utilisateur connecté."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        title = (request.data.get('title') or 'Test Akadex').strip()[:120]
        body = (
            request.data.get('body')
            or 'Les notifications push fonctionnent 🎉'
        ).strip()[:500]

        token_count = PushDeviceToken.objects.filter(user=request.user).count()
        if token_count == 0:
            return Response(
                {
                    'detail': (
                        'Aucun appareil enregistré. Ouvre l’app mobile connectée '
                        'pour enregistrer le token FCM.'
                    ),
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        result = send_push_to_user(
            request.user,
            title=title,
            body=body,
            data={'type': 'test'},
        )
        if result.get('error') == 'not_configured':
            return Response(
                {
                    'detail': (
                        'Firebase non configuré côté serveur. '
                        'Ajoute FIREBASE_CREDENTIALS_JSON dans .env / Render.'
                    ),
                },
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        return Response(
            {
                'ok': True,
                'devices': token_count,
                'success': result.get('success', 0),
                'failure': result.get('failure', 0),
            }
        )
