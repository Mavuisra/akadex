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
    this.bio = '',
    this.avatarUrl,
    this.reputation = 0,
    this.contributions = 0,
    this.badges = const [],
  });

  final String id;
  final String name;
  final String email;
  final String university;
  final String faculty;
  final String department;
  final String promotion;
  final String level;
  final String bio;
  final String? avatarUrl;
  final int reputation;
  final int contributions;
  final List<String> badges;

  @override
  List<Object?> get props => [id, name, email];
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
    this.likes = 0,
    this.comments = 0,
    this.tags = const [],
  });

  final String id;
  final String author;
  final String department;
  final String title;
  final String content;
  final DateTime createdAt;
  final int likes;
  final int comments;
  final List<String> tags;

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
