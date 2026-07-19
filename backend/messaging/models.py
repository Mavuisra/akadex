from django.conf import settings
from django.db import models
from django.db.models import Count, Q
from django.utils import timezone


class Conversation(models.Model):
    name = models.CharField(max_length=255, blank=True)
    is_group = models.BooleanField(default=False)
    participants = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        related_name='conversations',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-updated_at']

    def __str__(self):
        if self.is_group and self.name:
            return self.name
        return f'Conversation {self.pk}'

    @classmethod
    def get_or_create_direct(cls, user_a, user_b):
        """Retourne (ou crée) la conversation privée entre deux utilisateurs."""
        if user_a.pk == user_b.pk:
            raise ValueError('Impossible de démarrer une conversation avec soi-même.')
        existing = (
            cls.objects.filter(is_group=False)
            .annotate(n=Count('participants'))
            .filter(n=2)
            .filter(participants=user_a)
            .filter(participants=user_b)
            .first()
        )
        if existing:
            return existing, False
        conv = cls.objects.create(is_group=False)
        conv.participants.add(user_a, user_b)
        return conv, True


class Message(models.Model):
    class Kind(models.TextChoices):
        TEXT = 'text', 'Texte'
        AUDIO = 'audio', 'Vocal'

    class DeliveryStatus(models.TextChoices):
        SENT = 'sent', 'Envoyé'
        DELIVERED = 'delivered', 'Reçu'
        READ = 'read', 'Lu'

    conversation = models.ForeignKey(
        Conversation,
        on_delete=models.CASCADE,
        related_name='messages',
    )
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='sent_messages',
    )
    content = models.TextField(blank=True)
    kind = models.CharField(
        max_length=16,
        choices=Kind.choices,
        default=Kind.TEXT,
        db_index=True,
    )
    attachment = models.FileField(upload_to='chat/', blank=True, null=True)
    audio_duration_ms = models.PositiveIntegerField(default=0)
    delivery_status = models.CharField(
        max_length=16,
        choices=DeliveryStatus.choices,
        default=DeliveryStatus.SENT,
        db_index=True,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    delivered_at = models.DateTimeField(null=True, blank=True)
    read_at = models.DateTimeField(null=True, blank=True)
    is_read = models.BooleanField(default=False)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        preview = self.content[:40] if self.content else f'[{self.kind}]'
        return f'{self.sender}: {preview}'

    def mark_delivered(self):
        if self.delivery_status == self.DeliveryStatus.SENT:
            self.delivery_status = self.DeliveryStatus.DELIVERED
            self.delivered_at = timezone.now()
            self.save(update_fields=['delivery_status', 'delivered_at'])

    def mark_read(self):
        self.is_read = True
        self.delivery_status = self.DeliveryStatus.READ
        self.read_at = timezone.now()
        if not self.delivered_at:
            self.delivered_at = self.read_at
        self.save(
            update_fields=[
                'is_read',
                'delivery_status',
                'read_at',
                'delivered_at',
            ]
        )


class ConversationActivity(models.Model):
    """Indicateurs typing / enregistrement vocal (éphémères)."""

    conversation = models.ForeignKey(
        Conversation,
        on_delete=models.CASCADE,
        related_name='activities',
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='chat_activities',
    )
    is_typing = models.BooleanField(default=False)
    is_recording = models.BooleanField(default=False)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('conversation', 'user')

    @property
    def is_fresh(self):
        return (timezone.now() - self.updated_at).total_seconds() < 6
