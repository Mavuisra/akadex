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

final coursesProvider = FutureProvider<List<Course>>((ref) {
  return ref.watch(academicRepositoryProvider).fetchCourses();
});

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

final alumniProfileProvider =
    FutureProvider.family<UserProfile, String>((ref, userId) {
  return ref.watch(communityRepositoryProvider).fetchUser(userId);
});

final alumniPostsByAuthorProvider =
    FutureProvider.family<List<CommunityPost>, String>((ref, authorId) {
  return ref.watch(communityRepositoryProvider).fetchPosts(
        scope: 'alumni',
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
    this.featuredOnly = false,
    this.ordering = '-downloads',
  });

  final String? search;
  final DocumentType? docType;
  final String? courseId;
  final bool featuredOnly;
  final String ordering;

  @override
  bool operator ==(Object other) =>
      other is DocumentQuery &&
      other.search == search &&
      other.docType == docType &&
      other.courseId == courseId &&
      other.featuredOnly == featuredOnly &&
      other.ordering == ordering;

  @override
  int get hashCode =>
      Object.hash(search, docType, courseId, featuredOnly, ordering);
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

  Future<List<Course>> fetchCourses() async {
    try {
      final all = <Map<String, dynamic>>[];
      var path = 'courses/?ordering=code';
      while (true) {
        final res = await _dio.get(path);
        all.addAll(unwrapList(res.data));
        final next = res.data is Map ? res.data['next'] : null;
        if (next == null) break;
        final uri = Uri.parse(next.toString());
        path = uri.path.contains('/api/')
            ? next.toString().split('/api/').last
            : 'courses/?${uri.query}';
        if (all.length > 2000) break;
      }
      await _store.upsertCourses(all);
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

  Future<CourseModuleItem> createModule(Map<String, dynamic> data) async {
    final res = await _dio.post('course-modules/', data: data);
    return moduleFromJson(Map<String, dynamic>.from(res.data as Map));
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

  Future<List<UniversityItem>> fetchUniversities() async {
    try {
      final res = await _dio.get('universities/');
      final raw = unwrapList(res.data);
      await _store.upsertUniversities(raw);
      return raw.map(universityFromJson).toList();
    } catch (_) {
      return _store.getUniversities();
    }
  }

  Future<List<DepartmentItem>> fetchDepartments({String? universityId}) async {
    final res = await _dio.get(
      'departments/',
      queryParameters: {
        if (universityId != null && universityId.isNotEmpty)
          'faculty__university': universityId,
      },
    );
    return unwrapList(res.data).map(departmentFromJson).toList();
  }

  Future<List<FacultyItem>> fetchFaculties({String? universityId}) async {
    final res = await _dio.get(
      'faculties/',
      queryParameters: {
        if (universityId != null && universityId.isNotEmpty)
          'university': universityId,
      },
    );
    return unwrapList(res.data).map(facultyFromJson).toList();
  }

  Future<List<PromotionItem>> fetchPromotions({String? departmentId}) async {
    final res = await _dio.get(
      'promotions/',
      queryParameters: {
        if (departmentId != null && departmentId.isNotEmpty)
          'department': departmentId,
      },
    );
    return unwrapList(res.data).map(promotionFromJson).toList();
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

  Future<List<CommunityPost>> fetchPosts({String? scope, String? authorId}) async {
    final res = await _dio.get(
      'posts/',
      queryParameters: {
        'ordering': '-created_at',
        'scope': ?scope,
        'author': ?authorId,
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
  }) async {
    final res = await _dio.post(
      'posts/',
      data: {
        'title': title,
        'content': content,
        'kind': kind,
        'department': ?departmentId,
        if (videoUrl.isNotEmpty) 'video_url': videoUrl,
        'tags': <String>[],
      },
    );
    return postFromJson(Map<String, dynamic>.from(res.data as Map));
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
