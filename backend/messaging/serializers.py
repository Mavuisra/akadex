from django.utils import timezone
from rest_framework import serializers

from accounts.serializers import UserSerializer

from .models import Conversation, ConversationActivity, Message


class MessageSerializer(serializers.ModelSerializer):
    sender_name = serializers.SerializerMethodField()
    sender_avatar = serializers.SerializerMethodField()
    attachment_url = serializers.SerializerMethodField()

    class Meta:
        model = Message
        fields = [
            'id',
            'conversation',
            'sender',
            'sender_name',
            'sender_avatar',
            'content',
            'kind',
            'attachment',
            'attachment_url',
            'audio_duration_ms',
            'delivery_status',
            'created_at',
            'delivered_at',
            'read_at',
            'is_read',
        ]
        read_only_fields = [
            'sender',
            'delivery_status',
            'created_at',
            'delivered_at',
            'read_at',
            'is_read',
        ]

    def get_sender_name(self, obj):
        return obj.sender.get_full_name() or obj.sender.email

    def get_sender_avatar(self, obj):
        request = self.context.get('request')
        if not obj.sender.avatar:
            return ''
        url = obj.sender.avatar.url
        if request is not None:
            return request.build_absolute_uri(url)
        return url

    def get_attachment_url(self, obj):
        if not obj.attachment:
            return ''
        request = self.context.get('request')
        url = obj.attachment.url
        if request is not None:
            return request.build_absolute_uri(url)
        return url


class ConversationActivitySerializer(serializers.ModelSerializer):
    user_name = serializers.SerializerMethodField()

    class Meta:
        model = ConversationActivity
        fields = [
            'user',
            'user_name',
            'is_typing',
            'is_recording',
            'updated_at',
        ]

    def get_user_name(self, obj):
        return obj.user.get_full_name() or obj.user.email


class ConversationSerializer(serializers.ModelSerializer):
    participants_detail = UserSerializer(
        source='participants',
        many=True,
        read_only=True,
    )
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    peer = serializers.SerializerMethodField()
    activities = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = [
            'id',
            'name',
            'is_group',
            'participants',
            'participants_detail',
            'peer',
            'last_message',
            'unread_count',
            'activities',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']

    def get_last_message(self, obj):
        msg = obj.messages.order_by('-created_at').first()
        if not msg:
            return None
        return MessageSerializer(msg, context=self.context).data

    def get_unread_count(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return 0
        return (
            obj.messages.filter(is_read=False)
            .exclude(sender=request.user)
            .count()
        )

    def get_peer(self, obj):
        request = self.context.get('request')
        if not request or obj.is_group:
            return None
        peer = obj.participants.exclude(pk=request.user.pk).first()
        if not peer:
            return None
        data = UserSerializer(peer, context=self.context).data
        # Présence
        if peer.last_seen_at:
            delta = (timezone.now() - peer.last_seen_at).total_seconds()
            data['is_online'] = delta < 90
            data['last_seen_at'] = peer.last_seen_at.isoformat()
        else:
            data['is_online'] = False
            data['last_seen_at'] = None
        return data

    def get_activities(self, obj):
        request = self.context.get('request')
        qs = obj.activities.exclude(
            user=request.user if request else None
        ).select_related('user')
        fresh = [a for a in qs if a.is_fresh and (a.is_typing or a.is_recording)]
        return ConversationActivitySerializer(fresh, many=True).data
