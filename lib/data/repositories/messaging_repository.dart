import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_client.dart';
import '../models/messaging_models.dart';

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return MessagingRepository(ref.watch(dioProvider));
});

final conversationsProvider =
    FutureProvider.autoDispose<List<ChatConversation>>((ref) {
  return ref.watch(messagingRepositoryProvider).fetchConversations();
});

final conversationMessagesProvider = FutureProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, conversationId) {
  return ref
      .watch(messagingRepositoryProvider)
      .fetchMessages(conversationId);
});

class MessagingRepository {
  MessagingRepository(this._dio);

  final Dio _dio;

  Future<List<ChatConversation>> fetchConversations() async {
    final res = await _dio.get('conversations/');
    return unwrapList(res.data)
        .map(ChatConversation.fromJson)
        .toList();
  }

  Future<ChatConversation> startConversation(String userId) async {
    final res = await _dio.post(
      'conversations/start/',
      data: {'user_id': userId},
    );
    return ChatConversation.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  Future<List<ChatMessage>> fetchMessages(
    String conversationId, {
    String? search,
  }) async {
    final res = await _dio.get(
      'messages/',
      queryParameters: {
        'conversation': conversationId,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return unwrapList(res.data).map(ChatMessage.fromJson).toList();
  }

  Future<ChatMessage> sendText({
    required String conversationId,
    required String content,
  }) async {
    final res = await _dio.post(
      'messages/',
      data: {
        'conversation': conversationId,
        'content': content,
        'kind': 'text',
      },
    );
    return ChatMessage.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<ChatMessage> sendAudio({
    required String conversationId,
    required String filePath,
    required int durationMs,
    String? content,
    XFile? file,
  }) async {
    MultipartFile multipart;
    if (file != null) {
      final filename = file.name.isNotEmpty
          ? file.name
          : 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final bytes = await file.readAsBytes();
      multipart = MultipartFile.fromBytes(bytes, filename: filename);
    } else {
      final filename = filePath.split(RegExp(r'[\\/]')).last;
      multipart = await MultipartFile.fromFile(
        filePath,
        filename: filename.isEmpty ? 'voice.m4a' : filename,
      );
    }

    final form = FormData.fromMap({
      'conversation': conversationId,
      'kind': 'audio',
      'audio_duration_ms': durationMs,
      if (content != null && content.isNotEmpty) 'content': content,
      'attachment': multipart,
    });

    final res = await _dio.post('messages/', data: form);
    return ChatMessage.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> markRead(String conversationId) async {
    await _dio.post('conversations/$conversationId/mark_read/');
  }

  Future<void> setTyping({
    required String conversationId,
    bool isTyping = false,
    bool isRecording = false,
  }) async {
    await _dio.post(
      'conversations/$conversationId/typing/',
      data: {
        'is_typing': isTyping,
        'is_recording': isRecording,
      },
    );
  }

  Future<ChatPollResult> poll(
    String conversationId, {
    DateTime? after,
  }) async {
    final res = await _dio.get(
      'conversations/$conversationId/poll/',
      queryParameters: {
        'after': ?after?.toUtc().toIso8601String(),
      },
    );
    return ChatPollResult.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }
}
