from decimal import Decimal
from unittest.mock import MagicMock, patch
import uuid

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

from academic.models import Course, Department, Faculty, University
from payments.models import CourseDeposit, CoursePurchase
from payments.services import apply_remote_status, grant_course_access

User = get_user_model()


class PaymentAccessTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='buyer',
            email='buyer@unikin.ac.cd',
            password='Secret123!',
            first_name='Buyer',
        )
        uni = University.objects.create(name='UNIKIN', slug='unikin')
        fac = Faculty.objects.create(university=uni, name='Sciences', slug='sciences')
        dept = Department.objects.create(faculty=fac, name='Info', slug='info')
        self.course = Course.objects.create(
            department=dept,
            code='INF101',
            title='Algo',
        )
        self.deposit = CourseDeposit.objects.create(
            deposit_id=uuid.uuid4(),
            user=self.user,
            amount=Decimal('15.00'),
            currency='USD',
            phone='243800000000',
            provider='vodacom_mpesa',
            status=CourseDeposit.Status.ACCEPTED,
            course_ids=[str(self.course.id)],
        )
        self.client.force_authenticate(self.user)

    def test_grant_on_completed(self):
        from accounts.models import AppNotification

        self.deposit.status = CourseDeposit.Status.COMPLETED
        self.deposit.save(update_fields=['status'])
        granted = grant_course_access(self.deposit)
        self.assertEqual(granted, [self.course.id])
        self.deposit.refresh_from_db()
        self.assertTrue(self.deposit.access_granted)
        self.assertTrue(
            CoursePurchase.objects.filter(
                user=self.user, course=self.course
            ).exists()
        )
        self.assertTrue(
            AppNotification.objects.filter(
                user=self.user, kind=AppNotification.Kind.PAYMENT
            ).exists()
        )
        # Idempotent
        granted2 = grant_course_access(self.deposit)
        self.assertEqual(granted2, [self.course.id])
        self.assertEqual(CoursePurchase.objects.count(), 1)
        self.assertEqual(
            AppNotification.objects.filter(
                user=self.user, kind=AppNotification.Kind.PAYMENT
            ).count(),
            1,
        )

    def test_accepted_does_not_grant(self):
        grant_course_access(self.deposit)
        self.assertFalse(self.deposit.access_granted)
        self.assertEqual(CoursePurchase.objects.count(), 0)

    @patch('payments.views.PawaPayClient')
    def test_poll_completed_grants_and_returns_ids(self, client_cls):
        mock = MagicMock()
        client_cls.return_value = mock
        mock.get_deposit.return_value = {
            'depositId': str(self.deposit.deposit_id),
            'status': 'COMPLETED',
        }
        url = reverse(
            'payment-deposit-status',
            kwargs={'deposit_id': self.deposit.deposit_id},
        )
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['status'], 'COMPLETED')
        self.assertTrue(res.data['access_granted'])
        self.assertIn(self.course.id, res.data['granted_course_ids'])
        self.assertTrue(
            CoursePurchase.objects.filter(
                user=self.user, course=self.course
            ).exists()
        )

    def test_callback_completed_grants(self):
        url = reverse('payment-deposit-callback')
        res = self.client.post(
            url,
            {
                'depositId': str(self.deposit.deposit_id),
                'status': 'COMPLETED',
            },
            format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.deposit.refresh_from_db()
        self.assertEqual(self.deposit.status, 'COMPLETED')
        self.assertTrue(self.deposit.access_granted)
        self.assertTrue(
            CoursePurchase.objects.filter(
                user=self.user, course=self.course
            ).exists()
        )

    def test_my_courses(self):
        apply_remote_status(self.deposit, 'COMPLETED', {'status': 'COMPLETED'})
        res = self.client.get(reverse('payment-my-courses'))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['count'], 1)
        self.assertIn(self.course.id, res.data['course_ids'])

    def test_pricing_endpoint(self):
        res = self.client.get(reverse('payment-pricing'))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn('sale_price_usd', res.data)
        self.assertIn('list_price_usd', res.data)

    @patch('payments.views.PawaPayClient')
    def test_deposit_rejects_wrong_amount(self, client_cls):
        mock = MagicMock()
        client_cls.return_value = mock
        mock.token = 'eyJ.x.y'
        mock.currency = 'USD'
        url = reverse('payment-deposit-create')
        res = self.client.post(
            url,
            {
                'phone': '243800000000',
                'provider': 'vodacom_mpesa',
                'amount': '1.00',
                'course_ids': [str(self.course.id)],
            },
            format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    @patch('payments.views.PawaPayClient')
    def test_deposit_computes_server_amount(self, client_cls):
        mock = MagicMock()
        client_cls.return_value = mock
        mock.token = 'eyJ.x.y'
        mock.currency = 'USD'
        mock.request_deposit.return_value = {
            'depositId': str(uuid.uuid4()),
            'status': 'ACCEPTED',
        }
        url = reverse('payment-deposit-create')
        res = self.client.post(
            url,
            {
                'phone': '243800000000',
                'provider': 'vodacom_mpesa',
                'course_ids': [str(self.course.id)],
            },
            format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(Decimal(str(res.data['amount'])), Decimal('15.00'))
        mock.request_deposit.assert_called_once()
        self.assertEqual(mock.request_deposit.call_args.kwargs['amount'], 15.0)
