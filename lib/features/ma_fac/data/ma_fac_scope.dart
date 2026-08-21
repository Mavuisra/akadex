import '../../../../domain/models/models.dart';

/// Filtrage des cours Ma Fac (programme / contributions de promo).
///
/// Ma Fac ≠ Apprendre :
/// - Apprendre = `AKX-*` (plateforme) + `ENS-*` (enseignants)
/// - Ma Fac = uniquement le reste (ex. `PROP-*`, UE de promo)
abstract final class MaFacScope {
  /// Cours réservés au catalogue Apprendre — exclus de Ma Fac.
  static bool isLearnCatalog(Course c) {
    final code = c.code.trim().toUpperCase();
    return code.startsWith('AKX-') || code.startsWith('ENS-');
  }

  static bool isMaFacCourse(Course c) => !isLearnCatalog(c);

  static bool courseMatchesUser(Course c, UserProfile me) {
    if (!isMaFacCourse(c)) return false;

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

  /// Filtre promo (UE de programme uniquement).
  static List<Course> applyPromotionFilter(
    List<Course> scoped, {
    required String level,
    required String name,
  }) {
    final lvl = level.toLowerCase().trim();
    final pname = name.toLowerCase().trim();
    if (lvl.isEmpty && pname.isEmpty) return scoped;
    final matched = scoped.where((c) {
      final h =
          '${c.semester} ${c.targetPromotion} ${c.levelLabel}'.toLowerCase();
      return (lvl.isNotEmpty && h.contains(lvl)) ||
          (pname.isNotEmpty && h.contains(pname.split(' ').first));
    }).toList();
    return matched.isNotEmpty ? matched : scoped;
  }

  static List<Course> filterCourses(List<Course> all, UserProfile? me) {
    final catalogue = all.where(isMaFacCourse).toList();
    if (me == null) return catalogue.take(12).toList();
    final matched =
        catalogue.where((c) => courseMatchesUser(c, me)).toList();
    if (matched.isNotEmpty) return matched;
    final uni = me.university.trim().toLowerCase();
    if (uni.isNotEmpty) {
      final byUni = catalogue
          .where(
            (c) => c.university.toLowerCase().contains(uni.split(' ').first),
          )
          .toList();
      if (byUni.isNotEmpty) return byUni.take(20).toList();
    }
    return const [];
  }
}
