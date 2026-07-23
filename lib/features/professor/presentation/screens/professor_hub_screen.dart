import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/living_ui.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/models.dart';

class ProfessorHubScreen extends ConsumerWidget {
  const ProfessorHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final coursesAsync = ref.watch(coursesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: auth.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(child: Text(apiErrorMessage(e))),
        data: (user) {
          if (user == null) {
            return Center(
              child: FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Se connecter'),
              ),
            );
          }
          if (!user.usesTeacherShell) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Espace réservé aux enseignants.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                FadeSlideIn(
                  child: LivingHeroBanner(
                    title: 'Espace enseignant',
                    subtitle:
                        'Crée ton cours (tous les champs), puis ajoute modules et leçons.',
                    ctaLabel: 'Publier un cours',
                    onCta: () => context.push('/teacher-course'),
                    trailing: const Icon(
                      Icons.school_rounded,
                      color: Colors.white70,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SoftCard(
                  onTap: () => context.push('/teacher-publish'),
                  child: const Row(
                    children: [
                      Icon(Icons.playlist_add_rounded,
                          color: AkadexColors.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Publier une leçon',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Modules et contenus sur un cours déjà créé',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AkadexColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: Text(
                    'Bonjour ${user.name.split(' ').first}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (user.department.isNotEmpty) user.department,
                    if (user.university.isNotEmpty) user.university,
                  ].join(' · '),
                  style: const TextStyle(color: AkadexColors.inkMuted),
                ),
                const SizedBox(height: 20),
                const SectionTitle('Tes cours'),
                const SizedBox(height: 8),
                coursesAsync.when(
                  loading: () => const CupertinoActivityIndicator(),
                  error: (e, _) => Text(apiErrorMessage(e)),
                  data: (courses) {
                    final mine = _teacherCourses(courses, user);
                    if (mine.isEmpty) {
                      return SoftCard(
                        onTap: () => context.push('/teacher-course'),
                        child: const Text(
                          'Aucun cours pour l’instant.\n'
                          'Publie ton premier cours pour démarrer.',
                          style: TextStyle(color: AkadexColors.inkMuted),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final c in mine) ...[
                          SoftCard(
                            onTap: () =>
                                context.push('/library/course/${c.id}'),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AkadexColors.primarySoft,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.menu_book_rounded,
                                    color: AkadexColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '${c.code} · ${c.semester}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AkadexColors.inkMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Course> _teacherCourses(List<Course> courses, UserProfile user) {
    final name = user.name.toLowerCase();
    final first = name.split(' ').where((p) => p.isNotEmpty).firstOrNull ?? '';
    final mine = courses.where((c) {
      final hay = [
        c.teacher,
        c.displayTeacher,
        c.teacherFullName,
        c.submittedByName,
      ].join(' ').toLowerCase();
      if (first.isNotEmpty && hay.contains(first)) return true;
      // Cours publiés par ce compte (titulaire / contributeur).
      if (c.code.startsWith('ENS-')) return true;
      return false;
    }).toList();
    if (mine.isNotEmpty) return mine.take(40).toList();
    // Fallback : hors vitrine AKX.
    return courses
        .where((c) => !c.code.startsWith('AKX-'))
        .take(40)
        .toList();
  }
}
