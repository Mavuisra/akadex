import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/theme/timeline_tokens.dart';
import '../../../../core/widgets/moderation_chip.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/models.dart';
import '../../../learn/data/learn_domains.dart';

/// Détail d’un cours universitaire (Ma Fac) — infos renseignées + lien Apprendre.
class MaFacCourseDetailScreen extends ConsumerWidget {
  const MaFacCourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  String? _domainSlug(Course course) =>
      LearnDomains.resolveDomainSlug(course);

  String _domainLabel(Course course, String? slug) {
    if (course.domainNames.isNotEmpty) return course.domainNames.first;
    if (slug == null) return '';
    return LearnDomains.byId(slug)?.name ?? slug;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(courseProvider(courseId));

    return Scaffold(
      backgroundColor: TimelineTokens.of(context).feedBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Détail du cours',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(child: Text(apiErrorMessage(e))),
        data: (course) {
          final domainSlug = _domainSlug(course);
          final domainLabel = _domainLabel(course, domainSlug);
          final teacher = course.displayTeacher;
          final rows = <(String, String)>[
            if (course.code.isNotEmpty) ('Code UE', course.code),
            if (course.university.isNotEmpty) ('Université', course.university),
            if (course.faculty.isNotEmpty) ('Faculté', course.faculty),
            if (course.department.isNotEmpty)
              ('Département', course.department),
            if (course.semester.isNotEmpty) ('Cycle', course.semester),
            if (course.levelLabel.isNotEmpty)
              ('Semestre', course.levelLabel),
            if (course.promotion.isNotEmpty &&
                course.promotion != course.semester)
              ('Promotion', course.promotion),
            if (course.credits > 0)
              ('Crédits UE', '${course.credits}'),
            if (course.estimatedHours > 0)
              ('Volume horaire', '${course.estimatedHours} h'),
            if (teacher.isNotEmpty) ('Titulaire', teacher),
            if (course.domainNames.isNotEmpty)
              ('Domaine(s)', course.domainNames.join(', ')),
            if (course.submittedByName.isNotEmpty)
              ('Proposé par', course.submittedByName),
          ];

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: TimelineTokens.of(context).divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (course.needsModerationBadge) ...[
                            ModerationChip(status: course.moderationStatus),
                            const SizedBox(height: 10),
                          ],
                          Text(
                            course.title,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF050505),
                              height: 1.25,
                            ),
                          ),
                          if (course.moderationNote.isNotEmpty &&
                              course.needsModerationBadge) ...[
                            const SizedBox(height: 10),
                            Text(
                              course.moderationNote,
                              style: TextStyle(
                                color: TimelineTokens.of(context).meta,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: TimelineTokens.of(context).divider),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < rows.length; i++) ...[
                            _InfoRow(label: rows[i].$1, value: rows[i].$2),
                            if (i < rows.length - 1)
                              Divider(
                                height: 1,
                                indent: 12,
                                endIndent: 12,
                                color: TimelineTokens.of(context).divider,
                              ),
                          ],
                        ],
                      ),
                    ),
                    if (course.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _TextBlock(
                        title: 'Description',
                        body: course.description,
                      ),
                    ],
                    if (course.objectives.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _TextBlock(
                        title: 'Objectifs d’apprentissage',
                        body: course.objectives,
                      ),
                    ],
                    if (course.prerequisites.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _TextBlock(
                        title: 'Prérequis',
                        body: course.prerequisites,
                      ),
                    ],
                    if (course.skills.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _TextBlock(
                        title: 'Compétences',
                        body: course.skills,
                      ),
                    ],
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: TimelineTokens.of(context).divider),
                    ),
                  ),
                  child: FilledButton.icon(
                    onPressed: () {
                      if (domainSlug != null && domainSlug.isNotEmpty) {
                        context.push('/learn/domain/$domainSlug');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Aucun domaine associé pour l’instant. '
                              'Il sera défini à la validation admin.',
                            ),
                          ),
                        );
                        context.push('/learn');
                      }
                    },
                    icon: const Icon(Icons.play_circle_outline),
                    label: Text(
                      domainLabel.isNotEmpty
                          ? 'Voir les vidéos — $domainLabel'
                          : 'Voir les vidéos correspondantes',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: AkadexColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: TextStyle(
                color: TimelineTokens.of(context).meta,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF050505),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TimelineTokens.of(context).divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Color(0xFF050505),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Color(0xFF050505),
            ),
          ),
        ],
      ),
    );
  }
}
