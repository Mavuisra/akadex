import 'package:flutter/material.dart';

import '../../../domain/models/document_type.dart';

/// Catégorie de ressources « Ma Fac » (stories horizontales).
class MaFacCategory {
  const MaFacCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.colors,
    required this.types,
    this.photoUrl = '',
  });

  final String id;
  final String label;
  final IconData icon;
  final List<Color> colors;
  final List<DocumentType> types;
  final String photoUrl;

  bool matches(DocumentType type) => types.contains(type);
}

abstract final class MaFacCategories {
  static const all = <MaFacCategory>[
    MaFacCategory(
      id: 'examens',
      label: 'Examens',
      icon: Icons.quiz_outlined,
      colors: [Color(0xFF1A47B8), Color(0xFF0F2F7A)],
      types: [DocumentType.examen, DocumentType.corrige, DocumentType.interrogation],
      photoUrl:
          'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=600&q=80',
    ),
    MaFacCategory(
      id: 'resumes',
      label: 'Résumés',
      icon: Icons.notes_rounded,
      colors: [Color(0xFF00897B), Color(0xFF004D40)],
      types: [DocumentType.resume, DocumentType.ficheRevision, DocumentType.supportCours],
      photoUrl:
          'https://images.unsplash.com/photo-1456513080080-7e4c8c1d1e1b?w=600&q=80',
    ),
    MaFacCategory(
      id: 'tp',
      label: 'TP / TD',
      icon: Icons.science_outlined,
      colors: [Color(0xFFEF6C00), Color(0xFFE65100)],
      types: [DocumentType.tp],
      photoUrl:
          'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?w=600&q=80',
    ),
    MaFacCategory(
      id: 'tfc',
      label: 'TFC',
      icon: Icons.school_outlined,
      colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
      types: [DocumentType.tfc],
      photoUrl:
          'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=600&q=80',
    ),
    MaFacCategory(
      id: 'projets',
      label: 'Projets',
      icon: Icons.handyman_outlined,
      colors: [Color(0xFF455A64), Color(0xFF263238)],
      types: [DocumentType.projet, DocumentType.projetTutore],
      photoUrl:
          'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=600&q=80',
    ),
    MaFacCategory(
      id: 'rapport-stage',
      label: 'Rapport de stage',
      icon: Icons.work_outline_rounded,
      colors: [Color(0xFF0277BD), Color(0xFF01579B)],
      types: [DocumentType.rapport],
      photoUrl:
          'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=600&q=80',
    ),
    MaFacCategory(
      id: 'memoires',
      label: 'Mémoires',
      icon: Icons.menu_book_rounded,
      colors: [Color(0xFF5D4037), Color(0xFF3E2723)],
      types: [DocumentType.memoire, DocumentType.these],
      photoUrl:
          'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=600&q=80',
    ),
    MaFacCategory(
      id: 'autres',
      label: 'Autres',
      icon: Icons.folder_special_outlined,
      colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
      types: [DocumentType.autre, DocumentType.article, DocumentType.tutoriel, DocumentType.livre],
      photoUrl:
          'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=600&q=80',
    ),
  ];

  static MaFacCategory? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }
}
