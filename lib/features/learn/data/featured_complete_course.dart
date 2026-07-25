import '../../../domain/models/models.dart';

/// Cours vitrine complet affiché sur Apprendre (toutes les infos pédagogiques).
abstract final class FeaturedCompleteCourse {
  static const id = 'akx-featured-ia101';

  static const course = Course(
    id: id,
    title: 'Fondamentaux de l’Intelligence Artificielle',
    code: 'AKX-IA101',
    teacher: 'Jean-Pierre Mukendi',
    teacherTitle: 'Professeur',
    teacherFullName: 'Jean-Pierre Mukendi Kalala',
    teacherHeadline: 'Professeur',
    teacherBio:
        'Professeur Jean-Pierre Mukendi Kalala enseigne l’informatique à '
        'l’Université de Kinshasa depuis 12 ans. Chercheur en vision par '
        'ordinateur appliquée à l’agriculture urbaine, il a formé plus de '
        '2 000 étudiants en RDC et anime des ateliers IA pour le secteur public.',
    teacherSpecialty: 'Spécialiste en Intelligence Artificielle',
    teacherAvatarUrl:
        'https://images.unsplash.com/photo-1531384441138-2736e62e0919?w=400&q=80',
    teacherUniversity: 'Université de Kinshasa',
    semester: 'L2',
    promotion: 'L2',
    credits: 6,
    department: 'Informatique',
    description:
        'Ce cours introduit les concepts essentiels de l’intelligence '
        'artificielle pour les étudiants africains : historique, apprentissage '
        'automatique, réseaux de neurones et cas d’usage (santé, agriculture, '
        'éducation). Vous construisez une culture IA solide avant de passer '
        'aux spécialisations.',
    objectives:
        'Comprendre ce qu’est l’IA et ses limites.\n'
        'Distinguer apprentissage supervisé, non supervisé et par renforcement.\n'
        'Expliquer le fonctionnement d’un réseau de neurones simple.\n'
        'Identifier des applications IA pertinentes pour l’Afrique.',
    skills:
        'Vocabulaire IA et machine learning\n'
        'Lecture de modèles simples\n'
        'Éthique et biais algorithmiques\n'
        'Présentation d’un cas d’usage local',
    prerequisites:
        'Notions de mathématiques du secondaire et curiosité scientifique.',
    university: 'Université de Kinshasa',
    faculty: 'Faculté des Sciences',
    documentCount: 12,
    coverUrl:
        'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=1200&q=80',
    levelLabel: 'Débutant',
    estimatedHours: 28,
    domainSlugs: ['informatique'],
    domainNames: ['Informatique'],
  );

  static const learningOutcomes =
      'À la fin, vous pourrez expliquer l’IA à un public non technique '
      'et proposer un projet d’application locale.';

  static const modules = <FeaturedModule>[
    FeaturedModule(
      title: 'Module 1 — Qu’est-ce que l’IA ?',
      description: 'Définitions, histoire et enjeux contemporains.',
      lessons: [
        'L’IA expliquée simplement (vidéo)',
        'Machine Learning en 10 minutes (vidéo)',
        'Quiz — Concepts de base',
      ],
    ),
    FeaturedModule(
      title: 'Module 2 — Données et apprentissage',
      description: 'Données, features et entraînement.',
      lessons: [
        'Données pour le ML (vidéo)',
        'Exercice — Jeu de données local',
        'Lecture PDF — Glossaire IA',
      ],
    ),
    FeaturedModule(
      title: 'Module 3 — Réseaux de neurones',
      description: 'Intuition et architecture.',
      lessons: [
        'Neural Networks — introduction visuelle',
        'TP — Dessiner un réseau',
      ],
    ),
    FeaturedModule(
      title: 'Module 4 — IA pour l’Afrique',
      description: 'Cas d’usage santé, agro, éducation.',
      lessons: [
        'Cas d’usage continentaux',
        'Projet — Pitch d’une solution IA',
      ],
    ),
  ];

  /// Préfère le vrai cours API (même code) s’il existe, sinon le vitrine local.
  static Course resolve(List<Course> fromApi) {
    for (final c in fromApi) {
      if (c.code == course.code) return c;
    }
    return course;
  }
}

class FeaturedModule {
  const FeaturedModule({
    required this.title,
    required this.description,
    required this.lessons,
  });

  final String title;
  final String description;
  final List<String> lessons;
}
