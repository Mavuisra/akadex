import 'package:flutter/material.dart';

class DemoDoc {
  const DemoDoc({
    required this.id,
    required this.title,
    required this.meta,
    required this.type,
    this.level = 'L1',
    this.subject = 'Informatique',
    this.downloads = '12.4K',
    this.views = '3.2K',
    this.rating = '4.8',
    this.about =
        'Résumé complet du cours d’algorithmique couvrant les notions fondamentales, structures de données et exercices corrigés.',
    this.tags = const ['Algorithmique', 'Cours', 'Résumé', 'L1'],
  });

  final String id;
  final String title;
  final String meta;
  final String type;
  final String level;
  final String subject;
  final String downloads;
  final String views;
  final String rating;
  final String about;
  final List<String> tags;
}

class DemoCourse {
  const DemoCourse({
    required this.id,
    required this.title,
    required this.meta,
    required this.docs,
    required this.icon,
  });

  final String id;
  final String title;
  final String meta;
  final String docs;
  final IconData icon;
}

class DemoPost {
  const DemoPost({
    required this.author,
    required this.time,
    required this.title,
    required this.body,
    required this.tags,
    required this.likes,
    required this.comments,
  });

  final String author;
  final String time;
  final String title;
  final String body;
  final List<String> tags;
  final String likes;
  final String comments;
}

class DemoEvent {
  const DemoEvent({
    required this.title,
    required this.date,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String title;
  final String date;
  final String time;
  final IconData icon;
  final int color;
}

class DemoUni {
  const DemoUni({
    required this.code,
    required this.name,
    required this.city,
  });

  final String code;
  final String name;
  final String city;
}

class DemoCategory {
  const DemoCategory({
    required this.name,
    required this.docs,
    required this.icon,
    required this.color,
  });

  final String name;
  final String docs;
  final IconData icon;
  final int color;
}

abstract final class MockData {
  static const docs = [
    DemoDoc(
      id: 'd1',
      title: 'Algorithmique - Cours complet',
      meta: 'L1 - Informatique',
      type: 'PDF',
    ),
    DemoDoc(
      id: 'd2',
      title: 'Examen S1 - 2023',
      meta: 'L2 - Mathématiques',
      type: 'PDF',
      tags: ['Examens', 'Mathématiques', 'L2'],
    ),
    DemoDoc(
      id: 'd3',
      title: 'TP Réseaux - Corrigé',
      meta: 'L3 - Réseaux',
      type: 'DOC',
      tags: ['TP', 'Réseaux', 'Corrigé', 'L3'],
    ),
  ];

  static const courses = [
    DemoCourse(
      id: 'c1',
      title: 'Algorithmique',
      meta: 'L1 • Semestre 1',
      docs: '152 documents',
      icon: Icons.account_tree_outlined,
    ),
    DemoCourse(
      id: 'c2',
      title: 'Structure de données',
      meta: 'L1 • Semestre 1',
      docs: '98 documents',
      icon: Icons.hub_outlined,
    ),
    DemoCourse(
      id: 'c3',
      title: 'Bases de données',
      meta: 'L2 • Semestre 1',
      docs: '124 documents',
      icon: Icons.storage_outlined,
    ),
    DemoCourse(
      id: 'c4',
      title: 'Réseaux informatiques',
      meta: 'L2 • Semestre 2',
      docs: '87 documents',
      icon: Icons.wifi_tethering_rounded,
    ),
    DemoCourse(
      id: 'c5',
      title: 'Programmation Orientée Objet',
      meta: 'L2 • Semestre 1',
      docs: '110 documents',
      icon: Icons.code_rounded,
    ),
  ];

  static const posts = [
    DemoPost(
      author: 'Grace Ndaya',
      time: 'il y a 2 h',
      title: 'Comment résoudre une équation différentielle ?',
      body:
          'Quelqu’un peut m’expliquer la méthode de séparation des variables avec un exemple simple ?',
      tags: ['Mathématiques', 'L2'],
      likes: '48',
      comments: '12',
    ),
    DemoPost(
      author: 'Jean Kalala',
      time: 'il y a 5 h',
      title: 'Annales INF301 disponibles ?',
      body:
          'Je cherche les examens 2022 et 2023 avec corrigés pour préparer la session.',
      tags: ['Informatique', 'Examens'],
      likes: '31',
      comments: '9',
    ),
    DemoPost(
      author: 'Club Dev UNIKIN',
      time: 'hier',
      title: 'Hackathon campus — inscriptions ouvertes',
      body:
          '48h pour prototyper une solution étudiante. Thème : accès aux ressources.',
      tags: ['Événement', 'Clubs'],
      likes: '92',
      comments: '34',
    ),
  ];

  static const events = [
    DemoEvent(
      title: 'Examen d’Algorithmique',
      date: '16 Mai',
      time: '08:00',
      icon: Icons.assignment_outlined,
      color: 0xFF1A47B8,
    ),
    DemoEvent(
      title: 'Délibération Semestre 2',
      date: '28 Mai',
      time: '10:00',
      icon: Icons.gavel_rounded,
      color: 0xFFF59E0B,
    ),
    DemoEvent(
      title: 'Conférence IA & Avenir',
      date: '02 Juin',
      time: '14:00',
      icon: Icons.mic_none_rounded,
      color: 0xFF16A34A,
    ),
  ];

  static const universities = [
    DemoUni(code: 'UPN', name: 'UPN', city: 'Kinshasa'),
    DemoUni(code: 'UNIKIN', name: 'UNIKIN', city: 'Kinshasa'),
    DemoUni(code: 'ISP', name: 'ISP', city: 'Gombe'),
    DemoUni(code: 'UL', name: 'UL', city: 'Lubumbashi'),
  ];

  static const categories = [
    DemoCategory(
      name: 'Informatique',
      docs: '12.4K docs',
      icon: Icons.computer_rounded,
      color: 0xFF1A47B8,
    ),
    DemoCategory(
      name: 'Sciences Économiques',
      docs: '8.7K docs',
      icon: Icons.trending_up_rounded,
      color: 0xFF0D9488,
    ),
    DemoCategory(
      name: 'Droit',
      docs: '7.8K docs',
      icon: Icons.balance_rounded,
      color: 0xFF7C3AED,
    ),
    DemoCategory(
      name: 'Médecine',
      docs: '5.3K docs',
      icon: Icons.medical_services_outlined,
      color: 0xFFDC2626,
    ),
    DemoCategory(
      name: 'Sciences et Technologies',
      docs: '10.2K docs',
      icon: Icons.science_outlined,
      color: 0xFFEA580C,
    ),
  ];
}
