import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Demandes runtime caméra / galerie / notifications (Android 13+ & iOS).
abstract final class MediaPermissions {
  static Future<bool> ensureCamera() async {
    if (kIsWeb) return true;
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> ensureGallery() async {
    if (kIsWeb) return true;
    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
    }
    if (Platform.isAndroid) {
      // Android 13+ : photos ; sinon storage (maxSdk 32 dans le manifest).
      final photos = await Permission.photos.request();
      if (photos.isGranted || photos.isLimited) return true;
      final storage = await Permission.storage.request();
      return storage.isGranted;
    }
    return true;
  }

  static Future<bool> ensureNotifications() async {
    if (kIsWeb) return true;
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  }

  static String deniedMessage({required bool camera}) {
    if (camera) {
      return 'Autorise la caméra dans les réglages pour prendre une photo.';
    }
    return 'Autorise l’accès aux photos dans les réglages.';
  }
}
