import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:akadex/app.dart';
import 'package:akadex/data/api/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Akadex démarre sur l’onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const AkadexApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Akadex'), findsWidgets);
    expect(find.text('Suivant'), findsOneWidget);
  });
}
