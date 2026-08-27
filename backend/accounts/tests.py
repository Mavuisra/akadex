from datetime import timedelta

from django.contrib.auth import get_user_model
from django.test import TestCase, override_settings
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient

User = get_user_model()


class PasswordResetApiTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='isra',
            email='isra@unikin.ac.cd',
            password='AncienMdp123!',
            first_name='Isra',
        )

    def test_request_unknown_email_still_ok(self):
        res = self.client.post(
            reverse('password-reset'),
            {'email': 'inconnu@example.com'},
            format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn('detail', res.data)
        self.assertNotIn('dev_code', res.data)

    @override_settings(DEBUG=True)
    def test_request_and_confirm_flow(self):
        res = self.client.post(
            reverse('password-reset'),
            {'email': 'isra@unikin.ac.cd'},
            format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        code = res.data.get('dev_code')
        self.assertTrue(code and len(code) == 6)

        self.user.refresh_from_db()
        self.assertEqual(self.user.password_reset_token, code)

        bad = self.client.post(
            reverse('password-reset-confirm'),
            {
                'email': 'isra@unikin.ac.cd',
                'token': '000000',
                'password': 'NouveauMdp123!',
                'password_confirm': 'NouveauMdp123!',
            },
            format='json',
        )
        self.assertEqual(bad.status_code, status.HTTP_400_BAD_REQUEST)

        ok = self.client.post(
            reverse('password-reset-confirm'),
            {
                'email': 'isra@unikin.ac.cd',
                'token': code,
                'password': 'NouveauMdp123!',
                'password_confirm': 'NouveauMdp123!',
            },
            format='json',
        )
        self.assertEqual(ok.status_code, status.HTTP_200_OK)
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password('NouveauMdp123!'))
        self.assertEqual(self.user.password_reset_token, '')

    def test_expired_token_rejected(self):
        self.user.password_reset_token = '123456'
        self.user.password_reset_expires = timezone.now() - timedelta(minutes=1)
        self.user.save()
        res = self.client.post(
            reverse('password-reset-confirm'),
            {
                'email': 'isra@unikin.ac.cd',
                'token': '123456',
                'password': 'NouveauMdp123!',
                'password_confirm': 'NouveauMdp123!',
            },
            format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)


class ConfirmEmailApiTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='isra2',
            email='old@unikin.ac.cd',
            password='Secret123!',
            first_name='Isra',
        )
        self.user.pending_email = 'new@unikin.ac.cd'
        self.user.email_verification_token = 'tok-confirm-abc'
        self.user.save()
        self.client.force_authenticate(self.user)

    def test_confirm_email_ok(self):
        res = self.client.post(
            reverse('confirm-email'),
            {'token': 'tok-confirm-abc'},
            format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.user.refresh_from_db()
        self.assertEqual(self.user.email, 'new@unikin.ac.cd')
        self.assertEqual(self.user.pending_email, '')
        self.assertEqual(self.user.email_verification_token, '')

    def test_confirm_email_bad_token(self):
        res = self.client.post(
            reverse('confirm-email'),
            {'token': 'wrong'},
            format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)


class AccountDeletionTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='todelete',
            email='todelete@unikin.ac.cd',
            password='Secret123!',
            first_name='Jean',
            last_name='Kabila',
            phone='243800000001',
        )
        self.client.force_authenticate(self.user)

    def test_delete_me_anonymizes_and_deactivates(self):
        uid = self.user.pk
        res = self.client.delete(reverse('me'))
        self.assertEqual(res.status_code, status.HTTP_204_NO_CONTENT)
        self.user.refresh_from_db()
        self.assertFalse(self.user.is_active)
        self.assertEqual(self.user.email, f'deleted+{uid}@deleted.akadex.local')
        self.assertEqual(self.user.phone, '')
        self.assertFalse(self.user.has_usable_password())

    def test_deleted_user_cannot_login(self):
        self.client.delete(reverse('me'))
        self.client.force_authenticate(user=None)
        res = self.client.post(
            reverse('token_obtain_pair'),
            {'email': 'todelete@unikin.ac.cd', 'password': 'Secret123!'},
            format='json',
        )
        self.assertIn(res.status_code, (status.HTTP_401_UNAUTHORIZED, status.HTTP_400_BAD_REQUEST))
