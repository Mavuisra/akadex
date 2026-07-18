import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/repositories/repositories.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outlineAsync = ref.watch(courseOutlineProvider(widget.courseId));
    final commentsAsync = ref.watch(courseCommentsProvider(widget.courseId));

    return outlineAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CupertinoActivityIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: Center(child: Text(apiErrorMessage(e))),
      ),
      data: (outline) {
        final course = outline.course;
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                leading: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AkadexColors.primary,
                          AkadexColors.primaryDark,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(56, 48, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              course.code,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              course.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prof. ${course.teacher}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              if (course.university.isNotEmpty) course.university,
                              if (course.faculty.isNotEmpty) course.faculty,
                              if (course.department.isNotEmpty) course.department,
                              if (course.semester.isNotEmpty) course.semester,
                            ].join(' · '),
                            style: const TextStyle(
                              color: AkadexColors.inkMuted,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (course.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const SectionTitle('À propos'),
                      const SizedBox(height: 8),
                      SoftCard(child: Text(course.description, style: const TextStyle(height: 1.45))),
                    ],
                    if (course.objectives.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SoftCard(
                        child: _MetaBlock(
                          title: 'Objectifs pédagogiques',
                          body: course.objectives,
                        ),
                      ),
                    ],
                    if (course.skills.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SoftCard(
                        child: _MetaBlock(
                          title: 'Compétences acquises',
                          body: course.skills,
                        ),
                      ),
                    ],
                    if (course.prerequisites.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SoftCard(
                        child: _MetaBlock(
                          title: 'Prérequis',
                          body: course.prerequisites,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const SectionTitle('Programme'),
                    const SizedBox(height: 8),
                    if (outline.modules.isEmpty)
                      SoftCard(
                        child: Text(
                          'Aucun chapitre publié pour l’instant.',
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.6),
                          ),
                        ),
                      )
                    else
                      for (final mod in outline.modules) ...[
                        SoftCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mod.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              if (mod.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  mod.description,
                                  style: const TextStyle(
                                    color: AkadexColors.inkMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              for (final lesson in mod.lessons)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    lesson.isVideo
                                        ? Icons.play_circle_fill_rounded
                                        : Icons.description_outlined,
                                    color: AkadexColors.primary,
                                  ),
                                  title: Text(
                                    lesson.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    lesson.contentType.toUpperCase(),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  trailing: lesson.durationSeconds > 0
                                      ? Text(
                                          '${lesson.durationSeconds ~/ 60} min',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AkadexColors.inkMuted,
                                          ),
                                        )
                                      : null,
                                  onTap: () {
                                    if (lesson.isVideo) {
                                      context.push(
                                        '/library/lesson/${lesson.id}/play',
                                        extra: {
                                          'lesson': lesson,
                                          'courseId': widget.courseId,
                                          'modules': outline.modules,
                                        },
                                      );
                                    } else if (lesson.externalUrl.isNotEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Ressource : ${lesson.externalUrl}',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    const SizedBox(height: 12),
                    const SectionTitle('Commentaires'),
                    const SizedBox(height: 8),
                    SoftCard(
                      child: Column(
                        children: [
                          TextField(
                            controller: _commentCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Pose une question au professeur…',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: () async {
                                if (_commentCtrl.text.trim().isEmpty) return;
                                try {
                                  await ref
                                      .read(academicRepositoryProvider)
                                      .postCourseComment(
                                        widget.courseId,
                                        _commentCtrl.text.trim(),
                                      );
                                  _commentCtrl.clear();
                                  ref.invalidate(
                                    courseCommentsProvider(widget.courseId),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(apiErrorMessage(e)),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Publier'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    commentsAsync.when(
                      loading: () => const CupertinoActivityIndicator(),
                      error: (e, _) => Text(apiErrorMessage(e)),
                      data: (comments) => Column(
                        children: [
                          for (final c in comments) ...[
                            SoftCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${c.author}${c.authorRole.isNotEmpty ? ' · ${c.authorRole}' : ''}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(c.content),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetaBlock extends StatelessWidget {
  const _MetaBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(body, style: const TextStyle(height: 1.4)),
      ],
    );
  }
}
