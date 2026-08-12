"""Signaux accounts — push sur nouvelle notification in-app."""

from django.db.models.signals import post_save
from django.dispatch import receiver

from .fcm import send_push_to_user
from .models import AppNotification


@receiver(post_save, sender=AppNotification)
def push_on_app_notification(sender, instance, created, **kwargs):
    if not created:
        return
    send_push_to_user(
        instance.user,
        title=instance.title,
        body=instance.message,
        data={
            'kind': instance.kind,
            'notification_id': str(instance.id),
        },
    )
