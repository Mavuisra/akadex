import '../../domain/models/document_type.dart';
import '../../domain/models/models.dart';

int asInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

double asDouble(dynamic value, [double fallback = 0]) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

DocumentType documentTypeFromApi(String? value) {
  return switch (value) {
    'support_cours' => DocumentType.supportCours,
    'resume' => DocumentType.resume,
    'pdf' => DocumentType.pdf,
    'word' => DocumentType.word,
    'powerpoint' => DocumentType.powerpoint,
    'image' => DocumentType.image,
    'video' => DocumentType.video,
    'lien' => DocumentType.lien,
    'livre' => DocumentType.livre,
    'tp' => DocumentType.tp,
    'corrige' => DocumentType.corrige,
    'interrogation' => DocumentType.interrogation,
    'examen' => DocumentType.examen,
    'rapport' => DocumentType.rapport,
    'projet' => DocumentType.projet,
    'memoire' => DocumentType.memoire,
    'these' => DocumentType.these,
    'article' => DocumentType.article,
    'tutoriel' => DocumentType.tutoriel,
    'fiche_revision' => DocumentType.ficheRevision,
    _ => DocumentType.pdf,
  };
}

String? documentTypeToApi(DocumentType? type) {
  if (type == null) return null;
  return switch (type) {
    DocumentType.supportCours => 'support_cours',
    DocumentType.resume => 'resume',
    DocumentType.pdf => 'pdf',
    DocumentType.word => 'word',
    DocumentType.powerpoint => 'powerpoint',
    DocumentType.image => 'image',
    DocumentType.video => 'video',
    DocumentType.lien => 'lien',
    DocumentType.livre => 'livre',
    DocumentType.tp => 'tp',
    DocumentType.corrige => 'corrige',
    DocumentType.interrogation => 'interrogation',
    DocumentType.examen => 'examen',
    DocumentType.rapport => 'rapport',
    DocumentType.projet => 'projet',
    DocumentType.memoire => 'memoire',
    DocumentType.these => 'these',
    DocumentType.article => 'article',
    DocumentType.tutoriel => 'tutoriel',
    DocumentType.ficheRevision => 'fiche_revision',
  };
}

UserProfile userFromJson(Map<String, dynamic> json) {
  final first = (json['first_name'] ?? '').toString();
  final last = (json['last_name'] ?? '').toString();
  final full = (json['full_name'] ?? '').toString().trim();
  final name = full.isNotEmpty
      ? full
      : ('$first $last').trim().isEmpty
          ? (json['email'] ?? 'Étudiant').toString()
          : ('$first $last').trim();

  return UserProfile(
    id: json['id'].toString(),
    name: name,
    email: (json['email'] ?? '').toString(),
    university: (json['university_name'] ?? '').toString(),
    faculty: (json['faculty_name'] ?? '').toString(),
    department: (json['department_name'] ?? '').toString(),
    promotion: (json['promotion_name'] ?? '').toString(),
    level: (json['level'] ?? '').toString(),
    role: (json['role'] ?? 'student').toString(),
    bio: (json['bio'] ?? '').toString(),
    avatarUrl: json['avatar']?.toString(),
    reputation: asInt(json['reputation']),
    contributions: asInt(json['contributions_count']),
    badges: (json['badges'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
  );
}

AcademicDocument documentFromJson(Map<String, dynamic> json) {
  return AcademicDocument(
    id: json['id'].toString(),
    title: (json['title'] ?? '').toString(),
    type: documentTypeFromApi(json['doc_type']?.toString()),
    author: (json['author_name'] ?? '').toString(),
    university: (json['university_name'] ?? '').toString(),
    department: (json['department_name'] ?? '').toString(),
    course: (json['course_title'] ?? json['course_code'] ?? '').toString(),
    year: (json['academic_year'] ?? '').toString(),
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now(),
    sizeLabel: (json['size_label'] ?? '').toString().isEmpty
        ? _formatSize(asInt(json['file_size']))
        : json['size_label'].toString(),
    downloads: asInt(json['downloads']),
    views: asInt(json['views']),
    favorites: asInt(json['favorites_count']),
    rating: asDouble(json['rating_avg']),
    description: (json['description'] ?? '').toString(),
  );
}

Course courseFromJson(Map<String, dynamic> json) {
  final teachers = (json['teacher_names'] as List?) ?? const [];
  return Course(
    id: json['id'].toString(),
    title: (json['title'] ?? '').toString(),
    code: (json['code'] ?? '').toString(),
    teacher: teachers.isEmpty ? '—' : teachers.first.toString(),
    semester: (json['semester'] ?? '').toString(),
    credits: asInt(json['credits']),
    department: (json['department_name'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
    objectives: (json['objectives'] ?? '').toString(),
    skills: (json['skills'] ?? '').toString(),
    prerequisites: (json['prerequisites'] ?? '').toString(),
    university: (json['university_name'] ?? '').toString(),
    faculty: (json['faculty_name'] ?? '').toString(),
    documentCount: asInt(json['document_count']),
  );
}

CommunityPost postFromJson(Map<String, dynamic> json) {
  return CommunityPost(
    id: json['id'].toString(),
    author: (json['author_name'] ?? '').toString(),
    authorId: (json['author_id'] ?? json['author'] ?? '').toString(),
    authorRole: (json['author_role'] ?? 'student').toString(),
    department: (json['department_name'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    content: (json['content'] ?? '').toString(),
    kind: (json['kind'] ?? 'discussion').toString(),
    kindDisplay: (json['kind_display'] ?? '').toString(),
    videoUrl: (json['video_url'] ?? '').toString(),
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now(),
    likes: asInt(json['likes_count']),
    comments: asInt(json['comments_count']),
    tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
    isLiked: json['is_liked'] == true,
    isSaved: json['is_saved'] == true,
    isFollowingAuthor: json['is_following_author'] == true,
  );
}

CourseLessonItem lessonFromJson(Map<String, dynamic> json) {
  return CourseLessonItem(
    id: json['id'].toString(),
    moduleId: (json['module'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    contentType: (json['content_type'] ?? 'video').toString(),
    order: asInt(json['order']),
    description: (json['description'] ?? '').toString(),
    videoUrl: (json['video_url'] ?? '').toString(),
    externalUrl: (json['external_url'] ?? '').toString(),
    durationSeconds: asInt(json['duration_seconds']),
    subtitlesUrl: (json['subtitles_url'] ?? '').toString(),
  );
}

CourseModuleItem moduleFromJson(Map<String, dynamic> json) {
  final lessons = (json['lessons'] as List?) ?? const [];
  return CourseModuleItem(
    id: json['id'].toString(),
    title: (json['title'] ?? '').toString(),
    order: asInt(json['order']),
    description: (json['description'] ?? '').toString(),
    lessons: lessons
        .whereType<Map>()
        .map((e) => lessonFromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );
}

CourseOutline outlineFromJson(Map<String, dynamic> json) {
  final modules = (json['modules'] as List?) ?? const [];
  return CourseOutline(
    course: courseFromJson(json),
    modules: modules
        .whereType<Map>()
        .map((e) => moduleFromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );
}

CourseCommentItem courseCommentFromJson(Map<String, dynamic> json) {
  return CourseCommentItem(
    id: json['id'].toString(),
    author: (json['author_name'] ?? '').toString(),
    authorRole: (json['author_role'] ?? '').toString(),
    content: (json['content'] ?? '').toString(),
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now(),
    parentId: json['parent']?.toString(),
  );
}

UniversityAnnouncement announcementFromJson(Map<String, dynamic> json) {
  return UniversityAnnouncement(
    id: json['id'].toString(),
    title: (json['title'] ?? '').toString(),
    body: (json['body'] ?? '').toString(),
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now(),
    category: (json['category'] ?? 'Annonce').toString(),
  );
}

class CalendarEventItem {
  const CalendarEventItem({
    required this.id,
    required this.title,
    required this.description,
    required this.eventType,
    required this.startsAt,
    this.location = '',
  });

  final String id;
  final String title;
  final String description;
  final String eventType;
  final DateTime startsAt;
  final String location;
}

CalendarEventItem eventFromJson(Map<String, dynamic> json) {
  return CalendarEventItem(
    id: json['id'].toString(),
    title: (json['title'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
    eventType: (json['event_type'] ?? '').toString(),
    startsAt: DateTime.tryParse(json['starts_at']?.toString() ?? '') ??
        DateTime.now(),
    location: (json['location'] ?? '').toString(),
  );
}

class UniversityItem {
  const UniversityItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.city,
    required this.country,
    this.description = '',
  });

  final String id;
  final String name;
  final String slug;
  final String city;
  final String country;
  final String description;

  String get code => slug.toUpperCase().replaceAll('-', ' ').split(' ').first;
}

UniversityItem universityFromJson(Map<String, dynamic> json) {
  return UniversityItem(
    id: json['id'].toString(),
    name: (json['name'] ?? '').toString(),
    slug: (json['slug'] ?? '').toString(),
    city: (json['city'] ?? '').toString(),
    country: (json['country'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
  );
}

class DepartmentItem {
  const DepartmentItem({
    required this.id,
    required this.name,
    required this.facultyName,
    required this.universityId,
  });

  final String id;
  final String name;
  final String facultyName;
  final String universityId;
}

DepartmentItem departmentFromJson(Map<String, dynamic> json) {
  return DepartmentItem(
    id: json['id'].toString(),
    name: (json['name'] ?? '').toString(),
    facultyName: (json['faculty_name'] ?? '').toString(),
    universityId: json['university'].toString(),
  );
}

String _formatSize(int bytes) {
  if (bytes <= 0) return '—';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(0)} Ko';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
}

String formatCount(int n) {
  if (n >= 1000) {
    final v = n / 1000;
    return '${v.toStringAsFixed(v >= 10 ? 0 : 1)}K';
  }
  return '$n';
}

String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
  return '${date.day}/${date.month}/${date.year}';
}
