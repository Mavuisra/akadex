import 'package:shared_preferences/shared_preferences.dart';

/// Coach marks barre étudiant — une seule fois pour les nouveaux utilisateurs.
abstract final class StudentFeatureTour {
  static const prefsKey = 'student_feature_tour_v1_done';

  /// Au premier boot de cette feature :
  /// - session déjà connectée (maj app) → marquer terminé (pas de tour)
  /// - install fraîche / pas encore loggé → tour après 1ʳᵉ entrée campus
  static Future<void> migrateForExistingSessions(
    SharedPreferences prefs,
  ) async {
    if (prefs.containsKey(prefsKey)) return;
    final hasSession =
        (prefs.getString('access_token') ?? '').isNotEmpty;
    await prefs.setBool(prefsKey, hasSession);
  }

  static bool isDone(SharedPreferences prefs) =>
      prefs.getBool(prefsKey) ?? true;

  static Future<void> markDone(SharedPreferences prefs) =>
      prefs.setBool(prefsKey, true);

  static const steps = <FeatureTourStep>[
    FeatureTourStep(
      tabIndex: 0,
      title: 'Accueil',
      body:
          'Ton fil campus : documents et partages liés à ton parcours.',
    ),
    FeatureTourStep(
      tabIndex: 1,
      title: 'Apprendre',
      body: 'Cours vidéo pour progresser.',
    ),
    FeatureTourStep(
      tabIndex: 2,
      title: 'Ma Fac',
      body: 'Les docs de ta filière : UE, examens, supports utiles.',
    ),
    FeatureTourStep(
      tabIndex: 3,
      title: 'Profil',
      body: 'Compte, messages, notifications et paramètres.',
    ),
  ];
}

class FeatureTourStep {
  const FeatureTourStep({
    required this.tabIndex,
    required this.title,
    required this.body,
  });

  final int tabIndex;
  final String title;
  final String body;
}
