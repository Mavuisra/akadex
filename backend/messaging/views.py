from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.response import Response

from .models import Conversation, ConversationActivity, Message
from .serializers import ConversationSerializer, MessageSerializer

User = get_user_model()


def _touch_presence(user):
    User.objects.filter(pk=user.pk).update(last_seen_at=timezone.now())


def _notify_peers_of_message(message: Message) -> None:
    """Notification in-app + push FCM (via signal) aux autres participants."""
    try:
        from accounts.models import AppNotification
    except Exception:
        return

    sender = message.sender
    sender_name = (
        sender.get_full_name() if hasattr(sender, 'get_full_name') else ''
    ) or sender.email or 'Akadex'
    if message.kind == Message.Kind.AUDIO:
        body = 'Message vocal'
    else:
        body = (message.content or '').strip() or 'Nouveau message'
    if len(body) > 120:
        body = body[:117] + '…'

    route = f'/messages/chat/{message.conversation_id}'
    peers = message.conversation.participants.exclude(pk=sender.pk)
    for peer in peers:
        try:
            AppNotification.objects.create(
                user=peer,
                kind=AppNotification.Kind.MESSAGE,
                title=sender_name,
                message=body,
                link=route,
            )
        except Exception:
            # Ne jamais faire échouer l’envoi du message à cause de la notif.
            pass


class ConversationViewSet(viewsets.ModelViewSet):
    serializer_class = ConversationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        _touch_presence(self.request.user)
        return (
            Conversation.objects.filter(participants=self.request.user)
            .prefetch_related('participants', 'messages', 'activities')
            .distinct()
        )

    def perform_create(self, serializer):
        conversation = serializer.save()
        conversation.participants.add(self.request.user)

    @action(detail=False, methods=['post'])
    def start(self, request):
        """Démarre (ou reprend) une conversation privée avec user_id."""
        peer_id = request.data.get('user_id') or request.data.get('user')
        try:
            peer = User.objects.get(pk=peer_id)
        except (User.DoesNotExist, TypeError, ValueError):
            return Response(
                {'user_id': 'Utilisateur introuvable.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if peer.pk == request.user.pk:
            return Response(
                {'user_id': 'Impossible de te contacter toi-même.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        conv, created = Conversation.get_or_create_direct(request.user, peer)
        _touch_presence(request.user)
        return Response(
            ConversationSerializer(conv, context={'request': request}).data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )

    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        conv = self.get_object()
        qs = conv.messages.filter(is_read=False).exclude(sender=request.user)
        now = timezone.now()
        updated = qs.update(
            is_read=True,
            delivery_status=Message.DeliveryStatus.READ,
            read_at=now,
            delivered_at=now,
        )
        _touch_presence(request.user)
        return Response({'updated': updated})

    @action(detail=True, methods=['post'])
    def typing(self, request, pk=None):
        conv = self.get_object()
        is_typing = bool(request.data.get('is_typing', True))
        is_recording = bool(request.data.get('is_recording', False))
        activity, _ = ConversationActivity.objects.update_or_create(
            conversation=conv,
            user=request.user,
            defaults={
                'is_typing': is_typing and not is_recording,
                'is_recording': is_recording,
            },
        )
        _touch_presence(request.user)
        return Response(
            {
                'is_typing': activity.is_typing,
                'is_recording': activity.is_recording,
                'updated_at': activity.updated_at,
            }
        )

    @action(detail=True, methods=['get'])
    def poll(self, request, pk=None):
        """Snapshot léger pour le temps réel (messages récents + activité)."""
        conv = self.get_object()
        after = request.query_params.get('after')
        qs = conv.messages.select_related('sender')
        if after:
            qs = qs.filter(created_at__gt=after)
        # Marquer comme délivrés les messages reçus
        incoming = conv.messages.filter(
            delivery_status=Message.DeliveryStatus.SENT
        ).exclude(sender=request.user)
        incoming.update(
            delivery_status=Message.DeliveryStatus.DELIVERED,
            delivered_at=timezone.now(),
        )
        _touch_presence(request.user)
        return Response(
            {
                'conversation': ConversationSerializer(
                    conv, context={'request': request}
                ).data,
                'messages': MessageSerializer(
                    qs.order_by('created_at')[:100],
                    many=True,
                    context={'request': request},
                ).data,
            }
        )


class MessageViewSet(viewsets.ModelViewSet):
    serializer_class = MessageSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [JSONParser, MultiPartParser, FormParser]
    filterset_fields = ['conversation', 'kind']
    search_fields = ['content']

    def get_queryset(self):
        _touch_presence(self.request.user)
        qs = Message.objects.filter(
            conversation__participants=self.request.user
        ).select_related('sender', 'conversation')
        search = self.request.query_params.get('search')
        if search:
            qs = qs.filter(content__icontains=search.strip())
        return qs

    def perform_create(self, serializer):
        kind = serializer.validated_data.get('kind', Message.Kind.TEXT)
        message = serializer.save(
            sender=self.request.user,
            kind=kind,
            delivery_status=Message.DeliveryStatus.SENT,
        )
        Conversation.objects.filter(pk=message.conversation_id).update(
            updated_at=timezone.now()
        )
        # Effacer typing
        ConversationActivity.objects.filter(
            conversation_id=message.conversation_id,
            user=self.request.user,
        ).update(is_typing=False, is_recording=False)
        _touch_presence(self.request.user)
        _notify_peers_of_message(message)

    def create(self, request, *args, **kwargs):
        # Support multipart vocal
        data = request.data.copy() if hasattr(request.data, 'copy') else dict(request.data)
        if request.FILES.get('attachment') and not data.get('kind'):
            data = {**{k: data.get(k) for k in data.keys()}, 'kind': Message.Kind.AUDIO}
        serializer = self.get_serializer(data=data)
        serializer.is_valid(raise_exception=True)
        conv = serializer.validated_data.get('conversation')
        if conv and not conv.participants.filter(pk=request.user.pk).exists():
            return Response(
                {'detail': 'Accès refusé à cette conversation.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(
            serializer.data,
            status=status.HTTP_201_CREATED,
            headers=headers,
        )
