import 'package:flutter/material.dart';

import '../../../../domain/models/models.dart';

/// Domaine académique affiché en « story » sur Apprendre.
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

  bool matches(Course course) {
    final hay = [
      course.faculty,
      course.department,
      course.title,
      course.code,
      course.university,
    ].join(' ').toLowerCase();
    return keywords.any((k) => hay.contains(k.toLowerCase()));
  }
}

abstract final class LearnDomains {
  static const all = <LearnDomain>[
    LearnDomain(
      id: 'informatique',
      name: 'Informatique',
      shortLabel: 'Info',
      icon: Icons.computer_rounded,
      colors: [Color(0xFF1877F2), Color(0xFF0A4DA6)],
      keywords: ['informatique', 'fasi', 'génie logiciel', 'info', 'digital'],
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
      keywords: ['lettre', 'langue', 'histoire', 'socio', 'psycho', 'communication'],
    ),
    LearnDomain(
      id: 'ingenierie',
      name: 'Ingénierie',
      shortLabel: 'Ingé.',
      icon: Icons.engineering_rounded,
      colors: [Color(0xFF455A64), Color(0xFF263238)],
      keywords: ['ingénieur', 'ingenieur', 'polytech', 'civil', 'électri', 'electri'],
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

  static List<Course> filterCourses(List<Course> courses, LearnDomain domain) {
    final matched = courses.where(domain.matches).toList();
    if (matched.isEmpty) {
      return courses.where((c) => c.code.startsWith('AKX-')).take(12).toList();
    }
    matched.sort((a, b) {
      final af = a.code.startsWith('AKX-') ? 0 : 1;
      final bf = b.code.startsWith('AKX-') ? 0 : 1;
      return af.compareTo(bf);
    });
    return matched;
  }
}
