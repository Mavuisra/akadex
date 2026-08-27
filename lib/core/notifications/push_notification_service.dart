import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/api/api_client.dart';
import '../../data/repositories/push_token_repository.dart';
import '../permissions/media_permissions.dart';

const _fcmTokenPrefsKey = 'fcm_token';
const _androidChannelId = 'akadex_general';
const _androidChannelName = 'Akadex';

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

typedef PushOpenCallback = void Function(RemoteMessage message);

class PushNotificationService {
  PushNotificationService(this._prefs, this._pushTokens);

  final SharedPreferences _prefs;
  final PushTokenRepository _pushTokens;
  bool _initialized = false;
  bool _loggedIn = false;
  PushOpenCallback? _onOpen;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _messageSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static Future<void> bootstrap() async {
    if (kIsWeb) return;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);
    } catch (e) {
      debugPrint('FCM/Crashlytics bootstrap non initialise: $e');
    }
  }

  Future<void> initialize({
    required bool isLoggedIn,
    PushOpenCallback? onOpen,
  }) async {
    _loggedIn = isLoggedIn;
    _onOpen = onOpen;
    if (_initialized || kIsWeb) return;
    _initialized = true;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      await _initLocalNotifications();
      await MediaPermissions.ensureNotifications();

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
        unawaited(_showForegroundNotification(message));
      });

      _openedAppSub?.cancel();
      _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleOpen);

      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        _handleOpen(initial);
      }
    } catch (e) {
      debugPrint('Initialisation FCM echouee: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        // Tap sur notif locale (foreground) → notifications in-app.
        _onOpen?.call(
          RemoteMessage(
            data: {'kind': 'general', 'route': '/notifications'},
          ),
        );
      },
    );

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: 'Notifications Akadex',
        importance: Importance.high,
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    // iOS affiche déjà via setForegroundNotificationPresentationOptions.
    if (Platform.isIOS) return;

    await _local.show(
      message.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: 'Notifications Akadex',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: message.data['notification_id']?.toString(),
    );
  }

  void _handleOpen(RemoteMessage message) {
    debugPrint(
      'Push cliquee: ${message.messageId} kind=${message.data['kind']}',
    );
    _onOpen?.call(message);
  }

  /// Route cible depuis le payload FCM (défaut: /notifications).
  static String routeForMessage(RemoteMessage message) {
    final explicit = (message.data['route'] ?? '').toString().trim();
    if (explicit.startsWith('/')) return explicit;
    final kind = (message.data['kind'] ?? '').toString();
    switch (kind) {
      case 'message':
        final cid = (message.data['conversation_id'] ?? '').toString();
        if (cid.isNotEmpty) return '/messages/chat/$cid';
        return '/messages';
      case 'payment':
        return '/learn';
      case 'document_approved':
      case 'document_rejected':
        return '/library';
      case 'post_approved':
      case 'post_rejected':
        return '/home';
      default:
        return '/notifications';
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
