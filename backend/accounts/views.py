from django.contrib.auth import get_user_model
from rest_framework import generics, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import AppNotification
from .serializers import (
    AppNotificationSerializer,
    RegisterSerializer,
    UserSerializer,
)

User = get_user_model()


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
