import 'package:akadex/features/shell/student_shell.dart';
import 'package:akadex/features/shell/teacher_shell.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('StudentShell affiche Alumni et Communauté', (tester) async {
    final router = GoRouter(
      initialLocation: '/a',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return StudentShell(navigationShell: navigationShell);
          },
          branches: [
            for (final path in ['/a', '/b', '/c', '/d', '/e', '/f'])
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: path,
                    builder: (_, _) => Text('page$path'),
                  ),
                ],
              ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump(); // PageAtmosphere anime en boucle

    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Alumni'), findsOneWidget);
    expect(find.text('Communauté'), findsOneWidget);
    expect(find.text('Mes cours'), findsNothing);
    expect(find.text('Publier'), findsNothing);
  });

  testWidgets('TeacherShell affiche Mes cours et Publier, pas Alumni',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/t1',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return TeacherShell(navigationShell: navigationShell);
          },
          branches: [
            for (final path in ['/t1', '/t2', '/t3', '/t4'])
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: path,
                    builder: (_, _) => Text('page$path'),
                  ),
                ],
              ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    expect(find.text('Mes cours'), findsOneWidget);
    expect(find.text('Publier'), findsOneWidget);
    expect(find.text('Tableau'), findsOneWidget);
    expect(find.text('Alumni'), findsNothing);
    expect(find.text('Communauté'), findsNothing);
    expect(find.text('Accueil'), findsNothing);
    expect(find.byType(CupertinoTabBar), findsOneWidget);
  });
}
