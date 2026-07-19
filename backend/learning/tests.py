from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from academic.models import Course, Department, Faculty, University
from community.models import AlumniFollow, Post, PostKind
from learning.models import CourseLesson, CourseModule, LessonContentType

User = get_user_model()


class LearningAndAlumniApiTests(APITestCase):
    def setUp(self):
        self.uni = University.objects.create(
            name='Université de Kinshasa',
            slug='unikin-test',
            city='Kinshasa',
        )
        self.faculty = Faculty.objects.create(
            university=self.uni,
            name='Faculté des Sciences et Technologies',
            slug='sciences-tech',
        )
        self.dept = Department.objects.create(
            faculty=self.faculty,
            name='Informatique',
            slug='informatique',
        )
        self.teacher = User.objects.create_user(
            email='prof@unikin.ac.cd',
            username='prof',
            password='akadex2026',
            role=User.Role.TEACHER,
            university=self.uni,
            faculty=self.faculty,
            department=self.dept,
        )
        self.alumni = User.objects.create_user(
            email='alumni@unikin.ac.cd',
            username='alumni',
            password='akadex2026',
            role=User.Role.ALUMNI,
            university=self.uni,
            department=self.dept,
            first_name='Marie',
            last_name='Kasongo',
        )
        self.student = User.objects.create_user(
            email='etudiant@unikin.ac.cd',
            username='etudiant',
            password='akadex2026',
            role=User.Role.STUDENT,
            university=self.uni,
            department=self.dept,
        )
        self.course = Course.objects.create(
            department=self.dept,
            code='UNI-INF111',
            title='Algorithmique',
            description='Bases des algorithmes.',
            objectives='Maîtriser la complexité.',
            skills='Analyse, programmation',
            prerequisites='Mathématiques L1',
            credits=5,
            semester='L1',
        )
        self.course.teachers.add(self.teacher)
        self.module = CourseModule.objects.create(
            course=self.course,
            title='Chapitre 1 — Fondamentaux',
            order=1,
        )
        self.lesson = CourseLesson.objects.create(
            module=self.module,
            title='Introduction',
            content_type=LessonContentType.VIDEO,
            order=1,
            video_url='https://example.com/video.mp4',
            duration_seconds=600,
            is_published=True,
        )
        self.alumni_post = Post.objects.create(
            author=self.alumni,
            department=self.dept,
            title='Conseils pour le TFC',
            content='Planifiez 8 semaines et validez le sujet tôt.',
            kind=PostKind.ALUMNI_TFC,
            is_approved=True,
        )

    def _auth(self, user):
        res = self.client.post(
            reverse('token_obtain_pair'),
            {'email': user.email, 'password': 'akadex2026'},
            format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {res.data['access']}")

    def test_course_outline_includes_modules(self):
        url = reverse('course-outline-detail', args=[self.course.pk])
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['code'], 'UNI-INF111')
        self.assertEqual(res.data['university_name'], 'Université de Kinshasa')
        self.assertEqual(len(res.data['modules']), 1)
        self.assertEqual(res.data['modules'][0]['lessons'][0]['title'], 'Introduction')

    def test_lesson_progress_resume(self):
        self._auth(self.student)
        url = reverse('course-lesson-progress', args=[self.lesson.pk])
        res = self.client.post(
            url,
            {'position_seconds': 120, 'completed': False},
            format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['position_seconds'], 120)

    def test_teacher_can_create_module_and_lesson(self):
        self._auth(self.teacher)
        mod_res = self.client.post(
            reverse('course-module-list'),
            {
                'course': self.course.pk,
                'title': 'Chapitre 2',
                'order': 2,
                'description': 'Graphes',
            },
            format='json',
        )
        self.assertEqual(mod_res.status_code, status.HTTP_201_CREATED)
        lesson_res = self.client.post(
            reverse('course-lesson-list'),
            {
                'module': mod_res.data['id'],
                'title': 'Graphes — parcours',
                'content_type': 'video',
                'order': 1,
                'video_url': 'https://example.com/g.mp4',
                'is_published': True,
            },
            format='json',
        )
        self.assertEqual(lesson_res.status_code, status.HTTP_201_CREATED)

    def test_student_cannot_create_module(self):
        self._auth(self.student)
        res = self.client.post(
            reverse('course-module-list'),
            {'course': self.course.pk, 'title': 'X', 'order': 9},
            format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_student_cannot_create_lesson(self):
        self._auth(self.student)
        res = self.client.post(
            reverse('course-lesson-list'),
            {
                'module': self.module.pk,
                'title': 'Leçon pirate',
                'content_type': 'video',
                'order': 99,
                'video_url': 'https://example.com/x.mp4',
            },
            format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_alumni_cannot_create_module(self):
        self._auth(self.alumni)
        res = self.client.post(
            reverse('course-module-list'),
            {'course': self.course.pk, 'title': 'Y', 'order': 8},
            format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_alumni_feed_scope(self):
        url = reverse('post-list')
        res = self.client.get(url, {'scope': 'alumni'})
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        results = res.data['results'] if isinstance(res.data, dict) else res.data
        self.assertTrue(any(p['kind'] == 'alumni_tfc' for p in results))

    def test_alumni_can_publish_advice(self):
        self._auth(self.alumni)
        res = self.client.post(
            reverse('post-list'),
            {
                'title': 'Stages à Kinshasa',
                'content': 'Ciblez les fintech et les ONG tech.',
                'kind': 'alumni_career',
                'department': self.dept.pk,
            },
            format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data['kind'], 'alumni_career')

    def test_student_cannot_publish_alumni_advice(self):
        self._auth(self.student)
        res = self.client.post(
            reverse('post-list'),
            {
                'title': 'Fake alumni',
                'content': 'Ne devrait pas passer',
                'kind': 'alumni_advice',
                'department': self.dept.pk,
            },
            format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_follow_alumni_toggle(self):
        self._auth(self.student)
        url = reverse('alumni-follow-toggle')
        res = self.client.post(url, {'alumni': self.alumni.pk}, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertTrue(res.data['following'])
        self.assertTrue(
            AlumniFollow.objects.filter(
                follower=self.student,
                alumni=self.alumni,
            ).exists()
        )
        res2 = self.client.post(url, {'alumni': self.alumni.pk}, format='json')
        self.assertEqual(res2.status_code, status.HTTP_200_OK)
        self.assertFalse(res2.data['following'])

    def test_course_comment(self):
        self._auth(self.student)
        res = self.client.post(
            reverse('course-comment-list'),
            {'course': self.course.pk, 'content': 'Question sur le TP ?'},
            format='json',
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
