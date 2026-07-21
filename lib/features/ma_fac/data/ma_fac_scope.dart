import '../../../../domain/models/models.dart';

/// Filtrage des cours selon le profil académique connecté.
abstract final class MaFacScope {
  static bool courseMatchesUser(Course c, UserProfile me) {
    final fac = me.faculty.trim().toLowerCase();
    final dept = me.department.trim().toLowerCase();
    final promo = me.promotion.trim().toLowerCase();
    final level = me.level.trim().toLowerCase();
    final hay = [
      c.faculty,
      c.department,
      c.targetPromotion,
      c.semester,
      c.university,
      c.title,
    ].join(' ').toLowerCase();

    var score = 0;
    if (dept.isNotEmpty && hay.contains(dept.split(' ').first)) score += 3;
    if (fac.isNotEmpty && hay.contains(fac.split(' ').first)) score += 2;
    if (level.isNotEmpty &&
        (c.semester.toLowerCase().contains(level) ||
            c.targetPromotion.toLowerCase().contains(level) ||
            hay.contains(level))) {
      score += 2;
    }
    if (promo.isNotEmpty && hay.contains(promo.split(' ').first)) score += 1;
    if (score > 0) return true;

    if (me.facultyId.isNotEmpty && c.faculty.isNotEmpty) {
      return hay.contains(fac) || (dept.isNotEmpty && hay.contains(dept));
    }
    return false;
  }

  static List<Course> filterCourses(List<Course> all, UserProfile? me) {
    if (me == null) return all.take(12).toList();
    final matched = all.where((c) => courseMatchesUser(c, me)).toList();
    if (matched.isNotEmpty) {
      matched.sort((a, b) {
        final af = a.code.startsWith('AKX-') ? 0 : 1;
        final bf = b.code.startsWith('AKX-') ? 0 : 1;
        return af.compareTo(bf);
      });
      return matched;
    }
    final uni = me.university.trim().toLowerCase();
    if (uni.isNotEmpty) {
      final byUni = all
          .where(
            (c) => c.university.toLowerCase().contains(uni.split(' ').first),
          )
          .toList();
      if (byUni.isNotEmpty) return byUni.take(20).toList();
    }
    return all.where((c) => c.code.startsWith('AKX-')).take(8).toList();
  }
}
