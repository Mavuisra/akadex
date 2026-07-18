import 'package:flutter_test/flutter_test.dart';

import 'package:akadex/data/mappers/mappers.dart';
import 'package:akadex/domain/models/document_type.dart';

void main() {
  group('mappers', () {
    test('documentFromJson mappe un document API', () {
      final doc = documentFromJson({
        'id': 12,
        'title': 'TP Réseaux VLAN',
        'doc_type': 'tp',
        'author_name': 'Samuel Okito',
        'university_name': 'Université de Kinshasa',
        'department_name': 'Informatique',
        'course_title': 'Réseaux informatiques',
        'academic_year': '2025',
        'created_at': '2025-03-01T10:00:00Z',
        'size_label': '3.2 Mo',
        'downloads': 420,
        'views': 890,
        'favorites_count': 76,
        'rating_avg': 4.5,
        'description': 'Lab Packet Tracer',
      });

      expect(doc.id, '12');
      expect(doc.title, contains('VLAN'));
      expect(doc.type, DocumentType.tp);
      expect(doc.author, 'Samuel Okito');
      expect(doc.downloads, 420);
      expect(doc.rating, 4.5);
    });

    test('userFromJson mappe le profil', () {
      final user = userFromJson({
        'id': 3,
        'email': 'aicha.mbemba@unikin.ac.cd',
        'first_name': 'Aïcha',
        'last_name': 'Mbemba',
        'full_name': 'Aïcha Mbemba',
        'university_name': 'Université de Kinshasa',
        'faculty_name': 'Faculté des Sciences',
        'department_name': 'Informatique',
        'promotion_name': 'L3 Info 2025–2026',
        'level': 'Licence 3',
        'role': 'student',
        'bio': 'Passionnée',
        'reputation': 1280,
        'contributions_count': 47,
        'badges': ['Top contributeur'],
      });

      expect(user.name, 'Aïcha Mbemba');
      expect(user.role, 'student');
      expect(user.email, contains('aicha'));
      expect(user.reputation, 1280);
      expect(user.badges, contains('Top contributeur'));
    });

    test('postFromJson mappe une publication', () {
      final post = postFromJson({
        'id': 1,
        'author_name': 'Samuel Okito',
        'author_id': 4,
        'author_role': 'student',
        'department_name': 'Informatique',
        'title': 'Qui a les annales ?',
        'content': 'Besoin des corrigés 2023',
        'kind': 'question',
        'kind_display': 'Question',
        'created_at': '2025-06-01T08:00:00Z',
        'likes_count': 24,
        'comments_count': 11,
        'tags': ['examens'],
      });

      expect(post.likes, 24);
      expect(post.kind, 'question');
      expect(post.tags, ['examens']);
    });

    test('outlineFromJson mappe un programme de cours', () {
      final outline = outlineFromJson({
        'id': 10,
        'code': 'UNI-INF111',
        'title': 'Algorithmique',
        'teacher_names': ['Pierre Kabongo'],
        'semester': 'L1',
        'credits': 5,
        'department_name': 'Informatique',
        'university_name': 'Université de Kinshasa',
        'faculty_name': 'Sciences et Technologies',
        'description': 'Bases',
        'objectives': 'Complexité',
        'skills': 'Analyse',
        'prerequisites': '',
        'document_count': 3,
        'modules': [
          {
            'id': 1,
            'title': 'Chapitre 1',
            'order': 1,
            'description': '',
            'lessons': [
              {
                'id': 5,
                'module': 1,
                'title': 'Intro',
                'content_type': 'video',
                'order': 1,
                'video_url': 'https://example.com/v.mp4',
                'duration_seconds': 120,
              },
            ],
          },
        ],
      });

      expect(outline.course.code, 'UNI-INF111');
      expect(outline.course.university, contains('Kinshasa'));
      expect(outline.modules, hasLength(1));
      expect(outline.modules.first.lessons.first.isVideo, isTrue);
    });

    test('documentTypeFromApi couvre les types principaux', () {
      expect(documentTypeFromApi('examen'), DocumentType.examen);
      expect(documentTypeFromApi('fiche_revision'), DocumentType.ficheRevision);
      expect(documentTypeFromApi('inconnu'), DocumentType.pdf);
    });

    test('asDouble accepte String et num', () {
      expect(asDouble('4.70'), 4.7);
      expect(asDouble(4.8), 4.8);
      expect(asInt('420'), 420);
    });
  });
}
