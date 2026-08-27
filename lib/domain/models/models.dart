import 'package:equatable/equatable.dart';

import 'document_type.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.university,
    required this.faculty,
    required this.department,
    required this.promotion,
    required this.level,
    this.firstName = '',
    this.lastName = '',
    this.role = 'student',
    this.bio = '',
    this.avatarUrl,
    this.phone = '',
    this.reputation = 0,
    this.contributions = 0,
    this.badges = const [],
    this.postnom = '',
    this.headline = '',
    this.coverUrl,
    this.professionalDomain = '',
    this.company = '',
    this.graduationYear,
    this.universityId = '',
    this.facultyId = '',
    this.departmentId = '',
    this.promotionId = '',
    this.gender = '',
    this.birthDate,
    this.matricule = '',
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.pendingEmail = '',
  });

  final String id;
  final String name;
  final String firstName;
  final String lastName;
  final String email;
  final String university;
  final String faculty;
  final String department;
  final String promotion;
  final String level;
  final String role;
  final String bio;
  final String? avatarUrl;
  final String phone;
  final int reputation;
  final int contributions;
  final List<String> badges;
  final String postnom;
  final String headline;
  final String? coverUrl;
  final String professionalDomain;
  final String company;
  final int? graduationYear;
  final String universityId;
  final String facultyId;
  final String departmentId;
  final String promotionId;
  final String gender;
  final DateTime? birthDate;
  final String matricule;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final String pendingEmail;

  bool get isAlumni => role == 'alumni';
  bool get isTeacher => role == 'teacher' || role == 'admin';
  bool get isStudent => role == 'student';
  bool get isStaffTeacher => isTeacher;
  bool get usesTeacherShell => isTeacher;
  bool get usesStudentShell => !isTeacher;
  String get homeRoute => isTeacher ? '/teacher' : '/home';

  @override
  List<Object?> get props => [id, name, email, role, avatarUrl, pendingEmail];
}

class AcademicDocument extends Equatable {
  const AcademicDocument({
    required this.id,
    required this.title,
    required this.type,
    required this.author,
    required this.university,
    required this.department,
    required this.course,
    required this.year,
    required this.createdAt,
    this.authorId = '',
    this.sizeLabel = '2.4 Mo',
    this.downloads = 0,
    this.views = 0,
    this.favorites = 0,
    this.rating = 0,
    this.description = '',
    this.isApproved = true,
    this.moderationStatus = 'approved',
    this.rejectionReason = '',
    this.pointsAwarded = 0,
    this.externalUrl = '',
    this.fileUrl = '',
    this.peerValidationCount = 0,
    this.peerValidationsRequired = 10,
    this.userHasPeerValidated = false,
    this.canPeerValidate = false,
    this.userRating = 0,
    this.potentialPoints = 0,
  });

  final String id;
  final String title;
  final DocumentType type;
  final String author;
  final String authorId;
  final String university;
  final String department;
  final String course;
  final String year;
  final DateTime createdAt;
  final String sizeLabel;
  final int downloads;
  final int views;
  final int favorites;
  final double rating;
  final String description;
  final bool isApproved;
  final String moderationStatus;
  final String rejectionReason;
  final int pointsAwarded;
  final String externalUrl;
  final String fileUrl;
  final int peerValidationCount;
  final int peerValidationsRequired;
  final bool userHasPeerValidated;
  final bool canPeerValidate;
  final int userRating;
  final int potentialPoints;

  bool get awaitsPeerReview =>
      moderationStatus == 'pending_peers' || moderationStatus == 'pending';

  bool get awaitsAdminReview => moderationStatus == 'pending_admin';

  /// Aperçu toujours possible ; téléchargement seulement après 10 validations
  /// ou une fois le document approuvé.
  bool get canDownload =>
      isApproved || peerValidationCount >= peerValidationsRequired;

  String get previewUrl {
    if (fileUrl.trim().isNotEmpty) return fileUrl.trim();
    return externalUrl.trim();
  }

  bool get hasPreviewFile => previewUrl.isNotEmpty;

  double get peerValidationProgress => peerValidationsRequired <= 0
      ? 0
      : (peerValidationCount / peerValidationsRequired).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [id];
}

class Course extends Equatable {
  const Course({
    required this.id,
    required this.title,
    required this.code,
    required this.teacher,
    required this.semester,
    required this.credits,
    required this.department,
    this.description = '',
    this.objectives = '',
    this.skills = '',
    this.prerequisites = '',
    this.university = '',
    this.faculty = '',
    this.documentCount = 0,
    this.teacherTitle = 'Professeur',
    this.teacherFullName = '',
    this.teacherHeadline = '',
    this.teacherBio = '',
    this.teacherSpecialty = '',
    this.teacherAvatarUrl = '',
    this.teacherUniversity = '',
    this.promotion = '',
    this.coverUrl = '',
    this.levelLabel = '',
    this.estimatedHours = 0,
    this.views = 0,
    this.isApproved = true,
    this.moderationStatus = 'approved',
    this.moderationNote = '',
    this.domainSlugs = const [],
    this.domainNames = const [],
    this.submittedByName = '',
    this.submittedById = '',
  });

  final String id;
  final String title;
  final String code;
  final String teacher;
  final String teacherTitle;
  final String teacherFullName;
  final String teacherHeadline;
  final String teacherBio;
  final String teacherSpecialty;
  final String teacherAvatarUrl;
  final String teacherUniversity;
  final String semester;
  final String promotion;
  final int credits;
  final String department;
  final String description;
  final String objectives;
  final String skills;
  final String prerequisites;
  final String university;
  final String faculty;
  final int documentCount;
  final String coverUrl;
  final String levelLabel;
  final int estimatedHours;
  final int views;
  final bool isApproved;
  final String moderationStatus;
  final String moderationNote;
  final List<String> domainSlugs;
  final List<String> domainNames;
  final String submittedByName;
  final String submittedById;

  bool get needsModerationBadge =>
      moderationStatus != 'approved' && moderationStatus.isNotEmpty;

  String get primaryDomainSlug =>
      domainSlugs.isNotEmpty ? domainSlugs.first : '';

  String get displayTeacher {
    String clean(String s) {
      final t = s.trim();
      if (t.isEmpty || t == '—' || t == '-' || t.toLowerCase() == 'null') {
        return '';
      }
      return t;
    }

    var name = clean(teacherFullName);
    if (name.isEmpty) name = clean(teacher);
    if (name.isEmpty) return '';

    var title = clean(teacherTitle);

    final nameLower = name.toLowerCase();
    final titleLower = title.toLowerCase();
    if (nameLower.startsWith(titleLower)) return name;
    return '$title $name';
  }

  /// Badges promo · département · faculté (ex. L3 · Génie civil · Polytechnique).
  List<String> get academicTags {
    String shortFac(String f) {
      final t = f.trim();
      if (t.isEmpty) return '';
      final lower = t.toLowerCase();
      if (lower.contains('polytech')) return 'Polytechnique';
      if (lower.contains('droit')) return 'Droit';
      if (lower.contains('médecine') || lower.contains('medecine')) {
        return 'Médecine';
      }
      if (lower.contains('science')) return 'Sciences';
      if (lower.contains('éco') ||
          lower.contains('eco') ||
          lower.contains('gestion')) {
        return 'Économie';
      }
      if (lower.contains('lettre')) return 'Lettres';
      if (lower.contains('fasi') || lower.contains('info')) return 'FASI';
      return t
          .replaceFirst(
            RegExp(r'^Faculté\s+(de(s)?\s+)?', caseSensitive: false),
            '',
          )
          .trim();
    }

    String shortDept(String d) {
      final t = d.trim();
      if (t.isEmpty) return '';
      return t
          .replaceFirst(
            RegExp(r'^Département\s+(de(s)?\s+)?', caseSensitive: false),
            '',
          )
          .trim();
    }

    final promo = targetPromotion.trim();
    final dept = shortDept(department);
    final fac = shortFac(faculty);
    return [
      if (promo.isNotEmpty) promo,
      if (dept.isNotEmpty) dept,
      if (fac.isNotEmpty) fac,
    ];
  }

  String get targetPromotion {
    if (promotion.isNotEmpty) return promotion;
    return semester;
  }

  @override
  List<Object?> get props => [id];
}

class CommunityPost extends Equatable {
  const CommunityPost({
    required this.id,
    required this.author,
    required this.department,
    required this.title,
    required this.content,
    required this.createdAt,
    this.authorId = '',
    this.authorRole = 'student',
    this.authorAvatarUrl = '',
    this.authorUniversity = '',
    this.authorPromotion = '',
    this.kind = 'discussion',
    this.kindDisplay = '',
    this.videoUrl = '',
    this.attachmentUrl = '',
    this.imageUrl = '',
    this.pageCount = 0,
    this.likes = 0,
    this.comments = 0,
    this.tags = const [],
    this.isLiked = false,
    this.isSaved = false,
    this.isFollowingAuthor = false,
    this.isApproved = true,
    this.moderationStatus = 'approved',
    this.rejectionReason = '',
    this.backgroundColor = '',
  });

  final String id;
  final String author;
  final String authorId;
  final String authorRole;
  final String authorAvatarUrl;
  final String authorUniversity;
  final String authorPromotion;
  final String department;
  final String title;
  final String content;
  final String kind;
  final String kindDisplay;
  final String videoUrl;
  final String attachmentUrl;
  final String imageUrl;
  final int pageCount;
  final DateTime createdAt;
  final int likes;
  final int comments;
  final List<String> tags;
  final bool isLiked;
  final bool isSaved;
  final bool isFollowingAuthor;
  final bool isApproved;
  final String moderationStatus;
  final String rejectionReason;
  final String backgroundColor;

  bool get isAlumniContent => kind.startsWith('alumni_');
  bool get needsModerationBadge => moderationStatus != 'approved';
  bool get hasPdf => attachmentUrl.trim().isNotEmpty;
  bool get hasImage => imageUrl.trim().isNotEmpty;
  bool get hasVideo => videoUrl.trim().isNotEmpty;
  bool get hasMedia => hasPdf || hasImage || hasVideo;
  bool get isAcademicShare => const {
        'tp',
        'summary',
        'exam',
        'notes',
        'support',
        'rapport',
        'projet_tutore',
        'tfc',
        'memoire',
      }.contains(kind);

  CommunityPost copyWith({
    int? likes,
    int? comments,
    bool? isLiked,
    bool? isSaved,
  }) {
    return CommunityPost(
      id: id,
      author: author,
      department: department,
      title: title,
      content: content,
      createdAt: createdAt,
      authorId: authorId,
      authorRole: authorRole,
      authorAvatarUrl: authorAvatarUrl,
      authorUniversity: authorUniversity,
      authorPromotion: authorPromotion,
      kind: kind,
      kindDisplay: kindDisplay,
      videoUrl: videoUrl,
      attachmentUrl: attachmentUrl,
      imageUrl: imageUrl,
      pageCount: pageCount,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      tags: tags,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isFollowingAuthor: isFollowingAuthor,
      isApproved: isApproved,
      moderationStatus: moderationStatus,
      rejectionReason: rejectionReason,
      backgroundColor: backgroundColor,
    );
  }

  @override
  List<Object?> get props =>
      [id, likes, comments, isLiked, isSaved, backgroundColor];
}

class CourseLessonItem extends Equatable {
  const CourseLessonItem({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.contentType,
    required this.order,
    this.description = '',
    this.videoUrl = '',
    this.externalUrl = '',
    this.durationSeconds = 0,
    this.subtitlesUrl = '',
  });

  final String id;
  final String moduleId;
  final String title;
  final String contentType;
  final int order;
  final String description;
  final String videoUrl;
  final String externalUrl;
  final int durationSeconds;
  final String subtitlesUrl;

  bool get isVideo => contentType == 'video' && videoUrl.isNotEmpty;

  @override
  List<Object?> get props => [id];
}

class CourseModuleItem extends Equatable {
  const CourseModuleItem({
    required this.id,
    required this.title,
    required this.order,
    this.description = '',
    this.lessons = const [],
    this.courseId = '',
    this.courseTitle = '',
    this.courseCode = '',
  });

  final String id;
  final String title;
  final int order;
  final String description;
  final List<CourseLessonItem> lessons;
  final String courseId;
  final String courseTitle;
  final String courseCode;

  @override
  List<Object?> get props => [id];
}

class CourseOutline extends Equatable {
  const CourseOutline({
    required this.course,
    this.modules = const [],
  });

  final Course course;
  final List<CourseModuleItem> modules;

  @override
  List<Object?> get props => [course.id];
}

class CourseCommentItem extends Equatable {
  const CourseCommentItem({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    this.authorRole = '',
    this.parentId,
  });

  final String id;
  final String author;
  final String authorRole;
  final String content;
  final DateTime createdAt;
  final String? parentId;

  @override
  List<Object?> get props => [id];
}

class ChatThread extends Equatable {
  const ChatThread({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.updatedAt,
    this.unread = 0,
    this.isGroup = false,
  });

  final String id;
  final String name;
  final String lastMessage;
  final DateTime updatedAt;
  final int unread;
  final bool isGroup;

  @override
  List<Object?> get props => [id];
}

class UniversityAnnouncement extends Equatable {
  const UniversityAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.category = 'Annonce',
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String category;

  @override
  List<Object?> get props => [id];
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.message,
    required this.createdAt,
    this.points = 0,
    this.isRead = false,
  });

  final String id;
  final String kind;
  final String title;
  final String message;
  final int points;
  final bool isRead;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id];
}

class FollowedAlumni extends Equatable {
  const FollowedAlumni({
    required this.id,
    required this.alumniId,
    required this.name,
    required this.avatarUrl,
    required this.bio,
    required this.department,
    required this.followedAt,
  });

  final String id;
  final String alumniId;
  final String name;
  final String avatarUrl;
  final String bio;
  final String department;
  final DateTime followedAt;

  @override
  List<Object?> get props => [id];
}
