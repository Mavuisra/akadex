import 'package:flutter/material.dart';

import '../../../../domain/models/models.dart';

/// Domaine académique affiché en « story » sur Apprendre.
///
/// Catalogue Apprendre = vitrine plateforme (`AKX-*`) + cours publiés par
/// les enseignants (`ENS-*`). Ma Fac (programme / contributions promo) est
/// un autre catalogue — jamais mélangé ici.
class LearnDomain {
  const LearnDomain({
    required this.id,
    required this.name,
    required this.shortLabel,
    required this.icon,
    required this.colors,
    required this.keywords,
  });

  final String id;
  final String name;
  final String shortLabel;
  final IconData icon;
  final List<Color> colors;
  final List<String> keywords;

  /// Vrai si le cours relève de ce domaine (M2M ou keywords).
  bool matchesDomain(Course course) {
    if (course.domainSlugs.contains(id)) return true;
    final hay = [
      course.faculty,
      course.department,
      course.title,
      course.code,
      course.university,
      ...course.domainNames,
    ].join(' ').toLowerCase();
    return keywords.any((k) => hay.contains(k.toLowerCase()));
  }

  bool matches(Course course) => matchesDomain(course);
}

abstract final class LearnDomains {
  static const vitrinePrefix = 'AKX-';
  static const teacherPrefix = 'ENS-';

  /// Catalogue Apprendre : plateforme + publications enseignant.
  static bool isLearnCatalog(Course course) {
    final c = course.code.trim().toUpperCase();
    return c.startsWith(vitrinePrefix) || c.startsWith(teacherPrefix);
  }

  /// Alias historique (écrans Apprendre).
  static bool isVitrine(Course course) => isLearnCatalog(course);

  static const all = <LearnDomain>[
    LearnDomain(
      id: 'informatique',
      name: 'Informatique',
      shortLabel: 'Info',
      icon: Icons.computer_rounded,
      colors: [Color(0xFF1877F2), Color(0xFF0A4DA6)],
      keywords: [
        'informatique',
        'fasi',
        'génie logiciel',
        'info',
        'digital',
        'python',
        'ia',
        'intelligence artificielle',
      ],
    ),
    LearnDomain(
      id: 'droit',
      name: 'Droit',
      shortLabel: 'Droit',
      icon: Icons.gavel_rounded,
      colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
      keywords: ['droit', 'juridique', 'loi'],
    ),
    LearnDomain(
      id: 'medecine',
      name: 'Médecine',
      shortLabel: 'Méd.',
      icon: Icons.medical_services_outlined,
      colors: [Color(0xFF00897B), Color(0xFF004D40)],
      keywords: ['médecine', 'medecine', 'santé', 'sante', 'pharmacie'],
    ),
    LearnDomain(
      id: 'economie',
      name: 'Économie & Gestion',
      shortLabel: 'Éco',
      icon: Icons.trending_up_rounded,
      colors: [Color(0xFFEF6C00), Color(0xFFE65100)],
      keywords: ['économie', 'economie', 'gestion', 'commerce', 'finance'],
    ),
    LearnDomain(
      id: 'comptabilite',
      name: 'Comptabilité',
      shortLabel: 'Compta',
      icon: Icons.calculate_outlined,
      colors: [Color(0xFF00838F), Color(0xFF006064)],
      keywords: ['comptabilité', 'comptabilite', 'ohada', 'audit', 'fiscal'],
    ),
    LearnDomain(
      id: 'marketing',
      name: 'Marketing',
      shortLabel: 'Mktg',
      icon: Icons.campaign_outlined,
      colors: [Color(0xFFC2185B), Color(0xFF880E4F)],
      keywords: ['marketing', 'vente', 'communication commerciale'],
    ),
    LearnDomain(
      id: 'sciences',
      name: 'Sciences',
      shortLabel: 'Sci.',
      icon: Icons.science_outlined,
      colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
      keywords: ['science', 'physique', 'chimie', 'math', 'biologie'],
    ),
    LearnDomain(
      id: 'lettres',
      name: 'Lettres & SHS',
      shortLabel: 'Lettres',
      icon: Icons.menu_book_rounded,
      colors: [Color(0xFF5D4037), Color(0xFF3E2723)],
      keywords: [
        'lettre',
        'langue',
        'histoire',
        'socio',
        'psycho',
        'communication',
      ],
    ),
    LearnDomain(
      id: 'ingenierie',
      name: 'Ingénierie',
      shortLabel: 'Ingé.',
      icon: Icons.engineering_rounded,
      colors: [Color(0xFF455A64), Color(0xFF263238)],
      keywords: [
        'ingénieur',
        'ingenieur',
        'polytech',
        'civil',
        'électri',
        'electri',
      ],
    ),
    LearnDomain(
      id: 'agronomie',
      name: 'Agronomie',
      shortLabel: 'Agro',
      icon: Icons.eco_outlined,
      colors: [Color(0xFF7CB342), Color(0xFF33691E)],
      keywords: ['agro', 'agronomie', 'vétérinaire', 'veterinaire'],
    ),
  ];

  static LearnDomain? byId(String id) {
    for (final d in all) {
      if (d.id == id) return d;
    }
    return null;
  }

  static String? resolveDomainSlug(Course course) {
    if (course.primaryDomainSlug.isNotEmpty) return course.primaryDomainSlug;
    for (final d in all) {
      if (d.matchesDomain(course)) return d.id;
    }
    return null;
  }

  static List<Course> filterCourses(List<Course> courses, LearnDomain domain) {
    final matched = courses
        .where((c) => isLearnCatalog(c) && domain.matchesDomain(c))
        .toList();
    matched.sort((a, b) {
      final byDate = b.id.compareTo(a.id);
      if (byDate != 0) return byDate;
      return a.title.compareTo(b.title);
    });
    return matched;
  }

  static List<Course> vitrineCourses(List<Course> courses, {int limit = 3}) {
    final allV = courses.where(isLearnCatalog).toList();
    final withCover = allV.where((c) => c.coverUrl.isNotEmpty).toList();
    final without = allV.where((c) => c.coverUrl.isEmpty).toList();
    return [...withCover, ...without].take(limit).toList();
  }

  static Map<String, int> vitrineCounts(List<Course> courses) {
    final catalog = courses.where(isLearnCatalog);
    return {
      for (final d in all) d.id: catalog.where(d.matchesDomain).length,
    };
  }
}
