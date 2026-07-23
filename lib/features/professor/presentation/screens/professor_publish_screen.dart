import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/auth/auth_repository.dart';

/// Onglet Publier — lance la création de cours (plus de formulaire leçon séparé).
class ProfessorPublishScreen extends ConsumerWidget {
  const ProfessorPublishScreen({super.key});

  static const _fbBg = Color(0xFFF0F2F5);
  static const _fbInk = Color(0xFF050505);
  static const _fbMuted = Color(0xFF65676B);
  static const _fbBorder = Color(0xFFCED0D4);
  static const _fbBlue = Color(0xFF0866FF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      backgroundColor: _fbBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Publier',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: _fbInk,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _fbBorder),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          const SizedBox(height: 8),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFE7F3FF),
                      child: Text(
                        (user?.name.isNotEmpty == true)
                            ? user!.name[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _fbBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        user?.name ?? 'Enseignant',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: _fbInk,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Crée un cours avec ses modules, leçons et vidéos.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.35,
                    color: _fbMuted,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/teacher-course'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Publier un cours'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _fbBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.white,
            child: InkWell(
              onTap: () => context.go('/teacher'),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.menu_book_outlined, color: _fbBlue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gérer mes cours',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _fbInk,
                            ),
                          ),
                          Text(
                            'Voir les stats, modifier, ajouter des leçons',
                            style: TextStyle(fontSize: 13, color: _fbMuted),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: _fbMuted),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
