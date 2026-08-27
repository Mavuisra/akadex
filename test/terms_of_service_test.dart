import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:akadex/features/profile/presentation/screens/help_privacy_screens.dart';

void main() {
  testWidgets('TermsOfServiceScreen shows CGU sections', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const TermsOfServiceScreen(),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    expect(find.text('Conditions d’utilisation'), findsOneWidget);
    expect(find.text('1. Objet'), findsOneWidget);
    expect(find.text('4. Achats de cours'), findsOneWidget);
  });
}
