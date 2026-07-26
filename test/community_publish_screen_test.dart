import 'package:akadex/core/theme/akadex_theme.dart';
import 'package:akadex/data/api/api_client.dart';
import 'package:akadex/features/community/presentation/screens/community_publish_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('CommunityPublishScreen affiche le formulaire', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          theme: AkadexTheme.light(),
          home: const CommunityPublishScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('Nouvelle publication'), findsOneWidget);
    expect(find.text('Quoi de neuf ?'), findsOneWidget);
    expect(find.text('Publier'), findsOneWidget);
    expect(find.text('Public'), findsOneWidget);
    expect(find.text('Étudiant'), findsOneWidget);

    final contextField = find.textContaining('Contexte académique');
    await tester.scrollUntilVisible(
      contextField,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(contextField, findsOneWidget);
    expect(find.text('Galerie'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('Caméra'), findsOneWidget);
    expect(find.textContaining('3 Mo'), findsOneWidget);
  });

  testWidgets('FilledButton thème ne casse plus un Row', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AkadexTheme.light(),
        home: Scaffold(
          body: Row(
            children: [
              const Text('Public'),
              const Spacer(),
              FilledButton(onPressed: () {}, child: const Text('Publier')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Publier'), findsOneWidget);
  });
}
