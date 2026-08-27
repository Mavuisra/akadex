"""Signaux accounts — push sur nouvelle notification in-app."""

from django.db.models.signals import post_save
from django.dispatch import receiver

from .fcm import send_push_to_user
from .models import AppNotification


@receiver(post_save, sender=AppNotification)
def push_on_app_notification(sender, instance, created, **kwargs):
    if not created:
        return
    data = {
        'kind': instance.kind,
        'notification_id': str(instance.id),
    }
    if instance.link:
        data['route'] = instance.link
        if instance.kind == AppNotification.Kind.MESSAGE and '/messages/chat/' in instance.link:
            cid = instance.link.rsplit('/', 1)[-1]
            if cid.isdigit():
                data['conversation_id'] = cid
    send_push_to_user(
        instance.user,
        title=instance.title,
        body=instance.message,
        data=data,
    )
