import 'package:equatable/equatable.dart';

import '../mappers/mappers.dart';

class ChatPeer extends Equatable {
  const ChatPeer({
    required this.id,
    required this.name,
    this.avatarUrl = '',
    this.isOnline = false,
    this.lastSeenAt,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final bool isOnline;
  final DateTime? lastSeenAt;

  factory ChatPeer.fromJson(Map<String, dynamic> json) {
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
            ? (json['email'] ?? 'Utilisateur').toString()
            : composed;

    return ChatPeer(
      id: json['id'].toString(),
      name: name,
      avatarUrl: (json['avatar'] ?? '').toString(),
      isOnline: json['is_online'] == true,
      lastSeenAt: DateTime.tryParse(json['last_seen_at']?.toString() ?? ''),
    );
  }

  @override
  List<Object?> get props => [id, name, avatarUrl, isOnline, lastSeenAt];
}

class ChatActivity extends Equatable {
  const ChatActivity({
    required this.userId,
    required this.userName,
    this.isTyping = false,
    this.isRecording = false,
    this.updatedAt,
  });

  final String userId;
  final String userName;
  final bool isTyping;
  final bool isRecording;
  final DateTime? updatedAt;

  factory ChatActivity.fromJson(Map<String, dynamic> json) {
    return ChatActivity(
      userId: json['user'].toString(),
      userName: (json['user_name'] ?? '').toString(),
      isTyping: json['is_typing'] == true,
      isRecording: json['is_recording'] == true,
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  @override
  List<Object?> get props =>
      [userId, userName, isTyping, isRecording, updatedAt];
}

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.createdAt,
    this.senderAvatar = '',
    this.content = '',
    this.kind = 'text',
    this.attachmentUrl = '',
    this.audioDurationMs = 0,
    this.deliveryStatus = 'sent',
    this.isRead = false,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String content;
  final String kind;
  final String attachmentUrl;
  final int audioDurationMs;
  final String deliveryStatus;
  final DateTime createdAt;
  final bool isRead;

  bool get isAudio => kind == 'audio';
  bool get isText => kind == 'text' || kind.isEmpty;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'].toString(),
      conversationId: json['conversation'].toString(),
      senderId: json['sender'].toString(),
      senderName: (json['sender_name'] ?? '').toString(),
      senderAvatar: (json['sender_avatar'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      kind: (json['kind'] ?? 'text').toString(),
      attachmentUrl: (json['attachment_url'] ?? '').toString(),
      audioDurationMs: asInt(json['audio_duration_ms']),
      deliveryStatus: (json['delivery_status'] ?? 'sent').toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isRead: json['is_read'] == true,
    );
  }

  ChatMessage copyWith({
    String? deliveryStatus,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: content,
      kind: kind,
      attachmentUrl: attachmentUrl,
      audioDurationMs: audioDurationMs,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        content,
        kind,
        attachmentUrl,
        audioDurationMs,
        deliveryStatus,
        createdAt,
        isRead,
      ];
}

class ChatConversation extends Equatable {
  const ChatConversation({
    required this.id,
    required this.updatedAt,
    this.name = '',
    this.isGroup = false,
    this.peer,
    this.lastMessage,
    this.unreadCount = 0,
    this.activities = const [],
    this.createdAt,
  });

  final String id;
  final String name;
  final bool isGroup;
  final ChatPeer? peer;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final List<ChatActivity> activities;
  final DateTime? createdAt;
  final DateTime updatedAt;

  String get displayName =>
      peer?.name.isNotEmpty == true
          ? peer!.name
          : (name.isNotEmpty ? name : 'Conversation');

  String get avatarUrl => peer?.avatarUrl ?? '';

  bool get peerIsTyping =>
      activities.any((a) => a.isTyping && !a.isRecording);

  bool get peerIsRecording => activities.any((a) => a.isRecording);

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final last = json['last_message'];
    final peer = json['peer'];
    final acts = json['activities'];
    return ChatConversation(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      isGroup: json['is_group'] == true,
      peer: peer is Map
          ? ChatPeer.fromJson(Map<String, dynamic>.from(peer))
          : null,
      lastMessage: last is Map
          ? ChatMessage.fromJson(Map<String, dynamic>.from(last))
          : null,
      unreadCount: asInt(json['unread_count']),
      activities: acts is List
          ? acts
              .whereType<Map>()
              .map((e) => ChatActivity.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  ChatConversation copyWith({
    ChatPeer? peer,
    ChatMessage? lastMessage,
    int? unreadCount,
    List<ChatActivity>? activities,
    DateTime? updatedAt,
  }) {
    return ChatConversation(
      id: id,
      name: name,
      isGroup: isGroup,
      peer: peer ?? this.peer,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      activities: activities ?? this.activities,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        isGroup,
        peer,
        lastMessage,
        unreadCount,
        activities,
        updatedAt,
      ];
}

class ChatPollResult {
  const ChatPollResult({
    required this.conversation,
    required this.messages,
  });

  final ChatConversation conversation;
  final List<ChatMessage> messages;

  factory ChatPollResult.fromJson(Map<String, dynamic> json) {
    final conv = json['conversation'];
    final msgs = json['messages'];
    return ChatPollResult(
      conversation: ChatConversation.fromJson(
        Map<String, dynamic>.from(conv as Map),
      ),
      messages: msgs is List
          ? msgs
              .whereType<Map>()
              .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}
