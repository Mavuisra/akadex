import json

from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase
from rest_framework.test import APIClient

from community.models import Post, PostKind

User = get_user_model()


class PostCreateApiTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            email='exam.student@unikin.ac.cd',
            username='examstudent',
            password='akadex2026',
            first_name='Exam',
            last_name='Student',
            role=User.Role.STUDENT,
        )
        self.client.force_authenticate(self.user)

    def test_create_exam_kind_json(self):
        res = self.client.post(
            '/api/posts/',
            {
                'title': 'Examen algo',
                'content': 'Corrigé session juin',
                'kind': PostKind.EXAM,
                'tags': ['exam'],
            },
            format='json',
        )
        self.assertEqual(res.status_code, 201, res.data)
        self.assertEqual(res.data['kind'], 'exam')
        self.assertEqual(res.data['tags'], ['exam'])
        self.assertTrue(Post.objects.filter(kind='exam').exists())

    def test_create_tp_summary_notes_support(self):
        for kind in (
            PostKind.TP,
            PostKind.SUMMARY,
            PostKind.NOTES,
            PostKind.SUPPORT,
        ):
            res = self.client.post(
                '/api/posts/',
                {
                    'title': f'Titre {kind}',
                    'content': f'Contenu {kind}',
                    'kind': kind,
                    'tags': [kind],
                },
                format='json',
            )
            self.assertEqual(res.status_code, 201, res.data)
            self.assertEqual(res.data['kind'], kind)

    def test_multipart_with_pdf_and_json_tags(self):
        pdf = SimpleUploadedFile(
            'exam.pdf',
            b'%PDF-1.4\n1 0 obj<<>>endobj\ntrailer<<>>\n%%EOF\n',
            content_type='application/pdf',
        )
        res = self.client.post(
            '/api/posts/',
            {
                'title': 'Examen PDF',
                'content': 'Sujet joint',
                'kind': 'exam',
                'tags': json.dumps(['exam']),
                'file': pdf,
            },
            format='multipart',
        )
        self.assertEqual(res.status_code, 201, res.data)
        self.assertEqual(res.data['kind'], 'exam')
        self.assertEqual(res.data['tags'], ['exam'])
        self.assertTrue(bool(res.data.get('attachment_url')))

    def test_multipart_tags_as_json_string(self):
        pdf = SimpleUploadedFile(
            'note.pdf',
            b'%PDF-1.4\n1 0 obj<<>>endobj\ntrailer<<>>\n%%EOF\n',
            content_type='application/pdf',
        )
        res = self.client.post(
            '/api/posts/',
            {
                'title': 'Doc campus',
                'content': 'Un PDF',
                'kind': 'discussion',
                'tags': json.dumps(['discussion']),
                'file': pdf,
            },
            format='multipart',
        )
        self.assertEqual(res.status_code, 201, res.data)
        self.assertEqual(res.data['tags'], ['discussion'])

    def test_multipart_tags_plain_string_fallback(self):
        res = self.client.post(
            '/api/posts/',
            {
                'title': 'Sans json list',
                'content': 'tags en texte',
                'kind': 'discussion',
                'tags': 'campus',
            },
            format='multipart',
        )
        self.assertEqual(res.status_code, 201, res.data)
        self.assertEqual(res.data['tags'], ['campus'])

    def test_background_color_short_text(self):
        res = self.client.post(
            '/api/posts/',
            {
                'title': 'Status',
                'content': 'A chacun sa petite vie',
                'kind': 'discussion',
                'background_color': '#1877F2',
                'tags': [],
            },
            format='json',
        )
        self.assertEqual(res.status_code, 201, res.data)
        self.assertEqual(res.data['background_color'], '#1877F2')

    def test_multipart_image_returns_image_url(self):
        from io import BytesIO

        from PIL import Image

        buf = BytesIO()
        Image.new('RGB', (32, 32), color=(24, 119, 242)).save(buf, format='PNG')
        image = SimpleUploadedFile(
            'campus.png',
            buf.getvalue(),
            content_type='image/png',
        )
        res = self.client.post(
            '/api/posts/',
            {
                'title': 'Photo campus',
                'content': 'Une belle photo',
                'kind': 'discussion',
                'tags': json.dumps(['discussion']),
                'image': image,
            },
            format='multipart',
        )
        self.assertEqual(res.status_code, 201, res.data)
        image_url = res.data.get('image_url') or ''
        self.assertTrue(image_url, res.data)
        self.assertIn('/media/', image_url)
        path = image_url[image_url.find('/media/'):]
        media_res = self.client.get(path)
        self.assertEqual(media_res.status_code, 200, path)
        body = b''.join(media_res.streaming_content)
        self.assertGreater(len(body), 20)
