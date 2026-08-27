import 'package:akadex/core/notifications/push_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PushNotificationService.routeForMessage', () {
    test('route explicite', () {
      final m = RemoteMessage(data: {'route': '/profile'});
      expect(PushNotificationService.routeForMessage(m), '/profile');
    });

    test('kinds messages → chat', () {
      expect(
        PushNotificationService.routeForMessage(
          RemoteMessage(
            data: {
              'kind': 'message',
              'conversation_id': '99',
            },
          ),
        ),
        '/messages/chat/99',
      );
    });

    test('kinds payment → /learn', () {
      expect(
        PushNotificationService.routeForMessage(
          RemoteMessage(data: {'kind': 'payment'}),
        ),
        '/learn',
      );
    });

    test('kinds documents → /library', () {
      expect(
        PushNotificationService.routeForMessage(
          RemoteMessage(data: {'kind': 'document_approved'}),
        ),
        '/library',
      );
      expect(
        PushNotificationService.routeForMessage(
          RemoteMessage(data: {'kind': 'document_rejected'}),
        ),
        '/library',
      );
    });

    test('kinds posts → /home', () {
      expect(
        PushNotificationService.routeForMessage(
          RemoteMessage(data: {'kind': 'post_approved'}),
        ),
        '/home',
      );
    });

    test('défaut → /notifications', () {
      expect(
        PushNotificationService.routeForMessage(const RemoteMessage()),
        '/notifications',
      );
      expect(
        PushNotificationService.routeForMessage(
          RemoteMessage(data: {'kind': 'general'}),
        ),
        '/notifications',
      );
    });
  });
}
