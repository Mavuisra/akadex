import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/api/api_client.dart';
import '../../data/repositories/push_token_repository.dart';

const _fcmTokenPrefsKey = 'fcm_token';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase peut deja etre initialise.
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(
    ref.watch(sharedPreferencesProvider),
    ref.watch(pushTokenRepositoryProvider),
  );
});

class PushNotificationService {
  PushNotificationService(this._prefs, this._pushTokens);

  final SharedPreferences _prefs;
  final PushTokenRepository _pushTokens;
  bool _initialized = false;
  bool _loggedIn = false;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _messageSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;

  static Future<void> bootstrap() async {
    if (kIsWeb) return;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('FCM bootstrap non initialise: $e');
    }
  }

  Future<void> initialize({required bool isLoggedIn}) async {
    _loggedIn = isLoggedIn;
    if (_initialized || kIsWeb) return;
    _initialized = true;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _prefs.setString(_fcmTokenPrefsKey, token);
        if (_loggedIn) {
          await _registerWithBackend(token);
        }
      }

      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = messaging.onTokenRefresh.listen((token) async {
        await _prefs.setString(_fcmTokenPrefsKey, token);
        if (_loggedIn) {
          await _registerWithBackend(token);
        }
      });

      _messageSub?.cancel();
      _messageSub = FirebaseMessaging.onMessage.listen((message) {
        debugPrint(
          'Push recue (foreground): ${message.notification?.title ?? ''} '
          '${message.notification?.body ?? ''}',
        );
      });

      _openedAppSub?.cancel();
      _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('Push cliquee: ${message.messageId}');
      });
    } catch (e) {
      debugPrint('Initialisation FCM echouee: $e');
    }
  }

  Future<void> onAuthChanged({required bool isLoggedIn}) async {
    _loggedIn = isLoggedIn;
    if (kIsWeb) return;
    final token = cachedToken;
    if (!isLoggedIn) {
      await unregisterFromBackend(token: token);
      return;
    }
    if (token != null && token.isNotEmpty) {
      await _registerWithBackend(token);
    } else if (_initialized) {
      try {
        final fresh = await FirebaseMessaging.instance.getToken();
        if (fresh != null && fresh.isNotEmpty) {
          await _prefs.setString(_fcmTokenPrefsKey, fresh);
          await _registerWithBackend(fresh);
        }
      } catch (e) {
        debugPrint('Recuperation token FCM echouee: $e');
      }
    }
  }

  Future<void> unregisterFromBackend({String? token}) async {
    try {
      await _pushTokens.unregisterToken(token ?? cachedToken);
    } catch (e) {
      debugPrint('Desenregistrement token FCM echoue: $e');
    }
  }

  Future<void> _registerWithBackend(String token) async {
    try {
      await _pushTokens.registerToken(token);
    } catch (e) {
      debugPrint('Enregistrement token FCM echoue: $e');
    }
  }

  String? get cachedToken => _prefs.getString(_fcmTokenPrefsKey);
}
