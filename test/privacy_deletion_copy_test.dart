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

    expect(find.text('Suppression de compte'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();

    expect(find.textContaining('Android'), findsWidgets);
    expect(find.textContaining('Supprimer mon compte'), findsWidgets);
  });
}
