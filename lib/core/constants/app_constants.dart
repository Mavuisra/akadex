import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'Akadex';
  static const String appTagline = 'Le campus numérique des étudiants';
  static const String defaultUniversity = 'Université de Kinshasa';

  static const String logoAsset = 'assets/images/logo.png';
  static const String presentationAsset = 'assets/images/presentation.png';

  /// URLs légales (App Store / Play Store).
  static const String privacyPolicyUrl =
      'https://akadex.onrender.com/legal/privacy/';
  static const String termsOfServiceUrl =
      'https://akadex.onrender.com/legal/terms/';
  static const String deleteAccountUrl =
      'https://akadex.onrender.com/legal/delete-account/';

  static const String _prodApi = 'https://akadex.onrender.com/api/';

  /// Override : `--dart-define=API_BASE_URL=http://192.168.x.x:8000/api/`
  ///
  /// En debug sans override → backend local (même source que `/enseignant/`).
  /// En release → Render.
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kDebugMode) {
      // Émulateur Android : localhost de la machine hôte.
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:8000/api/';
      }
      return 'http://127.0.0.1:8000/api/';
    }
    return _prodApi;
  }

  static bool get isLocalApi =>
      apiBaseUrl.contains('127.0.0.1') || apiBaseUrl.contains('10.0.2.2');
}
