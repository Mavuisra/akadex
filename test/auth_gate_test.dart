import 'package:akadex/core/router/app_router.dart';
import 'package:akadex/core/theme/akadex_theme.dart';
import 'package:akadex/data/api/api_client.dart';
import 'package:akadex/data/auth/auth_repository.dart';
import 'package:akadex/data/local/local_academic_store.dart';
import 'package:akadex/data/sync/sync_service.dart';
import 'package:akadex/domain/models/models.dart';
import 'package:akadex/features/auth/presentation/screens/login_screen.dart';
import 'package:akadex/features/shell/student_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

UserProfile _student() => const UserProfile(
      id: '7',
      name: 'Isra Mavu',
      email: 'isra@unikin.ac.cd',
      university: 'UNIKIN',
      faculty: 'Sciences',
      department: 'Informatique',
      promotion: 'L2',
      level: 'L2',
      role: 'student',
      departmentId: '1',
    );

class _FakeAuth extends AuthController {
  _FakeAuth(super.repo, UserProfile? user) {
    state = AsyncValue.data(user);
  }

  @override
  Future<void> restore() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> containerWith(UserProfile? user) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localStoreProvider.overrideWithValue(LocalAcademicStore.memory()),
        authStateProvider.overrideWith(
          (ref) => _FakeAuth(ref.watch(authRepositoryProvider), user),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  testWidgets('invité : /home et /learn → /login', (tester) async {
    final container = await containerWith(null);
    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AkadexTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    router.go('/home');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(StudentShell), findsNothing);

    router.go('/learn');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
    expect(find.byType(LoginScreen), findsOneWidget);

    router.go('/messages');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
  });

  testWidgets('étudiant connecté : /home accessible, /login → /home',
      (tester) async {
    final container = await containerWith(_student());
    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AkadexTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    router.go('/login');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(router.routerDelegate.currentConfiguration.uri.path, '/home');
    expect(find.byType(StudentShell), findsOneWidget);

    router.go('/home');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(router.routerDelegate.currentConfiguration.uri.path, '/home');
    expect(find.byType(StudentShell), findsOneWidget);
  });
}
