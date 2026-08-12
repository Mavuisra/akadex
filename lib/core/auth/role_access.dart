import '../../domain/models/models.dart';

/// Source unique : quelles routes chaque rôle peut ouvrir.
abstract final class RoleAccess {
  /// Préfixes / chemins réservés au campus étudiant (interdit aux enseignants).
  static const studentOnlyPrefixes = <String>[
    '/home',
    '/learn',
    '/community',
    '/alumni',
    '/rewards',
    '/dashboard',
    '/friends',
    '/saved',
    '/peer-review',
  ];

  static bool usesTeacherShell(String? role) {
    return role == 'teacher' || role == 'admin';
  }

  static bool usesStudentShell(String? role) {
    if (role == null || role.isEmpty) return true;
    return !usesTeacherShell(role);
  }

  static String homeForRole(String? role) {
    return usesTeacherShell(role) ? '/teacher' : '/home';
  }

  static bool isPublicLocation(String location) {
    return location == '/login' ||
        location == '/register';
  }

  /// Liste bibliothèque = étudiant only ; détail cours/doc/leçon = partagé.
  static bool isStudentLibraryList(String location) {
    return location == '/library' || location.startsWith('/library?');
  }

  static bool isTeacherLocation(String location) {
    return location == '/teacher' ||
        location.startsWith('/teacher/') ||
        location.startsWith('/teacher-') ||
        location == '/professor' ||
        location.startsWith('/professor/');
  }

  static bool canAccess({
    required String? role,
    required String location,
  }) {
    if (isPublicLocation(location)) return true;

    if (usesTeacherShell(role)) {
      for (final p in studentOnlyPrefixes) {
        if (location == p || location.startsWith('$p/')) return false;
      }
      if (isStudentLibraryList(location)) return false;
      return true;
    }

    // Étudiant / alumni
    if (isTeacherLocation(location)) return false;
    return true;
  }

  static String redirectForDenied({
    required String? role,
    required String location,
  }) {
    if (usesTeacherShell(role)) return '/teacher';
    return '/home';
  }
}

extension UserProfileRoleAccess on UserProfile {
  bool get isStudentRole => role == 'student';
  bool get isStaffTeacher => role == 'teacher' || role == 'admin';
  bool get usesTeacherShellFlag => RoleAccess.usesTeacherShell(role);
  bool get usesStudentShellFlag => RoleAccess.usesStudentShell(role);
  String get homeRoutePath => RoleAccess.homeForRole(role);
}
