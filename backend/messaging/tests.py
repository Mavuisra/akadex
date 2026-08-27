from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

from messaging.models import Conversation, Message

User = get_user_model()


class MessagingRealtimeTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.a = User.objects.create_user(
            username='alice',
            email='alice@unikin.ac.cd',
            password='Secret123!',
            first_name='Alice',
        )
        self.b = User.objects.create_user(
            username='bob',
            email='bob@unikin.ac.cd',
            password='Secret123!',
            first_name='Bob',
        )
        self.conv, _ = Conversation.get_or_create_direct(self.a, self.b)
        self.client.force_authenticate(self.a)

    @patch('accounts.signals.send_push_to_user')
    def test_create_message_notifies_peer(self, send_push):
        from accounts.models import AppNotification

        send_push.return_value = {'success': 1, 'failure': 0}
        res = self.client.post(
            reverse('message-list'),
            {
                'conversation': self.conv.pk,
                'content': 'Salut Bob',
                'kind': 'text',
            },
            format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Message.objects.count(), 1)
        notif = AppNotification.objects.filter(
            user=self.b, kind=AppNotification.Kind.MESSAGE
        ).first()
        self.assertIsNotNone(notif)
        self.assertIn('/messages/chat/', notif.link)
        self.assertTrue(send_push.called)
        kwargs = send_push.call_args.kwargs
        self.assertEqual(kwargs['data']['kind'], 'message')
        self.assertIn('/messages/chat/', kwargs['data']['route'])

    def test_poll_after_returns_only_new(self):
        m1 = Message.objects.create(
            conversation=self.conv,
            sender=self.a,
            content='un',
            kind=Message.Kind.TEXT,
        )
        m2 = Message.objects.create(
            conversation=self.conv,
            sender=self.b,
            content='deux',
            kind=Message.Kind.TEXT,
        )
        url = reverse('conversation-poll', kwargs={'pk': self.conv.pk})
        res = self.client.get(url, {'after': m1.created_at.isoformat()})
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        ids = [row['id'] for row in res.data['messages']]
        self.assertNotIn(m1.pk, ids)
        self.assertIn(m2.pk, ids)
