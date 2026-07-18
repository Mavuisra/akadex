class AppConstants {
  static const String appName = 'Akadex';
  static const String appTagline = 'Le campus numérique des étudiants';
  static const String defaultUniversity = 'Université de Kinshasa';

  static const String logoAsset = 'assets/images/logo.png';
  static const String presentationAsset = 'assets/images/presentation.png';

  /// API Django locale (Chrome / Windows). Android émulateur : 10.0.2.2
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/',
  );
}
