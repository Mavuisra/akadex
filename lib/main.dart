import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/onboarding/student_feature_tour.dart';
import 'data/api/api_client.dart';
import 'data/local/local_academic_store.dart';
import 'data/sync/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  await PushNotificationService.bootstrap();
  final prefs = await SharedPreferences.getInstance();
  await StudentFeatureTour.migrateForExistingSessions(prefs);
  final localStore = await LocalAcademicStore.open();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localStoreProvider.overrideWithValue(localStore),
      ],
      child: const AkadexApp(),
    ),
  );
}
