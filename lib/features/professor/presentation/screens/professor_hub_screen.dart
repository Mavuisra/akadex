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
                        'Gère tes cours, publie modules et leçons — sans interface étudiant.',
                    ctaLabel: 'Publier une leçon',
                    onCta: () => context.go('/teacher-publish'),
                    trailing: const Icon(
                      Icons.school_rounded,
                      color: Colors.white70,
                      size: 48,
                    ),
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
                        child: Text(
                          'Aucun cours associé pour l’instant. '
                          'Publie une leçon pour démarrer.',
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.65),
                          ),
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
    final byName = courses
        .where((c) => c.teacher.toLowerCase().contains(name.split(' ').first))
        .toList();
    if (byName.isNotEmpty) return byName.take(40).toList();
    return courses.take(40).toList();
  }
}
