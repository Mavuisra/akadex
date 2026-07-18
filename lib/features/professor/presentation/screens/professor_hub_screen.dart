import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/repositories/repositories.dart';

class ProfessorHubScreen extends ConsumerWidget {
  const ProfessorHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final coursesAsync = ref.watch(coursesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Espace Professeurs')),
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
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.isTeacher
                          ? 'Diffuse tes enseignements'
                          : 'Cours des professeurs',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Vidéos, PDF, syllabus, TP, TD, examens et corrigés — '
                      'associés à une université, faculté, département, niveau et matière.',
                      style: TextStyle(
                        height: 1.4,
                        color: Colors.black.withValues(alpha: 0.65),
                      ),
                    ),
                    if (user.isTeacher) ...[
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () => context.push('/professor/publish'),
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Publier une leçon'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SectionTitle('Cours'),
              const SizedBox(height: 8),
              coursesAsync.when(
                loading: () => const CupertinoActivityIndicator(),
                error: (e, _) => Text(apiErrorMessage(e)),
                data: (courses) {
                  final list = courses.take(40).toList();
                  return Column(
                    children: [
                      for (final c in list) ...[
                        SoftCard(
                          onTap: () => context.push('/library/course/${c.id}'),
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
                                  Icons.play_circle_outline,
                                  color: AkadexColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${c.code} · ${c.semester} · Prof. ${c.teacher}',
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
          );
        },
      ),
    );
  }
}
