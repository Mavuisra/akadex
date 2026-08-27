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
    ),
    MaFacCategory(
      id: 'resumes',
      label: 'Résumés',
      icon: Icons.notes_rounded,
      colors: [Color(0xFF00897B), Color(0xFF004D40)],
      types: [DocumentType.resume, DocumentType.ficheRevision, DocumentType.supportCours],
    ),
    MaFacCategory(
      id: 'tp',
      label: 'TP / TD',
      icon: Icons.science_outlined,
      colors: [Color(0xFFEF6C00), Color(0xFFE65100)],
      types: [DocumentType.tp],
    ),
    MaFacCategory(
      id: 'tfc',
      label: 'TFC',
      icon: Icons.school_outlined,
      colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
      types: [DocumentType.tfc],
    ),
    MaFacCategory(
      id: 'projets',
      label: 'Projets',
      icon: Icons.handyman_outlined,
      colors: [Color(0xFF455A64), Color(0xFF263238)],
      types: [DocumentType.projet, DocumentType.projetTutore],
    ),
    MaFacCategory(
      id: 'rapport-stage',
      label: 'Rapport de stage',
      icon: Icons.work_outline_rounded,
      colors: [Color(0xFF0277BD), Color(0xFF01579B)],
      types: [DocumentType.rapport],
    ),
    MaFacCategory(
      id: 'memoires',
      label: 'Mémoires',
      icon: Icons.menu_book_rounded,
      colors: [Color(0xFF5D4037), Color(0xFF3E2723)],
      types: [DocumentType.memoire, DocumentType.these],
    ),
    MaFacCategory(
      id: 'autres',
      label: 'Autres',
      icon: Icons.folder_special_outlined,
      colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
      types: [DocumentType.autre, DocumentType.article, DocumentType.tutoriel, DocumentType.livre],
    ),
  ];

  static MaFacCategory? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }
}
