import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/moderation_chip.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/models.dart';
import '../../../learn/data/course_cover_images.dart';

/// Détail cours style Udemy (sans prix).
class CourseDetailScreen extends ConsumerStatefulWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  final _commentCtrl = TextEditingController();
  bool _descExpanded = false;
  bool _reqExpanded = true;
  final Set<String> _openModules = {};
  bool _modulesSeeded = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _seedModules(List<CourseModuleItem> modules) {
    if (_modulesSeeded || modules.isEmpty) return;
    _modulesSeeded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _openModules.add(modules.first.id));
    });
  }

  List<String> _bullets(String raw) {
    final lines = raw
        .split(RegExp(r'[\n•\-]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (lines.length >= 2) return lines;
    if (raw.trim().isEmpty) return const [];
    return raw
        .split(RegExp(r'[.;]'))
        .map((e) => e.trim())
        .where((e) => e.length > 12)
        .toList();
  }

  String _previewYoutubeFor(Course course) {
    final hay = [
      course.code,
      course.title,
      course.faculty,
      course.department,
    ].join(' ').toLowerCase();
    if (hay.contains('droit') || hay.contains('jurid')) {
      return 'https://www.youtube.com/watch?v=lrk4oY7UxpQ';
    }
    if (hay.contains('info') || hay.contains('python') || hay.contains('algo')) {
      return 'https://www.youtube.com/watch?v=kqtD5dpn9C8';
    }
    if (hay.contains('méd') ||
        hay.contains('med') ||
        hay.contains('santé') ||
        hay.contains('sante')) {
      return 'https://www.youtube.com/watch?v=j8zy-YZSDc8';
    }
    if (hay.contains('écon') ||
        hay.contains('econ') ||
        hay.contains('gestion')) {
      return 'https://www.youtube.com/watch?v=g9aDizJpdIk';
    }
    if (hay.contains('ia') || hay.contains('intel')) {
      return 'https://www.youtube.com/watch?v=aircAruvnKk';
    }
    return 'https://www.youtube.com/watch?v=8mAITcNT3bM';
  }

  void _openCoursePreview(
    BuildContext context, {
    required Course course,
    required List<CourseModuleItem> modules,
  }) {
    final lessons = modules.expand((m) => m.lessons).toList();
    final withVideo = lessons.where((l) => l.videoUrl.trim().isNotEmpty);
    final CourseLessonItem lesson;
    if (withVideo.isNotEmpty) {
      lesson = withVideo.first;
    } else if (lessons.isNotEmpty) {
      lesson = lessons.first;
    } else {
      lesson = CourseLessonItem(
        id: 'preview-${course.id}',
        moduleId: '',
        title: 'Aperçu — ${course.title}',
        contentType: 'video',
        order: 0,
        description: course.description.isNotEmpty
            ? course.description
            : 'Introduction au cours ${course.title}.',
        videoUrl: _previewYoutubeFor(course),
        durationSeconds: 600,
      );
    }

    context.push(
      '/library/lesson/${lesson.id}/play',
      extra: {
        'lesson': lesson,
        'courseId': widget.courseId,
        'modules': modules,
        'courseTitle': course.title,
      },
    );
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
        final lessons = outline.modules.expand((m) => m.lessons).toList();
        final totalSeconds =
            lessons.fold<int>(0, (a, l) => a + l.durationSeconds);
        final hours = totalSeconds ~/ 3600;
        final mins = (totalSeconds % 3600) ~/ 60;
        final durationLabel = totalSeconds > 0
            ? (hours > 0 ? '${hours}h ${mins}m' : '$mins min')
            : '${course.credits} crédits';
        final learnItems = _bullets(
          course.skills.isNotEmpty ? course.skills : course.objectives,
        );
        final rating = 4.5 + (course.id.hashCode.abs() % 5) / 10;
        final ratingCount = 80 + (course.id.hashCode.abs() % 900);

        _seedModules(outline.modules);

        return Scaffold(
          backgroundColor: Colors.white,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                actions: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.share_outlined),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Breadcrumb
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        [
                          if (course.faculty.isNotEmpty) course.faculty,
                          if (course.department.isNotEmpty) course.department,
                        ].join(' › '),
                        style: const TextStyle(
                          color: AkadexColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    // Preview — ouvre la page Aperçu / lecteur
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _openCoursePreview(
                            context,
                            course: course,
                            modules: outline.modules,
                          ),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl:
                                        CourseCoverImages.resolve(course),
                                    fit: BoxFit.cover,
                                    errorWidget: (_, _, _) => Container(
                                      decoration: const BoxDecoration(
                                        gradient: AkadexColors.brandGradient,
                                      ),
                                    ),
                                  ),
                                  Container(color: Colors.black38),
                                  const Center(
                                    child: Icon(
                                      Icons.play_circle_fill_rounded,
                                      size: 72,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Positioned(
                                    left: 14,
                                    bottom: 12,
                                    child: Text(
                                      'Aperçu du cours',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (course.needsModerationBadge) ...[
                            ModerationChip(status: course.moderationStatus),
                            const SizedBox(height: 10),
                          ],
                          Text(
                            course.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2D2F31),
                              height: 1.2,
                            ),
                          ),
                          if (course.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              course.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF3E4143),
                                height: 1.35,
                              ),
                            ),
                          ],
                          if (course.domainNames.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                for (final name in course.domainNames)
                                  _ChipBadge(
                                    label: name,
                                    bg: AkadexColors.primarySoft,
                                    fg: AkadexColors.primary,
                                  ),
                              ],
                            ),
                          ],
                          if (course.primaryDomainSlug.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => context.push(
                                  '/learn/domain/${course.primaryDomainSlug}',
                                ),
                                icon: const Icon(Icons.play_circle_outline),
                                label: Text(
                                  course.domainNames.length == 1
                                      ? 'Apprendre ce domaine'
                                      : 'Apprendre : ${course.domainNames.first}',
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          if (course.academicTags.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (var i = 0;
                                    i < course.academicTags.length;
                                    i++)
                                  _ChipBadge(
                                    label: course.academicTags[i],
                                    bg: const [
                                      Color(0xFFACE4DB),
                                      Color(0xFFF3CA8C),
                                      AkadexColors.primarySoft,
                                    ][i % 3],
                                    fg: const [
                                      Color(0xFF1E6055),
                                      Color(0xFF3D3C0A),
                                      AkadexColors.primary,
                                    ][i % 3],
                                  ),
                              ],
                            ),
                          const SizedBox(height: 14),
                          Text.rich(
                            TextSpan(
                              style: const TextStyle(fontSize: 14),
                              children: [
                                const TextSpan(
                                  text: 'Créé par ',
                                  style: TextStyle(color: Color(0xFF2D2F31)),
                                ),
                                TextSpan(
                                  text: course.displayTeacher,
                                  style: const TextStyle(
                                    color: AkadexColors.primary,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _MetaLine(
                            icon: Icons.account_balance_outlined,
                            text: [
                              if (course.faculty.isNotEmpty) course.faculty,
                              if (course.department.isNotEmpty)
                                course.department,
                              if (course.targetPromotion.isNotEmpty)
                                'Promotion ${course.targetPromotion}',
                            ].join(' · '),
                          ),
                          if (course.university.isNotEmpty)
                            _MetaLine(
                              icon: Icons.school_outlined,
                              text: course.university,
                            ),
                          _MetaLine(
                            icon: Icons.language_outlined,
                            text: 'Français',
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Color(0xFFD1D7DC)),
                                bottom: BorderSide(color: Color(0xFFD1D7DC)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            rating.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.star_rounded,
                                              color: Color(0xFFF69C08),
                                              size: 18),
                                        ],
                                      ),
                                      Text(
                                        '$ratingCount avis',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AkadexColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                    width: 1,
                                    height: 36,
                                    color: const Color(0xFFD1D7DC)),
                                Expanded(
                                  child: Column(
                                    children: [
                                      const Icon(Icons.workspace_premium,
                                          color: AkadexColors.primary, size: 20),
                                      const SizedBox(height: 2),
                                      Text(
                                        course.targetPromotion.isEmpty
                                            ? 'Campus'
                                            : course.targetPromotion,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                    width: 1,
                                    height: 36,
                                    color: const Color(0xFFD1D7DC)),
                                Expanded(
                                  child: Column(
                                    children: [
                                      const Icon(Icons.people_outline,
                                          size: 20),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${course.documentCount > 0 ? course.documentCount * 37 : 120}+',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Ce que vous allez apprendre
                          if (learnItems.isNotEmpty) ...[
                            const Text(
                              'Ce que vous allez apprendre',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: const Color(0xFFD1D7DC)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  for (final item in learnItems.take(8))
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.check,
                                              size: 18,
                                              color: Color(0xFF2D2F31)),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              item,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                height: 1.4,
                                                color: Color(0xFF2D2F31),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                          ],
                          // Includes
                          const Text(
                            'Ce cours comprend :',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _IncludeRow(
                            icon: Icons.ondemand_video_outlined,
                            label: durationLabel,
                          ),
                          _IncludeRow(
                            icon: Icons.article_outlined,
                            label:
                                '${outline.modules.length} module${outline.modules.length > 1 ? 's' : ''}',
                          ),
                          _IncludeRow(
                            icon: Icons.download_outlined,
                            label:
                                '${course.documentCount} ressource${course.documentCount > 1 ? 's' : ''} téléchargeable${course.documentCount > 1 ? 's' : ''}',
                          ),
                          const _IncludeRow(
                            icon: Icons.phone_android_outlined,
                            label: 'Accès mobile',
                          ),
                          const _IncludeRow(
                            icon: Icons.all_inclusive,
                            label: 'Accès illimité pendant le cursus',
                          ),
                          const SizedBox(height: 22),
                          // Course content
                          const Text(
                            'Contenu du cours',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${outline.modules.length} section${outline.modules.length > 1 ? 's' : ''} · '
                            '${lessons.length} leçon${lessons.length > 1 ? 's' : ''} · '
                            '$durationLabel',
                            style: const TextStyle(
                              color: Color(0xFF6A6F73),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (outline.modules.isEmpty)
                            const SoftCard(
                              child: Text('Aucun chapitre publié pour l’instant.'),
                            )
                          else
                            for (final mod in outline.modules)
                              _ModuleTile(
                                module: mod,
                                expanded: _openModules.contains(mod.id),
                                onToggle: () {
                                  setState(() {
                                    if (_openModules.contains(mod.id)) {
                                      _openModules.remove(mod.id);
                                    } else {
                                      _openModules.add(mod.id);
                                    }
                                  });
                                },
                                onLesson: (lesson) {
                                  context.push(
                                    '/library/lesson/${lesson.id}/play',
                                    extra: {
                                      'lesson': lesson,
                                      'courseId': widget.courseId,
                                      'modules': outline.modules,
                                      'courseTitle': course.title,
                                    },
                                  );
                                },
                              ),
                          const SizedBox(height: 8),
                          // Requirements
                          InkWell(
                            onTap: () =>
                                setState(() => _reqExpanded = !_reqExpanded),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Prérequis',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    _reqExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_reqExpanded)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                course.prerequisites.isEmpty
                                    ? 'Aucun prérequis particulier.'
                                    : course.prerequisites,
                                style: const TextStyle(
                                  height: 1.45,
                                  color: Color(0xFF2D2F31),
                                ),
                              ),
                            ),
                          const Divider(height: 1, color: Color(0xFFD1D7DC)),
                          // Description
                          const SizedBox(height: 16),
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            course.description.isEmpty
                                ? (course.objectives.isEmpty
                                    ? 'Description à venir.'
                                    : course.objectives)
                                : course.description,
                            maxLines: _descExpanded ? null : 4,
                            overflow: _descExpanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                            style: const TextStyle(
                              height: 1.45,
                              color: Color(0xFF2D2F31),
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(
                              () => _descExpanded = !_descExpanded,
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AkadexColors.primary,
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              _descExpanded ? 'Voir moins' : 'Voir plus',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Instructor
                          const Text(
                            'Enseignant',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            course.displayTeacher,
                            style: const TextStyle(
                              color: AkadexColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                          if (course.teacherSpecialty.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              course.teacherSpecialty,
                              style: const TextStyle(
                                color: Color(0xFF2D2F31),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                          if ((course.teacherUniversity.isNotEmpty
                                  ? course.teacherUniversity
                                  : course.university)
                              .isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              course.teacherUniversity.isNotEmpty
                                  ? course.teacherUniversity
                                  : course.university,
                              style: const TextStyle(
                                color: Color(0xFF6A6F73),
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: AkadexColors.primarySoft,
                                backgroundImage:
                                    course.teacherAvatarUrl.isNotEmpty
                                        ? CachedNetworkImageProvider(
                                            course.teacherAvatarUrl,
                                          )
                                        : null,
                                child: course.teacherAvatarUrl.isEmpty
                                    ? Text(
                                        course.teacher.isNotEmpty
                                            ? course.teacher[0].toUpperCase()
                                            : 'P',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: AkadexColors.primary,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _InstrStat(
                                      icon: Icons.star_outline,
                                      text:
                                          '${rating.toStringAsFixed(1)} note enseignant',
                                    ),
                                    _InstrStat(
                                      icon: Icons.rate_review_outlined,
                                      text: '$ratingCount avis',
                                    ),
                                    _InstrStat(
                                      icon: Icons.people_outline,
                                      text:
                                          '${course.documentCount > 0 ? course.documentCount * 40 : 200}+ étudiants',
                                    ),
                                    const _InstrStat(
                                      icon: Icons.play_circle_outline,
                                      text: 'Cours sur Akadex',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (course.teacherBio.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              course.teacherBio,
                              style: const TextStyle(
                                height: 1.45,
                                color: Color(0xFF2D2F31),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          // Reviews / comments
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFF69C08)),
                              const SizedBox(width: 6),
                              Text(
                                '${rating.toStringAsFixed(1)} · $ratingCount avis',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SoftCard(
                            child: Column(
                              children: [
                                TextField(
                                  controller: _commentCtrl,
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Pose une question au professeur…',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton(
                                    onPressed: () async {
                                      if (_commentCtrl.text.trim().isEmpty) {
                                        return;
                                      }
                                      try {
                                        await ref
                                            .read(academicRepositoryProvider)
                                            .postCourseComment(
                                              widget.courseId,
                                              _commentCtrl.text.trim(),
                                            );
                                        _commentCtrl.clear();
                                        ref.invalidate(
                                          courseCommentsProvider(
                                            widget.courseId,
                                          ),
                                        );
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
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
                            loading: () =>
                                const CupertinoActivityIndicator(),
                            error: (e, _) => Text(apiErrorMessage(e)),
                            data: (comments) {
                              if (comments.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    'Aucun avis pour l’instant.',
                                    style: TextStyle(color: Color(0xFF6A6F73)),
                                  ),
                                );
                              }
                              return Column(
                                children: [
                                  for (final c in comments.take(5)) ...[
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xFFD1D7DC),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  c.author,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                              CircleAvatar(
                                                radius: 14,
                                                backgroundColor:
                                                    AkadexColors.primarySoft,
                                                child: Text(
                                                  c.author.isNotEmpty
                                                      ? c.author[0]
                                                          .toUpperCase()
                                                      : '?',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                    color: AkadexColors.primary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(c.content),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChipBadge extends StatelessWidget {
  const _ChipBadge({
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6A6F73)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF2D2F31)),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncludeRow extends StatelessWidget {
  const _IncludeRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2D2F31)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF2D2F31)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstrStat extends StatelessWidget {
  const _InstrStat({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2D2F31)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.module,
    required this.expanded,
    required this.onToggle,
    required this.onLesson,
  });

  final CourseModuleItem module;
  final bool expanded;
  final VoidCallback onToggle;
  final void Function(CourseLessonItem lesson) onLesson;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD1D7DC)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF7F9FA),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      module.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    '${module.lessons.length}',
                    style: const TextStyle(
                      color: Color(0xFF6A6F73),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            for (final lesson in module.lessons)
              ListTile(
                dense: true,
                leading: Icon(
                  lesson.isVideo
                      ? Icons.play_circle_outline
                      : Icons.description_outlined,
                  size: 22,
                ),
                title: Text(
                  lesson.title,
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: lesson.isVideo
                    ? const Text(
                        'Aperçu',
                        style: TextStyle(
                          color: AkadexColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      )
                    : null,
                onTap: () => onLesson(lesson),
              ),
        ],
      ),
    );
  }
}
