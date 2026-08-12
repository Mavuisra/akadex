from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from academic.models import CalendarEvent, Course, Document, University
from community.models import Post
from django.contrib.auth import get_user_model

User = get_user_model()


class AkadexApiTests(APITestCase):
    def setUp(self):
        from academic.models import Department, Faculty

        self.uni = University.objects.create(
            name='Université Test',
            slug='uni-test',
            city='Kinshasa',
            country='RD Congo',
        )
        self.user = User.objects.create_user(
            email='etudiant@test.cd',
            username='etudiant',
            password='akadex2026',
            first_name='Léa',
            last_name='Moke',
            university=self.uni,
        )
        self.faculty = Faculty.objects.create(
            university=self.uni,
            name='Sciences',
            slug='sciences-test',
        )
        self.dept = Department.objects.create(
            faculty=self.faculty,
            name='Informatique',
            slug='info-test',
        )
        self.course = Course.objects.create(
            department=self.dept,
            code='INF101',
            title='Introduction à la programmation',
            credits=5,
            semester='L1',
        )
        self.doc = Document.objects.create(
            title='Support Python débutant',
            university=self.uni,
            department=self.dept,
            course=self.course,
            author=self.user,
            doc_type='support_cours',
            is_approved=True,
            is_featured=True,
            downloads=120,
            views=400,
        )
        self.post = Post.objects.create(
            author=self.user,
            department=self.dept,
            title='Besoin d’aide pour les listes ?',
            content='Quelqu’un peut expliquer append vs extend ?',
            tags=['python', 'entraide'],
            is_approved=True,
            likes_count=5,
        )
        CalendarEvent.objects.create(
            university=self.uni,
            title='Examen INF101',
            event_type='examen',
            starts_at='2030-01-15T09:00:00Z',
            location='Amphi A',
        )

    def test_list_universities(self):
        url = reverse('university-list')
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        results = res.data['results'] if isinstance(res.data, dict) else res.data
        self.assertTrue(any(u['slug'] == 'uni-test' for u in results))

    def test_list_documents_public(self):
        url = reverse('document-list')
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        results = res.data['results'] if isinstance(res.data, dict) else res.data
        self.assertGreaterEqual(len(results), 1)
        self.assertEqual(results[0]['title'], 'Support Python débutant')

    def test_list_courses(self):
        url = reverse('course-list')
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        results = res.data['results'] if isinstance(res.data, dict) else res.data
        self.assertTrue(any(c['code'] == 'INF101' for c in results))

    def test_list_posts(self):
        url = reverse('post-list')
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        results = res.data['results'] if isinstance(res.data, dict) else res.data
        self.assertTrue(any(p['title'].startswith('Besoin') for p in results))

    def test_list_events(self):
        url = reverse('event-list')
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        results = res.data['results'] if isinstance(res.data, dict) else res.data
        self.assertTrue(any(e['title'] == 'Examen INF101' for e in results))

    def test_login_jwt_and_me(self):
        token_url = reverse('token_obtain_pair')
        res = self.client.post(
            token_url,
            {'email': 'etudiant@test.cd', 'password': 'akadex2026'},
            format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn('access', res.data)
        self.assertIn('user', res.data)
        self.assertEqual(res.data['user']['email'], 'etudiant@test.cd')

        me_url = reverse('me')
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {res.data['access']}")
        me = self.client.get(me_url)
        self.assertEqual(me.status_code, status.HTTP_200_OK)
        self.assertEqual(me.data['first_name'], 'Léa')

    def test_register(self):
        url = reverse('register')
        res = self.client.post(
            url,
            {
                'email': 'nouveau@test.cd',
                'username': 'nouveau',
                'password': 'akadex2026',
                'password_confirm': 'akadex2026',
                'first_name': 'Noah',
                'last_name': 'Ilunga',
            },
            format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertTrue(User.objects.filter(email='nouveau@test.cd').exists())

    def test_student_can_propose_course_pending(self):
        from academic.models import LearningDomain

        self.user.department = self.dept
        self.user.save(update_fields=['department'])
        self.client.force_authenticate(user=self.user)
        url = reverse('course-list')
        res = self.client.post(
            url,
            {
                'title': 'Généralités des bases de données',
                'description': 'Intro SGBD',
                'teacher_name': 'Prof. Test',
                'semester': 'L2',
                'estimated_hours': 45,
            },
            format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data['moderation_status'], 'pending')
        self.assertFalse(res.data['is_approved'])
        course_id = res.data['id']

        domain = LearningDomain.objects.create(
            slug='informatique',
            name='Informatique',
        )
        admin = User.objects.create_superuser(
            email='admin@test.cd',
            username='admin',
            password='akadex2026',
        )
        self.client.force_authenticate(user=admin)
        approve = self.client.post(
            reverse('course-approve', args=[course_id]),
            {'domain_ids': [domain.id]},
            format='json',
        )
        self.assertEqual(approve.status_code, status.HTTP_200_OK)

    def test_teacher_can_publish_course_approved(self):
        from accounts.models import User
        from academic.models import LearningDomain

        teacher = User.objects.create_user(
            email='prof.publish@test.cd',
            username='profpublish',
            password='akadex2026',
            role=User.Role.TEACHER,
            department=self.dept,
        )
        LearningDomain.objects.create(
            slug='informatique',
            name='Informatique',
        )
        self.client.force_authenticate(user=teacher)
        res = self.client.post(
            reverse('course-list'),
            {
                'title': 'Algorithmique avancée',
                'code': 'INFO401',
                'description': 'Cours enseignant',
                'objectives': 'Maîtriser les graphes',
                'skills': 'Complexité',
                'prerequisites': 'L2 algo',
                'semester': 'L3',
                'level_label': 'S1',
                'credits': 5,
                'estimated_hours': 40,
                'domain_slugs': ['informatique'],
            },
            format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED, res.data)
        course = Course.objects.get(pk=res.data['id'])
        self.assertEqual(course.moderation_status, Course.ModerationStatus.APPROVED)
        self.assertTrue(course.is_approved)
        self.assertTrue(course.teachers.filter(pk=teacher.pk).exists())
        self.assertTrue(course.domains.filter(slug='informatique').exists())
        self.assertEqual(res.data['moderation_status'], 'approved')
        self.assertTrue(res.data['is_approved'])

    def test_peer_validation_then_admin_awards_points(self):
        from academic.rewards import (
            FACULTY_PEER_VALIDATIONS_REQUIRED,
            HIGH_TIER_POINTS,
            LOW_TIER_POINTS,
        )

        author = User.objects.create_user(
            email='author@test.cd',
            username='author',
            password='akadex2026',
            university=self.uni,
            faculty=self.faculty,
            department=self.dept,
        )
        doc = Document.objects.create(
            title='Examen INF101',
            university=self.uni,
            department=self.dept,
            author=author,
            doc_type='examen',
            moderation_status='pending_peers',
            is_approved=False,
        )

        validators = []
        for i in range(FACULTY_PEER_VALIDATIONS_REQUIRED):
            u = User.objects.create_user(
                email=f'peer{i}@test.cd',
                username=f'peer{i}',
                password='akadex2026',
                university=self.uni,
                faculty=self.faculty,
                department=self.dept,
            )
            validators.append(u)

        for u in validators:
            self.client.force_authenticate(user=u)
            res = self.client.post(
                reverse('document-peer-validate', args=[doc.pk]),
                {'score': 4},
                format='json',
            )
            self.assertEqual(res.status_code, status.HTTP_200_OK, res.data)

        doc.refresh_from_db()
        self.assertEqual(doc.moderation_status, 'pending_admin')
        self.assertEqual(doc.peer_validations.count(), FACULTY_PEER_VALIDATIONS_REQUIRED)

        admin = User.objects.create_superuser(
            email='admin.peer@test.cd',
            username='adminpeer',
            password='akadex2026',
        )
        self.client.force_authenticate(user=admin)
        res = self.client.post(reverse('document-approve', args=[doc.pk]))
        self.assertEqual(res.status_code, status.HTTP_200_OK, res.data)

        doc.refresh_from_db()
        author.refresh_from_db()
        self.assertTrue(doc.is_approved)
        self.assertEqual(doc.points_awarded, LOW_TIER_POINTS)
        self.assertEqual(author.reputation, LOW_TIER_POINTS)

        memo = Document.objects.create(
            title='Mémoire L3',
            university=self.uni,
            department=self.dept,
            author=author,
            doc_type='memoire',
            moderation_status='pending_peers',
            is_approved=False,
        )
        for u in validators:
            self.client.force_authenticate(user=u)
            self.client.post(reverse('document-peer-validate', args=[memo.pk]))
        self.client.force_authenticate(user=admin)
        self.client.post(reverse('document-approve', args=[memo.pk]))
        memo.refresh_from_db()
        author.refresh_from_db()
        self.assertEqual(memo.points_awarded, HIGH_TIER_POINTS)
        self.assertEqual(
            author.reputation,
            LOW_TIER_POINTS + HIGH_TIER_POINTS,
        )

    def test_pending_documents_visible_to_other_students(self):
        """Les docs en attente d'autres étudiants doivent apparaître dans la liste."""
        other = User.objects.create_user(
            email='autre@test.cd',
            username='autre',
            password='akadex2026',
            first_name='Paul',
            last_name='Kabongo',
            university=self.uni,
            faculty=self.faculty,
            department=self.dept,
        )
        peer = User.objects.create_user(
            email='pair@test.cd',
            username='pair',
            password='akadex2026',
            first_name='Marie',
            last_name='Lubala',
            university=self.uni,
            faculty=self.faculty,
            department=self.dept,
        )
        pending = Document.objects.create(
            title='TP réseaux — autre étudiant',
            university=self.uni,
            department=self.dept,
            author=other,
            doc_type='tp',
            moderation_status='pending_peers',
            is_approved=False,
        )

        self.client.force_authenticate(user=peer)
        res = self.client.get(reverse('document-list'))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        results = res.data['results'] if isinstance(res.data, dict) else res.data
        titles = [d['title'] for d in results]
        self.assertIn(pending.title, titles)
        self.assertIn(self.doc.title, titles)
