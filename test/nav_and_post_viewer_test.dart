import 'package:akadex/core/theme/akadex_theme.dart';
import 'package:akadex/core/widgets/post_viewer_screens.dart';
import 'package:akadex/data/api/api_client.dart';
import 'package:akadex/data/repositories/repositories.dart';
import 'package:akadex/domain/models/models.dart';
import 'package:akadex/features/learn/presentation/screens/learn_screen.dart';
import 'package:akadex/features/shell/student_shell.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('StudentShell verrouille Apprendre (plus Explorer)', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return StudentShell(navigationShell: navigationShell);
          },
          branches: [
            for (final path in [
              '/home',
              '/learn',
              '/library',
              '/community',
              '/alumni',
              '/profile',
            ])
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: path,
                    builder: (_, _) => Center(child: Text(path)),
                  ),
                ],
              ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AkadexTheme.light(),
        routerConfig: router,
      ),
    );
    await tester.pump();

    final bar = tester.widget<CupertinoTabBar>(find.byType(CupertinoTabBar));
    final labels = bar.items.map((e) => e.label).toList();
    expect(labels, contains('Apprendre'));
    expect(labels, isNot(contains('Explorer')));
    expect(labels, isNot(contains('Bibliothèque')));
    expect(labels, contains('Accueil'));
    expect(labels, contains('Ma Fac'));
  });

  testWidgets('LearnScreen affiche les domaines et cours', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          coursesProvider.overrideWith(_FakeCoursesNotifier.new),
        ],
        child: MaterialApp(
          theme: AkadexTheme.light(),
          home: const LearnScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Cours'), findsWidgets);
    expect(find.text('Cours populaires'), findsOneWidget);
    expect(find.text('Informatique'), findsWidgets);
  });

  testWidgets('TextPostViewerScreen affiche le contenu', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final post = CommunityPost(
      id: '1',
      author: 'Aicha',
      department: '',
      title: 't',
      content: 'Bonjour campus Akadex',
      createdAt: DateTime.now(),
      backgroundColor: '#1877F2',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          postCommentsProvider.overrideWith((ref, id) async => const []),
        ],
        child: MaterialApp(
          theme: AkadexTheme.light(),
          home: TextPostViewerScreen(post: post),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Bonjour campus Akadex'), findsOneWidget);
    expect(find.text('Aicha'), findsWidgets);
  });
}

class _FakeCoursesNotifier extends CoursesNotifier {
  @override
  Future<List<Course>> build() async => const [
        Course(
          id: '1',
          title: 'Algorithmes',
          code: 'INFO101',
          teacher: 'Mukendi',
          teacherTitle: 'Prof.',
          teacherFullName: 'David Mukendi',
          semester: 'L1',
          promotion: 'L1',
          credits: 5,
          department: 'Informatique',
          faculty: 'FASI',
        ),
      ];
}
