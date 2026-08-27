import 'package:akadex/core/router/app_router.dart';
import 'package:akadex/core/theme/akadex_theme.dart';
import 'package:akadex/data/api/api_client.dart';
import 'package:akadex/data/auth/auth_repository.dart';
import 'package:akadex/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:akadex/features/auth/presentation/screens/login_screen.dart';
import 'package:akadex/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuth extends AuthController {
  _FakeAuth(super.repo) {
    state = const AsyncValue.data(null);
  }

  @override
  Future<void> restore() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Mot de passe oublié : login → forgot → reset', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authStateProvider.overrideWith(
          (ref) => _FakeAuth(ref.watch(authRepositoryProvider)),
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
    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.tap(find.text('Mot de passe oublié ?'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/forgot-password');

    router.go('/reset-password?email=isra%40unikin.ac.cd&dev_code=123456');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ResetPasswordScreen), findsOneWidget);
    expect(find.text('123456'), findsWidgets);
  });
}
