import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';

final pushTokenRepositoryProvider = Provider<PushTokenRepository>((ref) {
  return PushTokenRepository(ref.watch(dioProvider));
});

class PushTokenRepository {
  PushTokenRepository(this._dio);

  final Dio _dio;

  static String get platform {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'unknown';
    }
  }

  Future<void> registerToken(String token) async {
    if (kIsWeb || token.isEmpty) return;
    await _dio.post(
      'auth/push-token/',
      data: {'token': token, 'platform': platform},
    );
  }

  Future<void> unregisterToken([String? token]) async {
    if (kIsWeb) return;
    await _dio.delete(
      'auth/push-token/',
      data: token != null && token.isNotEmpty ? {'token': token} : null,
    );
  }

  Future<Map<String, dynamic>> sendTestPush({
    String title = 'Test Akadex',
    String body = 'Les notifications push fonctionnent 🎉',
  }) async {
    final res = await _dio.post(
      'auth/push-test/',
      data: {'title': title, 'body': body},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }
}
