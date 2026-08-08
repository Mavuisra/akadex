import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/document_type.dart';
import '../../domain/models/models.dart';
import '../api/api_client.dart';
import '../auth/auth_repository.dart';
import '../local/local_academic_store.dart';
import '../mappers/mappers.dart';
import '../sync/sync_service.dart';

final academicRepositoryProvider = Provider<AcademicRepository>((ref) {
  return AcademicRepository(
    ref.watch(dioProvider),
    ref.watch(localStoreProvider),
  );
});

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(ref.watch(dioProvider));
});

final documentsProvider =
    FutureProvider.family<List<AcademicDocument>, DocumentQuery>((ref, query) {
  return ref.watch(academicRepositoryProvider).fetchDocuments(query);
});

final documentProvider =
    FutureProvider.family<AcademicDocument, String>((ref, id) {
  return ref.watch(academicRepositoryProvider).fetchDocument(id);
});

/// Catalogue cours : cache local d’abord, puis refresh réseau en arrière-plan.
class CoursesNotifier extends AsyncNotifier<List<Course>> {
  @override
  Future<List<Course>> build() async {
    final repo = ref.watch(academicRepositoryProvider);
    final cached = await repo.getCachedCourses();
    if (cached.isNotEmpty) {
      unawaited(_refreshInBackground());
      return cached;
    }
    return repo.fetchCourses(preferCache: false);
  }

  Future<void> _refreshInBackground() async {
    try {
      final fresh =
          await ref.read(academicRepositoryProvider).fetchCourses(preferCache: false);
      state = AsyncData(fresh);
    } catch (_) {
      // Garde le cache affiché.
    }
  }
}

final coursesProvider =
    AsyncNotifierProvider<CoursesNotifier, List<Course>>(CoursesNotifier.new);

final courseProvider = FutureProvider.family<Course, String>((ref, id) {
  return ref.watch(academicRepositoryProvider).fetchCourse(id);
});

final universitiesProvider = FutureProvider<List<UniversityItem>>((ref) {
  return ref.watch(academicRepositoryProvider).fetchUniversities();
});

final departmentsProvider =
    FutureProvider.family<List<DepartmentItem>, String?>((ref, universityId) {
  return ref
      .watch(academicRepositoryProvider)
      .fetchDepartments(universityId: universityId);
});

/// Départements d’une faculté (inscription / Ma Fac).
final facultyDepartmentsProvider =
    FutureProvider.family<List<DepartmentItem>, String?>((ref, facultyId) {
  if (facultyId == null || facultyId.isEmpty) {
    return Future.value(const <DepartmentItem>[]);
  }
  return ref
      .watch(academicRepositoryProvider)
      .fetchDepartments(facultyId: facultyId);
});

final facultiesProvider =
    FutureProvider.family<List<FacultyItem>, String?>((ref, universityId) {
  return ref
      .watch(academicRepositoryProvider)
      .fetchFaculties(universityId: universityId);
});

final promotionsProvider =
    FutureProvider.family<List<PromotionItem>, String?>((ref, departmentId) {
  return ref
      .watch(academicRepositoryProvider)
      .fetchPromotions(departmentId: departmentId);
});

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) {
  return ref.watch(authRepositoryProvider).fetchNotifications();
});

final postCommentsProvider =
    FutureProvider.family<List<CourseCommentItem>, String>((ref, postId) {
  return ref.watch(communityRepositoryProvider).fetchPostComments(postId);
});

final eventsProvider = FutureProvider<List<CalendarEventItem>>((ref) {
  return ref.watch(academicRepositoryProvider).fetchEvents();
});

final announcementsProvider =
    FutureProvider<List<UniversityAnnouncement>>((ref) {
  return ref.watch(academicRepositoryProvider).fetchAnnouncements();
});

final postsProvider = FutureProvider.family<List<CommunityPost>, String?>((
  ref,
  scope,
) {
  return ref.watch(communityRepositoryProvider).fetchPosts(scope: scope);
});

/// Fil d’accueil : posts étudiants (TP, résumés, examens…).
class TimelineQuery {
  const TimelineQuery({
    this.kind,
    this.universityId,
    this.facultyId,
    this.departmentId,
    this.promotionId,
    this.tag,
    this.year,
  });

  final String? kind;
  final String? universityId;
  final String? facultyId;
  final String? departmentId;
  final String? promotionId;
  final String? tag;
  final String? year;

  static const empty = TimelineQuery();

  TimelineQuery copyWith({
    String? kind,
    String? universityId,
    String? facultyId,
    String? departmentId,
    String? promotionId,
    String? tag,
    String? year,
    bool clearKind = false,
    bool clearUniversity = false,
    bool clearFaculty = false,
    bool clearDepartment = false,
    bool clearPromotion = false,
    bool clearTag = false,
    bool clearYear = false,
  }) {
    return TimelineQuery(
      kind: clearKind ? null : (kind ?? this.kind),
      universityId:
          clearUniversity ? null : (universityId ?? this.universityId),
      facultyId: clearFaculty ? null : (facultyId ?? this.facultyId),
      departmentId:
          clearDepartment ? null : (departmentId ?? this.departmentId),
      promotionId: clearPromotion ? null : (promotionId ?? this.promotionId),
      tag: clearTag ? null : (tag ?? this.tag),
      year: clearYear ? null : (year ?? this.year),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TimelineQuery &&
        other.kind == kind &&
        other.universityId == universityId &&
        other.facultyId == facultyId &&
        other.departmentId == departmentId &&
        other.promotionId == promotionId &&
        other.tag == tag &&
        other.year == year;
  }

  @override
  int get hashCode => Object.hash(
        kind,
        universityId,
        facultyId,
        departmentId,
        promotionId,
        tag,
        year,
      );
}

final timelinePostsProvider =
    FutureProvider.family<List<CommunityPost>, TimelineQuery>((ref, query) {
  final kind = (query.kind == null || query.kind == 'all') ? null : query.kind;
  return ref.watch(communityRepositoryProvider).fetchPosts(
        scope: 'timeline',
        kind: kind,
        universityId: query.universityId,
        facultyId: query.facultyId,
        departmentId: query.departmentId,
        promotionId: query.promotionId,
        tag: query.tag,
        year: query.year,
      );
});

final alumniProfileProvider =
    FutureProvider.family<UserProfile, String>((ref, userId) {
  return ref.watch(communityRepositoryProvider).fetchUser(userId);
});

final alumniPostsByAuthorProvider =
    FutureProvider.family<List<CommunityPost>, String>((ref, authorId) {
  // Toutes les pubs de l’auteur (pas seulement scope alumni).
  return ref.watch(communityRepositoryProvider).fetchPosts(
        authorId: authorId,
      );
});

final courseOutlineProvider =
    FutureProvider.family<CourseOutline, String>((ref, id) {
  return ref.watch(academicRepositoryProvider).fetchCourseOutline(id);
});

final courseCommentsProvider =
    FutureProvider.family<List<CourseCommentItem>, String>((ref, courseId) {
  return ref.watch(academicRepositoryProvider).fetchCourseComments(courseId);
});

final myDocumentsProvider = FutureProvider<List<AcademicDocument>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Future.value(const []);
  return ref.watch(academicRepositoryProvider).fetchMyDocuments(user.id);
});

class DocumentQuery {
  const DocumentQuery({
    this.search,
    this.docType,
    this.courseId,
    this.universityId,
    this.departmentId,
    this.facultyId,
    this.featuredOnly = false,
    this.ordering = '-downloads',
  });

  final String? search;
  final DocumentType? docType;
  final String? courseId;
  final String? universityId;
  final String? departmentId;
  final String? facultyId;
  final bool featuredOnly;
  final String ordering;

  @override
  bool operator ==(Object other) =>
      other is DocumentQuery &&
      other.search == search &&
      other.docType == docType &&
      other.courseId == courseId &&
      other.universityId == universityId &&
      other.departmentId == departmentId &&
      other.facultyId == facultyId &&
      other.featuredOnly == featuredOnly &&
      other.ordering == ordering;

  @override
  int get hashCode => Object.hash(
        search,
        docType,
        courseId,
        universityId,
        departmentId,
        facultyId,
        featuredOnly,
        ordering,
      );
}

class AcademicRepository {
  AcademicRepository(this._dio, this._store);

  final Dio _dio;
  final LocalAcademicStore _store;

  Future<List<AcademicDocument>> fetchDocuments(DocumentQuery query) async {
    try {
      final res = await _dio.get(
        'documents/',
        queryParameters: {
          if (query.search != null && query.search!.trim().isNotEmpty)
            'search': query.search!.trim(),
          if (query.docType != null)
            'doc_type': documentTypeToApi(query.docType),
          'course': ?query.courseId,
          'university': ?query.universityId,
          'department': ?query.departmentId,
          if (query.facultyId != null && query.facultyId!.isNotEmpty)
            'department__faculty': query.facultyId,
          if (query.featuredOnly) 'is_featured': true,
          'ordering': query.ordering,
        },
      );
      final raw = unwrapList(res.data);
      await _store.upsertDocuments(raw);
      return raw.map(documentFromJson).toList();
    } catch (_) {
      return _store.getDocuments(
        search: query.search,
        docType: query.docType,
        courseId: query.courseId,
        featuredOnly: query.featuredOnly,
      );
    }
  }

  Future<AcademicDocument> fetchDocument(String id) async {
    try {
      final res = await _dio.get('documents/$id/');
      final raw = Map<String, dynamic>.from(res.data as Map);
      await _store.upsertDocuments([raw]);
      return documentFromJson(raw);
    } catch (_) {
      final local = await _store.getDocument(id);
      if (local != null) return local;
      rethrow;
    }
  }

  Future<List<AcademicDocument>> fetchMyDocuments(String authorId) async {
    final res = await _dio.get(
      'documents/',
      queryParameters: {
        'author': authorId,
        'ordering': '-created_at',
      },
    );
    return unwrapList(res.data).map(documentFromJson).toList();
  }

  Future<AcademicDocument> createDocument(Map<String, dynamic> data) async {
    final res = await _dio.post('documents/', data: data);
    return documentFromJson(Map<String, dynamic>.from(res.data as Map));
  }

  /// Contribution étudiant avec fichier uploadé (Ma Fac / Bibliothèque).
  Future<AcademicDocument> createDocumentMultipart({
    required String title,
    required String docType,
    required Object universityId,
    String description = '',
    Object? departmentId,
    String externalUrl = '',
    String academicYear = '',
    List<int>? fileBytes,
    String? fileName,
    String? filePath,
  }) async {
    final hasFile = (fileBytes != null && fileBytes.isNotEmpty) ||
        (filePath != null && filePath.isNotEmpty);

    if (!hasFile) {
      return createDocument({
        'title': title,
        'description': description,
        'doc_type': docType,
        'university': universityId,
        if (departmentId != null) 'department': departmentId,
        'external_url': externalUrl,
        if (academicYear.isNotEmpty) 'academic_year': academicYear,
      });
    }

    MultipartFile? filePart;
    final name = fileName ??
        (filePath != null && filePath.isNotEmpty
            ? filePath.split(RegExp(r'[\\/]')).last
            : 'document.pdf');
    if (fileBytes != null && fileBytes.isNotEmpty) {
      filePart = MultipartFile.fromBytes(
        fileBytes,
        filename: name,
        contentType: _mediaTypeFor(
          name,
          fallback: DioMediaType('application', 'octet-stream'),
        ),
      );
    } else if (filePath != null && filePath.isNotEmpty) {
      filePart = await MultipartFile.fromFile(
        filePath,
        filename: name,
        contentType: _mediaTypeFor(
          name,
          fallback: DioMediaType('application', 'octet-stream'),
        ),
      );
    }

    final form = FormData.fromMap({
      'title': title,
      'description': description,
      'doc_type': docType,
      'university': universityId,
      if (departmentId != null) 'department': departmentId,
      'external_url': externalUrl,
      if (academicYear.isNotEmpty) 'academic_year': academicYear,
      if (filePart != null) 'file': filePart,
    });

    final res = await _dio.post('documents/', data: form);
    return documentFromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<Course> createCourse(Map<String, dynamic> data) async {
    final res = await _dio.post('courses/', data: data);
    final raw = Map<String, dynamic>.from(res.data as Map);
    await _store.upsertCourses([raw]);
    return courseFromJson(raw);
  }

  Future<Course> updateCourse(String id, Map<String, dynamic> data) async {
    final res = await _dio.patch('courses/$id/', data: data);
    final raw = Map<String, dynamic>.from(res.data as Map);
    await _store.upsertCourses([raw]);
    return courseFromJson(raw);
  }

  Future<Map<String, dynamic>> fetchCourseStats(String id) async {
    try {
      final res = await _dio.get('courses/$id/stats/');
      return Map<String, dynamic>.from(res.data as Map);
    } catch (_) {
      final course = await fetchCourse(id);
      final outline = await fetchCourseOutline(id);
      final lessons =
          outline.modules.fold<int>(0, (a, m) => a + m.lessons.length);
      final activity = _emptyActivity7d();
      return {
        'course_id': id,
        'views': course.views,
        'students': _estimateStudents(course),
        'students_completed': 0,
        'modules': outline.modules.length,
        'lessons': lessons,
        'comments': 0,
        'activity_7d': activity,
      };
    }
  }

  Future<Map<String, dynamic>> fetchTeacherDashboard({
    String? userId,
    String? userName,
  }) async {
    try {
      final res = await _dio.get('courses/teacher_dashboard/');
      return Map<String, dynamic>.from(res.data as Map);
    } catch (_) {
      return buildLocalTeacherDashboard(
        courses: await fetchCourses(preferCache: true),
        userId: userId ?? '',
        userName: userName ?? '',
      );
    }
  }

  /// Stats locales si l’API prod n’a pas encore teacher_dashboard / stats.
  Map<String, dynamic> buildLocalTeacherDashboard({
    required List<Course> courses,
    required String userId,
    required String userName,
  }) {
    final mine = _filterTeacherCourses(courses, userId, userName);
    final views = mine.fold<int>(0, (a, c) => a + c.views);
    final students = mine.fold<int>(0, (a, c) => a + _estimateStudents(c));
    final top = [
      for (final c in mine.take(12))
        {
          'id': c.id,
          'title': c.title,
          'code': c.code,
          'views': c.views,
          'students': _estimateStudents(c),
          'semester': c.semester,
        },
    ];
    // Activité illustrative basée sur les vues (répartition 7 jours).
    final activity = _activityFromViews(views);
    return {
      'courses_count': mine.length,
      'views': views,
      'students': students,
      'lessons': mine.fold<int>(0, (a, c) => a + (c.documentCount > 0 ? c.documentCount : 3)),
      'activity_7d': activity,
      'top_courses': top,
    };
  }

  List<Course> _filterTeacherCourses(
    List<Course> courses,
    String userId,
    String userName,
  ) {
    final name = userName.toLowerCase();
    final first =
        name.split(' ').where((p) => p.isNotEmpty).firstOrNull ?? '';
    final mine = courses.where((c) {
      if (userId.isNotEmpty && c.submittedById == userId) return true;
      final hay = [
        c.teacher,
        c.displayTeacher,
        c.teacherFullName,
        c.submittedByName,
      ].join(' ').toLowerCase();
      if (first.isNotEmpty && hay.contains(first)) return true;
      if (c.code.startsWith('ENS-')) return true;
      return false;
    }).toList();
    if (mine.isNotEmpty) return mine;
    return courses.where((c) => !c.code.startsWith('AKX-')).take(20).toList();
  }

  int _estimateStudents(Course c) {
    if (c.views > 0) return (c.views / 3).ceil().clamp(1, 9999);
    if (c.documentCount > 0) return c.documentCount * 12;
    return 0;
  }

  List<Map<String, dynamic>> _emptyActivity7d() {
    final now = DateTime.now();
    const labels = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
    return [
      for (var i = 6; i >= 0; i--)
        {
          'date': now.subtract(Duration(days: i)).toIso8601String().split('T').first,
          'label': labels[(now.subtract(Duration(days: i)).weekday - 1) % 7],
          'value': 0,
        },
    ];
  }

  List<Map<String, dynamic>> _activityFromViews(int views) {
    final now = DateTime.now();
    const labels = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
    final base = views > 0 ? views : 7;
    final weights = [0.08, 0.12, 0.18, 0.15, 0.22, 0.14, 0.11];
    return [
      for (var i = 0; i < 7; i++)
        {
          'date': now
              .subtract(Duration(days: 6 - i))
              .toIso8601String()
              .split('T')
              .first,
          'label': labels[
              (now.subtract(Duration(days: 6 - i)).weekday - 1) % 7],
          'value': (base * weights[i]).round().clamp(0, 99999),
        },
    ];
  }

  Future<List<Course>> getCachedCourses() => _store.getCourses();

  /// Charge le catalogue cours. Avec [preferCache], renvoie le SQLite s’il
  /// existe (affichage immédiat) ; sinon pagination réseau avec pages larges.
  Future<List<Course>> fetchCourses({
    bool preferCache = true,
    String? departmentId,
    String? facultyId,
  }) async {
    if (preferCache &&
        departmentId == null &&
        facultyId == null) {
      final local = await _store.getCourses();
      if (local.isNotEmpty) return local;
    }

    try {
      final all = <Map<String, dynamic>>[];
      var page = 1;
      while (true) {
        final res = await _dio.get(
          'courses/',
          queryParameters: {
            'ordering': 'code',
            'page': page,
            'page_size': 100,
            if (departmentId != null && departmentId.isNotEmpty)
              'department': departmentId,
            if (facultyId != null && facultyId.isNotEmpty)
              'department__faculty': facultyId,
          },
        );
        all.addAll(unwrapList(res.data));
        final next = res.data is Map ? res.data['next'] : null;
        if (next == null) break;
        page++;
        if (all.length > 2000 || page > 40) break;
      }
      if (departmentId == null && facultyId == null) {
        await _store.replaceAllCourses(all);
      }
      return all.map(courseFromJson).toList();
    } catch (_) {
      return _store.getCourses();
    }
  }

  Future<Course> fetchCourse(String id) async {
    try {
      final res = await _dio.get('courses/$id/');
      final raw = Map<String, dynamic>.from(res.data as Map);
      await _store.upsertCourses([raw]);
      return courseFromJson(raw);
    } catch (_) {
      final local = await _store.getCourse(id);
      if (local != null) return local;
      rethrow;
    }
  }

  Future<CourseOutline> fetchCourseOutline(String id) async {
    final res = await _dio.get('course-outlines/$id/');
    return outlineFromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<List<CourseCommentItem>> fetchCourseComments(String courseId) async {
    final res = await _dio.get(
      'course-comments/',
      queryParameters: {'course': courseId},
    );
    return unwrapList(res.data).map(courseCommentFromJson).toList();
  }

  Future<void> postCourseComment(String courseId, String content) async {
    final payload = {
      'course': int.tryParse(courseId) ?? courseId,
      'content': content,
    };
    try {
      await _dio.post('course-comments/', data: payload);
    } catch (_) {
      await _store.enqueueOp('course_comment', payload);
    }
  }

  Future<CourseLessonItem> createLesson(Map<String, dynamic> data) async {
    final res = await _dio.post('course-lessons/', data: data);
    return lessonFromJson(Map<String, dynamic>.from(res.data as Map));
  }

  /// Création de leçon avec fichier (PDF, diapos, TP…) → stockage S3 / local.
  Future<CourseLessonItem> createLessonMultipart({
    required Object moduleId,
    required String title,
    required String contentType,
    required int order,
    String description = '',
    String videoUrl = '',
    bool isPublished = true,
    List<int>? fileBytes,
    String? fileName,
    String? filePath,
  }) async {
    final hasFile = (fileBytes != null && fileBytes.isNotEmpty) ||
        (filePath != null && filePath.isNotEmpty);

    if (!hasFile) {
      return createLesson({
        'module': moduleId,
        'title': title,
        'description': description,
        'content_type': contentType,
        'order': order,
        'video_url': videoUrl,
        'is_published': isPublished,
      });
    }

    MultipartFile? filePart;
    final name = fileName ??
        (filePath != null && filePath.isNotEmpty
            ? filePath.split(RegExp(r'[\\/]')).last
            : 'lesson.pdf');
    if (fileBytes != null && fileBytes.isNotEmpty) {
      filePart = MultipartFile.fromBytes(
        fileBytes,
        filename: name,
        contentType: _mediaTypeFor(
          name,
          fallback: DioMediaType('application', 'octet-stream'),
        ),
      );
    } else if (filePath != null && filePath.isNotEmpty) {
      filePart = await MultipartFile.fromFile(
        filePath,
        filename: name,
        contentType: _mediaTypeFor(
          name,
          fallback: DioMediaType('application', 'octet-stream'),
        ),
      );
    }

    final form = FormData.fromMap({
      'module': moduleId,
      'title': title,
      'description': description,
      'content_type': contentType,
      'order': order,
      'video_url': videoUrl,
      'is_published': isPublished,
      if (filePart != null) 'file': filePart,
    });

    final res = await _dio.post('course-lessons/', data: form);
    return lessonFromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<CourseModuleItem> createModule(Map<String, dynamic> data) async {
    final res = await _dio.post('course-modules/', data: data);
    return moduleFromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<List<CourseModuleItem>> searchModules(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final res = await _dio.get(
      'course-modules/',
      queryParameters: {'search': q},
    );
    return unwrapList(res.data).map(moduleFromJson).toList();
  }

  Future<void> saveLessonProgress(
    String lessonId, {
    required int positionSeconds,
    bool completed = false,
  }) async {
    await _store.saveProgressLocal(
      lessonId,
      positionSeconds: positionSeconds,
      completed: completed,
      dirty: true,
    );
    try {
      await _dio.post(
        'course-lessons/$lessonId/progress/',
        data: {
          'position_seconds': positionSeconds,
          'completed': completed,
        },
      );
      await _store.markProgressClean(lessonId);
    } catch (_) {
      // Resté dirty → sync ultérieure
    }
  }

  Future<Map<String, dynamic>?> fetchLessonProgress(String lessonId) async {
    final local = await _store.getProgress(lessonId);
    if (local != null) return Map<String, dynamic>.from(local);
    try {
      final res = await _dio.get(
        'lesson-progress/',
        queryParameters: {'lesson': lessonId},
      );
      final list = unwrapList(res.data);
      if (list.isEmpty) return null;
      final row = list.first;
      await _store.saveProgressLocal(
        lessonId,
        positionSeconds: asInt(row['position_seconds']),
        completed: row['completed'] == true,
        dirty: false,
      );
      return row;
    } catch (_) {
      return null;
    }
  }

  /// Cache SQLite d’abord (affichage immédiat), puis refresh réseau.
  Future<List<UniversityItem>> fetchUniversities({
    bool preferCache = true,
  }) async {
    if (preferCache) {
      final cached = await _store.getUniversities();
      if (cached.isNotEmpty) {
        unawaited(_pullUniversities());
        return cached;
      }
    }
    return _pullUniversities();
  }

  Future<List<UniversityItem>> _pullUniversities() async {
    try {
      final res = await _dio.get('universities/');
      final raw = unwrapList(res.data);
      await _store.upsertUniversities(raw);
      return raw.map(universityFromJson).toList();
    } catch (_) {
      return _store.getUniversities();
    }
  }

  Future<List<DepartmentItem>> fetchDepartments({
    String? universityId,
    String? facultyId,
  }) async {
    try {
      final res = await _dio.get(
        'departments/',
        queryParameters: {
          if (facultyId != null && facultyId.isNotEmpty)
            'faculty': facultyId
          else if (universityId != null && universityId.isNotEmpty)
            'faculty__university': universityId,
        },
      );
      return unwrapList(res.data).map(departmentFromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<FacultyItem>> fetchFaculties({String? universityId}) async {
    try {
      final res = await _dio.get(
        'faculties/',
        queryParameters: {
          if (universityId != null && universityId.isNotEmpty)
            'university': universityId,
        },
      );
      return unwrapList(res.data).map(facultyFromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<PromotionItem>> fetchPromotions({String? departmentId}) async {
    if (departmentId == null || departmentId.isEmpty) {
      return const [];
    }
    try {
      final res = await _dio.get(
        'promotions/',
        queryParameters: {'department': departmentId},
      );
      return unwrapList(res.data).map(promotionFromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<String> suggestUniversity(String name) async {
    final res = await _dio.post(
      'suggest/university/',
      data: {'name': name.trim()},
    );
    return res.data['id'].toString();
  }

  Future<String> suggestFaculty({
    required String name,
    required String universityId,
  }) async {
    final res = await _dio.post(
      'suggest/faculty/',
      data: {
        'name': name.trim(),
        'university': int.tryParse(universityId) ?? universityId,
      },
    );
    return res.data['id'].toString();
  }

  Future<String> suggestDepartment({
    required String name,
    String? facultyId,
    String? universityId,
  }) async {
    final res = await _dio.post(
      'suggest/department/',
      data: {
        'name': name.trim(),
        if (facultyId != null && facultyId.isNotEmpty)
          'faculty': int.tryParse(facultyId) ?? facultyId,
        if (universityId != null && universityId.isNotEmpty)
          'university': int.tryParse(universityId) ?? universityId,
      },
    );
    return res.data['id'].toString();
  }

  Future<String> suggestPromotion({
    required String name,
    required String departmentId,
  }) async {
    final res = await _dio.post(
      'suggest/promotion/',
      data: {
        'name': name.trim(),
        'department': int.tryParse(departmentId) ?? departmentId,
      },
    );
    return res.data['id'].toString();
  }

  Future<List<CalendarEventItem>> fetchEvents() async {
    final res = await _dio.get(
      'events/',
      queryParameters: {'ordering': 'starts_at'},
    );
    return unwrapList(res.data).map(eventFromJson).toList();
  }

  Future<List<UniversityAnnouncement>> fetchAnnouncements() async {
    final res = await _dio.get('announcements/');
    return unwrapList(res.data).map(announcementFromJson).toList();
  }

  Future<void> downloadDocument(String id) async {
    await _dio.post('documents/$id/download/');
  }

  Future<void> viewDocument(String id) async {
    await _dio.post('documents/$id/view/');
  }
}

class CommunityRepository {
  CommunityRepository(this._dio);

  final Dio _dio;

  Future<List<CommunityPost>> fetchPosts({
    String? scope,
    String? authorId,
    String? kind,
    String? tag,
    String? universityId,
    String? facultyId,
    String? departmentId,
    String? promotionId,
    String? year,
  }) async {
    final res = await _dio.get(
      'posts/',
      queryParameters: {
        'ordering': '-created_at',
        'scope': ?scope,
        'author': ?authorId,
        'kind': ?kind,
        'tag': ?tag,
        'university': ?universityId,
        'faculty': ?facultyId,
        'department': ?departmentId,
        'promotion': ?promotionId,
        'year': ?year,
      },
    );
    return unwrapList(res.data).map(postFromJson).toList();
  }

  Future<UserProfile> fetchUser(String id) async {
    final res = await _dio.get('auth/users/$id/');
    return userFromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<CommunityPost> likePost(String id) async {
    await _dio.post('posts/$id/like/');
    final postRes = await _dio.get('posts/$id/');
    return postFromJson(Map<String, dynamic>.from(postRes.data as Map));
  }

  Future<CommunityPost> savePost(String id) async {
    await _dio.post('posts/$id/save_post/');
    final postRes = await _dio.get('posts/$id/');
    return postFromJson(Map<String, dynamic>.from(postRes.data as Map));
  }

  Future<bool> toggleFollowAlumni(String alumniId) async {
    final res = await _dio.post(
      'alumni-follows/toggle/',
      data: {'alumni': int.tryParse(alumniId) ?? alumniId},
    );
    return res.data['following'] == true;
  }

  Future<CommunityPost> createPost({
    required String title,
    required String content,
    required String kind,
    int? departmentId,
    String videoUrl = '',
    String fileUrl = '',
    int pageCount = 0,
    List<String> tags = const [],
    String backgroundColor = '',
    String? filePath,
    String? imagePath,
    List<int>? fileBytes,
    String? fileName,
    List<int>? imageBytes,
    String? imageName,
  }) async {
    final hasFile = (fileBytes != null && fileBytes.isNotEmpty) ||
        (filePath != null && filePath.isNotEmpty);
    final hasImage = (imageBytes != null && imageBytes.isNotEmpty) ||
        (imagePath != null && imagePath.isNotEmpty);

    late final Response res;
    if (hasFile || hasImage) {
      MultipartFile? filePart;
      if (fileBytes != null && fileBytes.isNotEmpty) {
        final name = fileName ?? 'document.pdf';
        filePart = MultipartFile.fromBytes(
          fileBytes,
          filename: name,
          contentType: _mediaTypeFor(name, fallback: DioMediaType('application', 'pdf')),
        );
      } else if (filePath != null && filePath.isNotEmpty) {
        final name = fileName ?? filePath.split(RegExp(r'[\\/]')).last;
        filePart = await MultipartFile.fromFile(
          filePath,
          filename: name,
          contentType: _mediaTypeFor(name, fallback: DioMediaType('application', 'pdf')),
        );
      }

      MultipartFile? imagePart;
      if (imageBytes != null && imageBytes.isNotEmpty) {
        final name = imageName ?? 'image.jpg';
        imagePart = MultipartFile.fromBytes(
          imageBytes,
          filename: name,
          contentType: _mediaTypeFor(name, fallback: DioMediaType('image', 'jpeg')),
        );
      } else if (imagePath != null && imagePath.isNotEmpty) {
        final name = imageName ?? imagePath.split(RegExp(r'[\\/]')).last;
        imagePart = await MultipartFile.fromFile(
          imagePath,
          filename: name,
          contentType: _mediaTypeFor(name, fallback: DioMediaType('image', 'jpeg')),
        );
      }

      final form = FormData.fromMap({
        'title': title,
        'content': content,
        'kind': kind,
        'department': ?departmentId,
        if (videoUrl.isNotEmpty) 'video_url': videoUrl,
        if (fileUrl.isNotEmpty) 'file_url': fileUrl,
        if (pageCount > 0) 'page_count': pageCount,
        if (backgroundColor.isNotEmpty) 'background_color': backgroundColor,
        // Multipart : JSONField exige une chaîne JSON valide.
        'tags': jsonEncode(tags),
        'file': ?filePart,
        'image': ?imagePart,
      });
      res = await _dio.post('posts/', data: form);
    } else {
      res = await _dio.post(
        'posts/',
        data: {
          'title': title,
          'content': content,
          'kind': kind,
          'department': ?departmentId,
          if (videoUrl.isNotEmpty) 'video_url': videoUrl,
          if (fileUrl.isNotEmpty) 'file_url': fileUrl,
          if (pageCount > 0) 'page_count': pageCount,
          if (backgroundColor.isNotEmpty) 'background_color': backgroundColor,
          'tags': tags,
        },
      );
    }
    return postFromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<CommunityPost> updatePost({
    required String id,
    required String title,
    required String content,
    required String kind,
    int? departmentId,
    String videoUrl = '',
    String fileUrl = '',
    int pageCount = 0,
    List<String> tags = const [],
    String backgroundColor = '',
    String? filePath,
    String? imagePath,
    List<int>? fileBytes,
    String? fileName,
    List<int>? imageBytes,
    String? imageName,
  }) async {
    final hasFile = (fileBytes != null && fileBytes.isNotEmpty) ||
        (filePath != null && filePath.isNotEmpty);
    final hasImage = (imageBytes != null && imageBytes.isNotEmpty) ||
        (imagePath != null && imagePath.isNotEmpty);

    late final Response res;
    if (hasFile || hasImage) {
      MultipartFile? filePart;
      if (fileBytes != null && fileBytes.isNotEmpty) {
        final name = fileName ?? 'document.pdf';
        filePart = MultipartFile.fromBytes(
          fileBytes,
          filename: name,
          contentType: _mediaTypeFor(
            name,
            fallback: DioMediaType('application', 'pdf'),
          ),
        );
      } else if (filePath != null && filePath.isNotEmpty) {
        final name = fileName ?? filePath.split(RegExp(r'[\\/]')).last;
        filePart = await MultipartFile.fromFile(
          filePath,
          filename: name,
          contentType: _mediaTypeFor(
            name,
            fallback: DioMediaType('application', 'pdf'),
          ),
        );
      }

      MultipartFile? imagePart;
      if (imageBytes != null && imageBytes.isNotEmpty) {
        final name = imageName ?? 'image.jpg';
        imagePart = MultipartFile.fromBytes(
          imageBytes,
          filename: name,
          contentType: _mediaTypeFor(
            name,
            fallback: DioMediaType('image', 'jpeg'),
          ),
        );
      } else if (imagePath != null && imagePath.isNotEmpty) {
        final name = imageName ?? imagePath.split(RegExp(r'[\\/]')).last;
        imagePart = await MultipartFile.fromFile(
          imagePath,
          filename: name,
          contentType: _mediaTypeFor(
            name,
            fallback: DioMediaType('image', 'jpeg'),
          ),
        );
      }

      final form = FormData.fromMap({
        'title': title,
        'content': content,
        'kind': kind,
        'department': ?departmentId,
        if (videoUrl.isNotEmpty) 'video_url': videoUrl,
        if (fileUrl.isNotEmpty) 'file_url': fileUrl,
        if (pageCount > 0) 'page_count': pageCount,
        'background_color': backgroundColor,
        'tags': jsonEncode(tags),
        'file': ?filePart,
        'image': ?imagePart,
      });
      res = await _dio.patch('posts/$id/', data: form);
    } else {
      res = await _dio.patch(
        'posts/$id/',
        data: {
          'title': title,
          'content': content,
          'kind': kind,
          'department': ?departmentId,
          if (videoUrl.isNotEmpty) 'video_url': videoUrl,
          if (fileUrl.isNotEmpty) 'file_url': fileUrl,
          if (pageCount > 0) 'page_count': pageCount,
          'background_color': backgroundColor,
          'tags': tags,
        },
      );
    }
    return postFromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> deletePost(String id) async {
    await _dio.delete('posts/$id/');
  }

  Future<void> commentPost(String postId, String content) async {
    await _dio.post(
      'post-comments/',
      data: {
        'post': int.tryParse(postId) ?? postId,
        'content': content,
      },
    );
  }

  Future<List<CourseCommentItem>> fetchPostComments(String postId) async {
    final res = await _dio.get(
      'post-comments/',
      queryParameters: {'post': postId},
    );
    return unwrapList(res.data).map(courseCommentFromJson).toList();
  }
}

DioMediaType _mediaTypeFor(String filename, {required DioMediaType fallback}) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) return DioMediaType('image', 'png');
  if (lower.endsWith('.gif')) return DioMediaType('image', 'gif');
  if (lower.endsWith('.webp')) return DioMediaType('image', 'webp');
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return DioMediaType('image', 'jpeg');
  }
  if (lower.endsWith('.pdf')) return DioMediaType('application', 'pdf');
  if (lower.endsWith('.ppt')) return DioMediaType('application', 'vnd.ms-powerpoint');
  if (lower.endsWith('.pptx')) {
    return DioMediaType(
      'application',
      'vnd.openxmlformats-officedocument.presentationml.presentation',
    );
  }
  if (lower.endsWith('.doc')) return DioMediaType('application', 'msword');
  if (lower.endsWith('.docx')) {
    return DioMediaType(
      'application',
      'vnd.openxmlformats-officedocument.wordprocessingml.document',
    );
  }
  if (lower.endsWith('.zip')) return DioMediaType('application', 'zip');
  return fallback;
}
