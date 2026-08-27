import 'package:akadex/core/onboarding/student_feature_tour.dart';
import 'package:akadex/data/api/api_client.dart';
import 'package:akadex/features/shell/student_shell.dart';
import 'package:akadex/features/shell/teacher_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _prefs({bool tourDone = true}) async {
  SharedPreferences.setMockInitialValues({
    StudentFeatureTour.prefsKey: tourDone,
  });
  return SharedPreferences.getInstance();
}

Widget _shellApp(SharedPreferences prefs) {
  final router = GoRouter(
    initialLocation: '/a',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return StudentShell(navigationShell: navigationShell);
        },
        branches: [
          for (final path in ['/a', '/b', '/c', '/d'])
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

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('StudentShell : Accueil · Apprendre · Ma Fac · Profil',
      (tester) async {
    final prefs = await _prefs();
    await tester.pumpWidget(_shellApp(prefs));
    await tester.pump();

    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Apprendre'), findsOneWidget);
    expect(find.text('Ma Fac'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Alumni'), findsNothing);
    expect(find.text('Communauté'), findsNothing);
    expect(find.text('Mes cours'), findsNothing);
  });

  testWidgets('StudentShell : coach marks pour nouvel utilisateur',
      (tester) async {
    final prefs = await _prefs(tourDone: false);
    await tester.pumpWidget(_shellApp(prefs));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.text(
        'Ton fil campus : documents et partages liés à ton parcours.',
      ),
      findsOneWidget,
    );
    expect(find.text('Suivant'), findsOneWidget);

    await tester.tap(find.text('Suivant'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.textContaining('Cours vidéo'), findsOneWidget);

    await tester.tap(find.text('Passer'));
    await tester.pump();
    expect(find.text('Suivant'), findsNothing);
    expect(StudentFeatureTour.isDone(prefs), isTrue);
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
    expect(find.text('Alumni'), findsNothing);
  });

  test('migrateForExistingSessions saute le tour si déjà connecté', () async {
    SharedPreferences.setMockInitialValues({'access_token': 'x'});
    final prefs = await SharedPreferences.getInstance();
    await StudentFeatureTour.migrateForExistingSessions(prefs);
    expect(StudentFeatureTour.isDone(prefs), isTrue);
  });

  test('migrateForExistingSessions active le tour pour install fraîche',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await StudentFeatureTour.migrateForExistingSessions(prefs);
    expect(StudentFeatureTour.isDone(prefs), isFalse);
  });
}
