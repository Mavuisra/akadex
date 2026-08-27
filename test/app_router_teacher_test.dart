import 'package:akadex/core/router/app_router.dart';
import 'package:akadex/core/theme/akadex_theme.dart';
import 'package:akadex/data/api/api_client.dart';
import 'package:akadex/data/auth/auth_repository.dart';
import 'package:akadex/data/local/local_academic_store.dart';
import 'package:akadex/data/sync/sync_service.dart';
import 'package:akadex/domain/models/models.dart';
import 'package:akadex/features/shell/teacher_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

UserProfile _teacher() => const UserProfile(
      id: '42',
      name: 'Pierre Kabongo',
      email: 'kabongo@unikin.ac.cd',
      university: 'UNIKIN',
      faculty: 'Sciences',
      department: 'Informatique',
      promotion: 'L2',
      level: 'L2',
      role: 'teacher',
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

  testWidgets('routerProvider enseignant : pas de crash GlobalKey', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localStoreProvider.overrideWithValue(LocalAcademicStore.memory()),
        authStateProvider.overrideWith(
          (ref) => _FakeAuth(ref.watch(authRepositoryProvider), _teacher()),
        ),
      ],
    );
    addTearDown(container.dispose);

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

    router.go('/teacher');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.byType(TeacherShell), findsOneWidget);
    expect(find.text('Mes cours'), findsWidgets);

    router.go('/teacher-dashboard');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);

    router.go('/teacher-publish');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);

    router.push('/teacher-course');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(find.text('Publier un cours'), findsWidgets);
  });
}
