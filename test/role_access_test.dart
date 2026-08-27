import 'package:akadex/core/auth/role_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoleAccess.homeForRole', () {
    test('enseignant et admin → /teacher', () {
      expect(RoleAccess.homeForRole('teacher'), '/teacher');
      expect(RoleAccess.homeForRole('admin'), '/teacher');
    });

    test('étudiant et alumni → /home', () {
      expect(RoleAccess.homeForRole('student'), '/home');
      expect(RoleAccess.homeForRole('alumni'), '/home');
      expect(RoleAccess.homeForRole(null), '/home');
    });
  });

  group('RoleAccess.canAccess — invité', () {
    test('autorise login / register / forgot / reset / CGU', () {
      expect(RoleAccess.canAccess(role: null, location: '/login'), isTrue);
      expect(RoleAccess.canAccess(role: null, location: '/register'), isTrue);
      expect(
        RoleAccess.canAccess(role: null, location: '/forgot-password'),
        isTrue,
      );
      expect(
        RoleAccess.canAccess(role: null, location: '/reset-password'),
        isTrue,
      );
      expect(
        RoleAccess.canAccess(
          role: null,
          location: '/reset-password?email=a%40b.com',
        ),
        isTrue,
      );
      expect(
        RoleAccess.canAccess(role: null, location: '/profile/terms'),
        isTrue,
      );
      expect(
        RoleAccess.canAccess(role: null, location: '/profile/privacy'),
        isTrue,
      );
    });

    test('interdit le campus et le shell enseignant', () {
      for (final loc in [
        '/home',
        '/learn',
        '/community',
        '/alumni',
        '/profile',
        '/messages',
        '/ma-fac',
        '/cart',
        '/teacher',
        '/library/course/1',
      ]) {
        expect(
          RoleAccess.canAccess(role: null, location: loc),
          isFalse,
          reason: loc,
        );
        expect(
          RoleAccess.canAccess(role: '', location: loc),
          isFalse,
          reason: loc,
        );
      }
    });
  });

  group('RoleAccess.canAccess — enseignant', () {
    const role = 'teacher';

    test('interdit le campus étudiant', () {
      for (final loc in [
        '/home',
        '/learn',
        '/community',
        '/alumni',
        '/alumni/publish',
        '/rewards',
        '/library',
      ]) {
        expect(
          RoleAccess.canAccess(role: role, location: loc),
          isFalse,
          reason: loc,
        );
      }
    });

    test('autorise le shell enseignant et le détail cours', () {
      for (final loc in [
        '/teacher',
        '/teacher-publish',
        '/teacher-calendar',
        '/teacher-profile',
        '/library/course/12',
        '/library/lesson/3',
        '/login',
      ]) {
        expect(
          RoleAccess.canAccess(role: role, location: loc),
          isTrue,
          reason: loc,
        );
      }
    });
  });

  group('RoleAccess.canAccess — étudiant', () {
    const role = 'student';

    test('interdit les routes enseignant', () {
      for (final loc in [
        '/teacher',
        '/teacher-publish',
        '/teacher-calendar',
        '/teacher-profile',
        '/professor',
        '/professor/publish',
      ]) {
        expect(
          RoleAccess.canAccess(role: role, location: loc),
          isFalse,
          reason: loc,
        );
      }
    });

    test('autorise le campus étudiant', () {
      for (final loc in [
        '/home',
        '/learn',
        '/library',
        '/community',
        '/alumni',
        '/profile',
        '/rewards',
      ]) {
        expect(
          RoleAccess.canAccess(role: role, location: loc),
          isTrue,
          reason: loc,
        );
      }
    });
  });

  group('RoleAccess.redirectForDenied', () {
    test('invité → /login', () {
      expect(
        RoleAccess.redirectForDenied(role: null, location: '/home'),
        '/login',
      );
    });

    test('renvoie vers le bon shell', () {
      expect(
        RoleAccess.redirectForDenied(role: 'teacher', location: '/home'),
        '/teacher',
      );
      expect(
        RoleAccess.redirectForDenied(role: 'student', location: '/teacher'),
        '/home',
      );
    });
  });
}
