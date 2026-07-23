import 'package:akadex/core/theme/akadex_theme.dart';
import 'package:akadex/features/shell/teacher_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Reproduit la config critique : root key + 2 StatefulShellRoute + overlay.
GoRouter _buildDualShellRouter({
  required GlobalKey<NavigatorState> root,
  required GlobalKey<StatefulNavigationShellState> teacherShell,
  required GlobalKey<StatefulNavigationShellState> studentShell,
  required List<GlobalKey<NavigatorState>> teacherNavs,
  required List<GlobalKey<NavigatorState>> studentNavs,
}) {
  return GoRouter(
    navigatorKey: root,
    initialLocation: '/teacher',
    routes: [
      StatefulShellRoute.indexedStack(
        key: teacherShell,
        builder: (context, state, shell) {
          return TeacherShell(navigationShell: shell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: teacherNavs[0],
            routes: [
              GoRoute(
                path: '/teacher',
                builder: (_, _) => const Scaffold(
                  body: Center(child: Text('hub-enseignant')),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: teacherNavs[1],
            routes: [
              GoRoute(
                path: '/teacher-publish',
                builder: (_, _) => const Scaffold(
                  body: Center(child: Text('publier')),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: teacherNavs[2],
            routes: [
              GoRoute(
                path: '/teacher-dashboard',
                builder: (_, _) => const Scaffold(
                  body: Center(child: Text('tableau-de-bord')),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: teacherNavs[3],
            routes: [
              GoRoute(
                path: '/teacher-profile',
                builder: (_, _) => const Scaffold(
                  body: Center(child: Text('profil-ens')),
                ),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        key: studentShell,
        builder: (context, state, shell) {
          return Scaffold(
            body: shell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: shell.currentIndex,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home), label: 'Accueil'),
                NavigationDestination(
                  icon: Icon(Icons.school),
                  label: 'Apprendre',
                ),
              ],
              onDestinationSelected: shell.goBranch,
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: studentNavs[0],
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, _) => const Scaffold(
                  body: Center(child: Text('accueil-etudiant')),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: studentNavs[1],
            routes: [
              GoRoute(
                path: '/learn',
                builder: (_, _) => const Scaffold(
                  body: Center(child: Text('apprendre')),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/teacher-course',
        parentNavigatorKey: root,
        builder: (_, _) => const Scaffold(
          body: Center(child: Text('creer-cours')),
        ),
      ),
      GoRoute(
        path: '/library/course/:id',
        parentNavigatorKey: root,
        builder: (_, state) => Scaffold(
          body: Center(child: Text('cours-${state.pathParameters['id']}')),
        ),
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'dual shell + root key : navigation enseignant sans GlobalKey crash',
    (tester) async {
      final root = GlobalKey<NavigatorState>(debugLabel: 'root');
      final tShell =
          GlobalKey<StatefulNavigationShellState>(debugLabel: 'shell-teacher');
      final sShell =
          GlobalKey<StatefulNavigationShellState>(debugLabel: 'shell-student');
      final tNavs = [
        for (var i = 0; i < 4; i++)
          GlobalKey<NavigatorState>(debugLabel: 't-nav-$i'),
      ];
      final sNavs = [
        for (var i = 0; i < 2; i++)
          GlobalKey<NavigatorState>(debugLabel: 's-nav-$i'),
      ];

      final router = _buildDualShellRouter(
        root: root,
        teacherShell: tShell,
        studentShell: sShell,
        teacherNavs: tNavs,
        studentNavs: sNavs,
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AkadexTheme.light(),
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('hub-enseignant'), findsOneWidget);
      expect(find.byType(TeacherShell), findsOneWidget);
      expect(find.text('Tableau'), findsOneWidget);

      // Onglets shell
      router.go('/teacher-dashboard');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('tableau-de-bord'), findsOneWidget);

      router.go('/teacher-publish');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('publier'), findsOneWidget);

      // Overlay root (comme Publier un cours)
      router.push('/teacher-course');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('creer-cours'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Switch vers shell étudiant puis retour enseignant
      router.go('/home');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('accueil-etudiant'), findsOneWidget);

      router.go('/teacher');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('hub-enseignant'), findsOneWidget);

      router.push('/library/course/99');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('cours-99'), findsOneWidget);
    },
  );
}
