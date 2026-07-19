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
  });

  final String id;
  final String title;
  final DocumentType type;
  final String author;
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
  });

  final String id;
  final String title;
  final String code;
  final String teacher;
  final String semester;
  final int credits;
  final String department;
  final String description;
  final String objectives;
  final String skills;
  final String prerequisites;
  final String university;
  final String faculty;
  final int documentCount;

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
    this.kind = 'discussion',
    this.kindDisplay = '',
    this.videoUrl = '',
    this.likes = 0,
    this.comments = 0,
    this.tags = const [],
    this.isLiked = false,
    this.isSaved = false,
    this.isFollowingAuthor = false,
    this.isApproved = true,
    this.moderationStatus = 'approved',
    this.rejectionReason = '',
  });

  final String id;
  final String author;
  final String authorId;
  final String authorRole;
  final String authorAvatarUrl;
  final String department;
  final String title;
  final String content;
  final String kind;
  final String kindDisplay;
  final String videoUrl;
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

  bool get isAlumniContent => kind.startsWith('alumni_');
  bool get needsModerationBadge => moderationStatus != 'approved';

  @override
  List<Object?> get props => [id];
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
  });

  final String id;
  final String title;
  final int order;
  final String description;
  final List<CourseLessonItem> lessons;

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
