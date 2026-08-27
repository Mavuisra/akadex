import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:akadex/features/profile/presentation/screens/help_privacy_screens.dart';

void main() {
  testWidgets('privacy policy mentions account deletion and uninstall', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const PrivacySettingsScreen(),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    final deletionTitle = find.text('Suppression de compte');
    await tester.scrollUntilVisible(
      deletionTitle,
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(deletionTitle, findsOneWidget);

    expect(find.textContaining('Android'), findsWidgets);
    expect(find.textContaining('Supprimer mon compte'), findsWidgets);
  });
}
