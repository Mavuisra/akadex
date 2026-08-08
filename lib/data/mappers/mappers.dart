import '../../core/theme/status_backgrounds.dart';
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
    'projet_tutore' => DocumentType.projetTutore,
    'tfc' => DocumentType.tfc,
    'memoire' => DocumentType.memoire,
    'these' => DocumentType.these,
    'article' => DocumentType.article,
    'tutoriel' => DocumentType.tutoriel,
    'fiche_revision' => DocumentType.ficheRevision,
    'autre' => DocumentType.autre,
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
    DocumentType.projetTutore => 'projet_tutore',
    DocumentType.tfc => 'tfc',
    DocumentType.memoire => 'memoire',
    DocumentType.these => 'these',
    DocumentType.article => 'article',
    DocumentType.tutoriel => 'tutoriel',
    DocumentType.ficheRevision => 'fiche_revision',
    DocumentType.autre => 'autre',
  };
}

UserProfile userFromJson(Map<String, dynamic> json) {
  final first = (json['first_name'] ?? '').toString();
  final last = (json['last_name'] ?? '').toString();
  final postnom = (json['postnom'] ?? '').toString();
  final full = (json['full_name'] ?? '').toString().trim();
  final composed = [first, postnom, last]
      .where((p) => p.trim().isNotEmpty)
      .join(' ')
      .trim();
  final name = full.isNotEmpty
      ? full
      : composed.isEmpty
          ? (json['email'] ?? 'Étudiant').toString()
          : composed;

  return UserProfile(
    id: json['id'].toString(),
    name: name,
    firstName: first,
    lastName: last,
    email: (json['email'] ?? '').toString(),
    university: (json['university_name'] ?? '').toString(),
    faculty: (json['faculty_name'] ?? '').toString(),
    department: (json['department_name'] ?? '').toString(),
    promotion: (json['promotion_name'] ?? '').toString(),
    level: (json['level'] ?? '').toString(),
    role: (json['role'] ?? 'student').toString(),
    bio: (json['bio'] ?? '').toString(),
    avatarUrl: json['avatar']?.toString(),
    phone: (json['phone'] ?? '').toString(),
    reputation: asInt(json['reputation']),
    contributions: asInt(json['contributions_count']),
    badges: (json['badges'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
    postnom: postnom,
    headline: (json['headline'] ?? '').toString(),
    coverUrl: json['cover']?.toString(),
    professionalDomain: (json['professional_domain'] ?? '').toString(),
    company: (json['company'] ?? '').toString(),
    graduationYear: json['graduation_year'] == null
        ? null
        : asInt(json['graduation_year']),
    universityId: (json['university'] ?? '').toString(),
    facultyId: (json['faculty'] ?? '').toString(),
    departmentId: (json['department'] ?? '').toString(),
    promotionId: (json['promotion'] ?? '').toString(),
    gender: (json['gender'] ?? '').toString(),
    birthDate: DateTime.tryParse(json['birth_date']?.toString() ?? ''),
    matricule: (json['matricule'] ?? '').toString(),
    followersCount: asInt(json['followers_count']),
    followingCount: asInt(json['following_count']),
    postsCount: asInt(json['posts_count']),
    pendingEmail: (json['pending_email'] ?? '').toString(),
  );
}

AcademicDocument documentFromJson(Map<String, dynamic> json) {
  return AcademicDocument(
    id: json['id'].toString(),
    title: (json['title'] ?? '').toString(),
    type: documentTypeFromApi(json['doc_type']?.toString()),
    author: (json['author_name'] ?? '').toString(),
    authorId: (json['author'] ?? json['author_id'] ?? '').toString(),
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
    isApproved: json['is_approved'] != false,
    moderationStatus: (json['moderation_status'] ??
            (json['is_approved'] == true ? 'approved' : 'pending'))
        .toString(),
    rejectionReason: (json['rejection_reason'] ?? '').toString(),
    pointsAwarded: asInt(json['points_awarded']),
    externalUrl: (json['external_url'] ?? '').toString(),
  );
}

String _cleanTeacherName(String raw) {
  final t = raw.trim();
  if (t.isEmpty || t == '—' || t == '-' || t.toLowerCase() == 'null') {
    return '';
  }
  return t;
}

Course courseFromJson(Map<String, dynamic> json) {
  final teachers = (json['teacher_names'] as List?) ?? const [];
  final fullName = _cleanTeacherName(
    (json['teacher_full_name'] ?? '').toString(),
  );
  final fromList = teachers
      .map((e) => _cleanTeacherName(e.toString()))
      .firstWhere((e) => e.isNotEmpty, orElse: () => '');
  final teacherNameField =
      _cleanTeacherName((json['teacher_name'] ?? '').toString());
  final resolvedName = fullName.isNotEmpty
      ? fullName
      : (fromList.isNotEmpty ? fromList : teacherNameField);
  final domains = (json['domains'] as List?) ?? const [];
  final domainSlugs = <String>[];
  final domainNames = <String>[];
  for (final d in domains) {
    if (d is Map) {
      final slug = (d['slug'] ?? '').toString();
      final name = (d['name'] ?? '').toString();
      if (slug.isNotEmpty) domainSlugs.add(slug);
      if (name.isNotEmpty) domainNames.add(name);
    }
  }
  return Course(
    id: json['id'].toString(),
    title: (json['title'] ?? '').toString(),
    code: (json['code'] ?? '').toString(),
    teacher: resolvedName,
    teacherTitle: (() {
      final t = _cleanTeacherName((json['teacher_title'] ?? '').toString());
      return t.isEmpty ? 'Professeur' : t;
    })(),
    teacherFullName: resolvedName,
    teacherHeadline: (json['teacher_headline'] ?? '').toString(),
    teacherBio: (json['teacher_bio'] ?? '').toString(),
    teacherSpecialty: (json['teacher_specialty'] ?? '').toString(),
    teacherAvatarUrl: (json['teacher_avatar_url'] ?? '').toString(),
    teacherUniversity: (json['teacher_university'] ?? '').toString(),
    semester: (json['semester'] ?? '').toString(),
    promotion: (json['promotion'] ?? json['semester'] ?? '').toString(),
    credits: asInt(json['credits']),
    department: (json['department_name'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
    objectives: (json['objectives'] ?? '').toString(),
    skills: (json['skills'] ?? '').toString(),
    prerequisites: (json['prerequisites'] ?? '').toString(),
    university: (json['university_name'] ?? '').toString(),
    faculty: (json['faculty_name'] ?? '').toString(),
    documentCount: asInt(json['document_count']),
    coverUrl: (json['cover_url'] ?? '').toString(),
    levelLabel: (json['level_label'] ?? '').toString(),
    estimatedHours: asInt(json['estimated_hours']),
    views: asInt(json['views']),
    isApproved: json['is_approved'] != false,
    moderationStatus: (json['moderation_status'] ??
            (json['is_approved'] == true ? 'approved' : 'pending'))
        .toString(),
    moderationNote: (json['moderation_note'] ?? '').toString(),
    domainSlugs: domainSlugs,
    domainNames: domainNames,
    submittedByName: (json['submitted_by_name'] ?? '').toString(),
    submittedById: (json['submitted_by'] ?? '').toString(),
  );
}

CommunityPost postFromJson(Map<String, dynamic> json) {
  final tags = (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
      const <String>[];
  var backgroundColor = (json['background_color'] ?? '').toString();
  if (backgroundColor.trim().isEmpty) {
    backgroundColor = StatusBackgrounds.hexFromTags(tags) ?? '';
  }
  return CommunityPost(
    id: json['id'].toString(),
    author: (json['author_name'] ?? '').toString(),
    authorId: (json['author_id'] ?? json['author'] ?? '').toString(),
    authorRole: (json['author_role'] ?? 'student').toString(),
    authorAvatarUrl: (json['author_avatar'] ?? '').toString(),
    authorUniversity: (json['author_university'] ?? '').toString(),
    authorPromotion: (json['author_promotion'] ?? '').toString(),
    department: (json['department_name'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    content: (json['content'] ?? '').toString(),
    kind: (json['kind'] ?? 'discussion').toString(),
    kindDisplay: (json['kind_display'] ?? '').toString(),
    videoUrl: (json['video_url'] ?? '').toString(),
    attachmentUrl: (json['attachment_url'] ?? json['file_url'] ?? '').toString(),
    imageUrl: (json['image_url'] ?? '').toString(),
    pageCount: asInt(json['page_count']),
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now(),
    likes: asInt(json['likes_count']),
    comments: asInt(json['comments_count']),
    tags: tags,
    isLiked: json['is_liked'] == true,
    isSaved: json['is_saved'] == true,
    isFollowingAuthor: json['is_following_author'] == true,
    isApproved: json['is_approved'] != false,
    moderationStatus: (json['moderation_status'] ?? 'approved').toString(),
    rejectionReason: (json['rejection_reason'] ?? '').toString(),
    backgroundColor: backgroundColor,
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
    courseId: (json['course_id'] ?? json['course'] ?? '').toString(),
    courseTitle: (json['course_title'] ?? '').toString(),
    courseCode: (json['course_code'] ?? '').toString(),
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
    this.facultyId = '',
  });

  final String id;
  final String name;
  final String facultyName;
  final String universityId;
  final String facultyId;
}

DepartmentItem departmentFromJson(Map<String, dynamic> json) {
  return DepartmentItem(
    id: json['id'].toString(),
    name: (json['name'] ?? '').toString(),
    facultyName: (json['faculty_name'] ?? '').toString(),
    universityId: json['university'].toString(),
    facultyId: (json['faculty'] ?? '').toString(),
  );
}

class FacultyItem {
  const FacultyItem({
    required this.id,
    required this.name,
    required this.universityId,
  });

  final String id;
  final String name;
  final String universityId;
}

FacultyItem facultyFromJson(Map<String, dynamic> json) {
  return FacultyItem(
    id: json['id'].toString(),
    name: (json['name'] ?? '').toString(),
    universityId: (json['university'] ?? '').toString(),
  );
}

class PromotionItem {
  const PromotionItem({
    required this.id,
    required this.name,
    required this.departmentId,
    this.year = 0,
    this.level = '',
  });

  final String id;
  final String name;
  final String departmentId;
  final int year;
  final String level;
}

PromotionItem promotionFromJson(Map<String, dynamic> json) {
  return PromotionItem(
    id: json['id'].toString(),
    name: (json['name'] ?? '').toString(),
    departmentId: (json['department'] ?? '').toString(),
    year: asInt(json['year']),
    level: (json['level'] ?? '').toString(),
  );
}

AppNotification notificationFromJson(Map<String, dynamic> json) {
  return AppNotification(
    id: json['id'].toString(),
    kind: (json['kind'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    message: (json['message'] ?? '').toString(),
    points: asInt(json['points']),
    isRead: json['is_read'] == true,
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now(),
  );
}

String moderationStatusLabel(String status) => switch (status) {
      'pending' => 'En attente de validation',
      'changes_requested' => 'Modification demandée',
      'approved' => 'Validé',
      'rejected' => 'Rejeté',
      _ => status,
    };

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
  if (diff.isNegative || diff.inSeconds < 45) return 'à l’instant';
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
  return '${date.day}/${date.month}/${date.year}';
}
