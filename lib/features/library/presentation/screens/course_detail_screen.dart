import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/theme/timeline_tokens.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/moderation_chip.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/models.dart';
import '../../../learn/data/cart_provider.dart';
import '../../../learn/data/course_cover_images.dart';
import '../../../learn/data/course_pricing.dart';
import '../../../learn/data/payments_repository.dart';
import '../../../learn/presentation/widgets/course_price_row.dart';

/// Détail cours style Udemy.
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

  bool _ownsCourse(String courseId) {
    final ids = ref.watch(purchasedCourseIdsProvider).valueOrNull ?? {};
    return ids.contains(courseId);
  }

  Future<bool> _ensurePurchased(String courseId) async {
    if (_ownsCourse(courseId)) return true;
    final goCheckout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cours payant'),
        content: const Text(
          'Ce cours est payant. Finalise le paiement pour accéder aux leçons. '
          'L’accès est débloqué après confirmation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Plus tard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Acheter'),
          ),
        ],
      ),
    );
    if (goCheckout == true && mounted) {
      final outline =
          ref.read(courseOutlineProvider(courseId)).valueOrNull;
      final price = ref.read(catalogPricingProvider).valueOrNull?.salePriceUsd ??
          CatalogPricing.offlineFallback.salePriceUsd;
      if (outline != null) {
        ref.read(cartProvider.notifier).addCourse(
              outline.course,
              priceUsd: price,
            );
      }
      context.push('/checkout');
    }
    return false;
  }

  Future<void> _openLesson({
    required CourseLessonItem lesson,
    required Course course,
    required List<CourseModuleItem> modules,
    bool isFreePreview = false,
  }) async {
    if (!isFreePreview) {
      final ok = await _ensurePurchased(course.id);
      if (!ok) return;
    }
    if (!mounted) return;
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

  void _openCoursePreview(
    BuildContext context, {
    required Course course,
    required List<CourseModuleItem> modules,
  }) {
    final lessons = modules.expand((m) => m.lessons).toList();
    final withVideo = lessons.where((l) => l.videoUrl.trim().isNotEmpty);
    final CourseLessonItem lesson;
    final bool freePreview;
    if (withVideo.isNotEmpty) {
      lesson = withVideo.first;
      freePreview = false;
    } else if (lessons.isNotEmpty) {
      lesson = lessons.first;
      freePreview = false;
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
      freePreview = true;
    }

    unawaited(
      _openLesson(
        lesson: lesson,
        course: course,
        modules: modules,
        isFreePreview: freePreview,
      ),
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

        final feed = TimelineTokens.of(context);
        final primary = Theme.of(context).colorScheme.primary;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: feed.feedBg,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: feed.cardBg,
                surfaceTintColor: Colors.transparent,
                foregroundColor: feed.ink,
                leading: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Panier',
                    onPressed: () => context.push('/cart'),
                    icon: Badge(
                      isLabelVisible: ref.watch(cartProvider).isNotEmpty,
                      label: Text('${ref.watch(cartProvider).length}'),
                      child: const Icon(Icons.shopping_cart_outlined),
                    ),
                  ),
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
                        style: TextStyle(
                          color: primary,
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
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: feed.ink,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const CoursePriceRow(),
                          if (course.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              course.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                color: feed.meta,
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
                                    bg: feed.softTint,
                                    fg: primary,
                                  ),
                              ],
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
                                    bg: (isDark
                                        ? const [
                                            Color(0xFF1E3A36),
                                            Color(0xFF3A3020),
                                            Color(0xFF242424),
                                          ]
                                        : [
                                            const Color(0xFFACE4DB),
                                            const Color(0xFFF3CA8C),
                                            feed.softTint,
                                          ])[i % 3],
                                    fg: (isDark
                                        ? [
                                            const Color(0xFF7DCEC0),
                                            const Color(0xFFE0C070),
                                            primary,
                                          ]
                                        : [
                                            const Color(0xFF1E6055),
                                            const Color(0xFF3D3C0A),
                                            primary,
                                          ])[i % 3],
                                  ),
                              ],
                            ),
                          const SizedBox(height: 14),
                          Text.rich(
                            TextSpan(
                              style: const TextStyle(fontSize: 14),
                              children: [
                                TextSpan(
                                  text: 'Créé par ',
                                  style: TextStyle(color: feed.ink),
                                ),
                                TextSpan(
                                  text: course.displayTeacher,
                                  style: TextStyle(
                                    color: primary,
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
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: feed.divider),
                                bottom: BorderSide(color: feed.divider),
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
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                    width: 1,
                                    height: 36,
                                    color: feed.divider),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Icon(Icons.workspace_premium,
                                          color: primary, size: 20),
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
                                    color: feed.divider),
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
                                    Border.all(color: feed.divider),
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
                                          Icon(Icons.check,
                                              size: 18,
                                              color: feed.ink),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              item,
                                              style: TextStyle(
                                                fontSize: 14,
                                                height: 1.4,
                                                color: feed.ink,
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
                            style: TextStyle(
                              color: feed.meta,
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
                                  unawaited(
                                    _openLesson(
                                      lesson: lesson,
                                      course: course,
                                      modules: outline.modules,
                                    ),
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
                                style: TextStyle(
                                  height: 1.45,
                                  color: feed.ink,
                                ),
                              ),
                            ),
                          Divider(height: 1, color: feed.divider),
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
                            style: TextStyle(
                              height: 1.45,
                              color: feed.ink,
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(
                              () => _descExpanded = !_descExpanded,
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: primary,
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
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                          if (course.teacherSpecialty.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              course.teacherSpecialty,
                              style: TextStyle(
                                color: feed.ink,
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
                              style: TextStyle(
                                color: feed.meta,
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
                                backgroundColor: feed.softTint,
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
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                      color: primary,
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
                              style: TextStyle(
                                height: 1.45,
                                color: feed.ink,
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
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    'Aucun avis pour l’instant.',
                                    style: TextStyle(color: feed.meta),
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
                                          color: feed.divider,
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
                                                    feed.softTint,
                                                child: Text(
                                                  c.author.isNotEmpty
                                                      ? c.author[0]
                                                          .toUpperCase()
                                                      : '?',
                        style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                    color: primary,
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
          bottomNavigationBar: _CourseBuyBar(course: course),
        );
      },
    );
  }
}

class _CourseBuyBar extends ConsumerWidget {
  const _CourseBuyBar({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = TimelineTokens.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    final inCart = cart.any((e) => e.courseId == course.id);
    final owned =
        (ref.watch(purchasedCourseIdsProvider).valueOrNull ?? {}).contains(
      course.id,
    );

    if (owned) {
      return Material(
        color: feed.cardBg,
        elevation: 8,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  // Relance l’aperçu / première leçon via le parent —
                  // simple: reste sur la page, scroll contenu.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cours débloqué — ouvre une leçon ci-dessus.'),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text(
                  'Accès confirmé',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: feed.cardBg,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              const CoursePriceRow(dense: true),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (inCart) {
                      context.push('/cart');
                      return;
                    }
                    final price = ref
                            .read(catalogPricingProvider)
                            .valueOrNull
                            ?.salePriceUsd ??
                        CatalogPricing.offlineFallback.salePriceUsd;
                    final added =
                        notifier.addCourse(course, priceUsd: price);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          added
                              ? 'Ajouté au panier'
                              : 'Déjà dans le panier',
                        ),
                        action: SnackBarAction(
                          label: 'Voir',
                          onPressed: () => context.push('/cart'),
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    inCart ? 'Voir le panier' : 'Ajouter',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final price = ref
                            .read(catalogPricingProvider)
                            .valueOrNull
                            ?.salePriceUsd ??
                        CatalogPricing.offlineFallback.salePriceUsd;
                    notifier.addCourse(course, priceUsd: price);
                    context.push('/checkout');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Acheter',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
          Icon(icon, size: 16, color: TimelineTokens.of(context).meta),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: TimelineTokens.of(context).ink),
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
          Icon(icon, size: 20, color: TimelineTokens.of(context).ink),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: TimelineTokens.of(context).ink),
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
          Icon(icon, size: 16, color: TimelineTokens.of(context).ink),
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
        border: Border.all(color: TimelineTokens.of(context).divider),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Container(
              width: double.infinity,
              color: TimelineTokens.of(context).softTint,
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
                    style: TextStyle(
                      color: TimelineTokens.of(context).meta,
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
                    ? Text(
                        'Aperçu',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
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
