import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:akadex/features/ai/presentation/screens/ai_assistant_screen.dart';

void main() {
  testWidgets('AI screen is unavailable, not a fake chat', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const AiAssistantScreen(),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    expect(find.text('Bientôt disponible'), findsOneWidget);
    expect(find.textContaining('chat fictif'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
