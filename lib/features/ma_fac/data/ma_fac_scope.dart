import '../../../../domain/models/models.dart';

/// Filtrage des cours Ma Fac (programme / contributions de promo).
///
/// Indépendant d’Apprendre : les codes `AKX-*` sont la vitrine vidéo et
/// n’apparaissent jamais ici. Le pont vers Apprendre se fait via le domaine
/// ([LearnDomains.resolveDomainSlug]), pas en fusionnant les catalogues.
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
    // Les AKX-* sont la vitrine « Apprendre », pas le programme de promotion.
    final catalogue = all.where((c) => !c.code.startsWith('AKX-')).toList();
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
