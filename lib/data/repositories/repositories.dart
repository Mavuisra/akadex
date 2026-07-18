import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/document_type.dart';
import '../../domain/models/models.dart';
import '../api/api_client.dart';
import '../mappers/mappers.dart';

final academicRepositoryProvider = Provider<AcademicRepository>((ref) {
  return AcademicRepository(ref.watch(dioProvider));
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

final departmentsProvider = FutureProvider<List<DepartmentItem>>((ref) {
  return ref.watch(academicRepositoryProvider).fetchDepartments();
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

final courseOutlineProvider =
    FutureProvider.family<CourseOutline, String>((ref, id) {
  return ref.watch(academicRepositoryProvider).fetchCourseOutline(id);
});

final courseCommentsProvider =
    FutureProvider.family<List<CourseCommentItem>, String>((ref, courseId) {
  return ref.watch(academicRepositoryProvider).fetchCourseComments(courseId);
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
  AcademicRepository(this._dio);

  final Dio _dio;

  Future<List<AcademicDocument>> fetchDocuments(DocumentQuery query) async {
    final res = await _dio.get(
      'documents/',
      queryParameters: {
        if (query.search != null && query.search!.trim().isNotEmpty)
          'search': query.search!.trim(),
        if (query.docType != null) 'doc_type': documentTypeToApi(query.docType),
        if (query.courseId != null) 'course': query.courseId,
        if (query.featuredOnly) 'is_featured': true,
        'ordering': query.ordering,
      },
    );
    return unwrapList(res.data).map(documentFromJson).toList();
  }

  Future<AcademicDocument> fetchDocument(String id) async {
    final res = await _dio.get('documents/$id/');
    return documentFromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<List<Course>> fetchCourses() async {
    final res = await _dio.get('courses/', queryParameters: {'ordering': 'code'});
    return unwrapList(res.data).map(courseFromJson).toList();
  }

  Future<Course> fetchCourse(String id) async {
    final res = await _dio.get('courses/$id/');
    return courseFromJson(Map<String, dynamic>.from(res.data as Map));
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
    await _dio.post(
      'course-comments/',
      data: {'course': int.tryParse(courseId) ?? courseId, 'content': content},
    );
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
    await _dio.post(
      'course-lessons/$lessonId/progress/',
      data: {
        'position_seconds': positionSeconds,
        'completed': completed,
      },
    );
  }

  Future<Map<String, dynamic>?> fetchLessonProgress(String lessonId) async {
    final res = await _dio.get(
      'lesson-progress/',
      queryParameters: {'lesson': lessonId},
    );
    final list = unwrapList(res.data);
    if (list.isEmpty) return null;
    return list.first;
  }

  Future<List<UniversityItem>> fetchUniversities() async {
    final res = await _dio.get('universities/');
    return unwrapList(res.data).map(universityFromJson).toList();
  }

  Future<List<DepartmentItem>> fetchDepartments() async {
    final res = await _dio.get('departments/');
    return unwrapList(res.data).map(departmentFromJson).toList();
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

  Future<List<CommunityPost>> fetchPosts({String? scope}) async {
    final res = await _dio.get(
      'posts/',
      queryParameters: {
        'ordering': '-created_at',
        if (scope != null) 'scope': scope,
      },
    );
    return unwrapList(res.data).map(postFromJson).toList();
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
        if (departmentId != null) 'department': departmentId,
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
}
