import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/timeline_tokens.dart';
import '../../../../domain/models/models.dart';
import '../../data/course_cover_images.dart';
import '../../data/learn_domains.dart';
import 'course_price_row.dart';

/// Carte cours style Udemy avec prix promo.
class CourseUdemyCard extends StatelessWidget {
  const CourseUdemyCard({
    super.key,
    required this.course,
    this.onTap,
  });

  final Course course;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final rating = 4.5 + (course.id.hashCode.abs() % 5) / 10;
    final ratingsCount = 80 + (course.id.hashCode.abs() % 900);
    final cover = CourseCoverImages.resolve(course);
    final feed = TimelineTokens.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: feed.cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ??
            () => context.push('/library/course/${course.id}'),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: feed.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: cover,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        color: const Color(0xFFE4E6EB),
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, _, _) => Image.network(
                        'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=1200&q=80',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: feed.softTint,
                          alignment: Alignment.center,
                          child: Icon(Icons.school_outlined,
                              size: 40, color: feed.meta),
                        ),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.code,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            course.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: feed.ink,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      course.displayTeacher,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: feed.meta,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (course.teacherSpecialty.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        course.teacherSpecialty,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: feed.meta,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (course.faculty.isNotEmpty) course.faculty,
                        if (course.department.isNotEmpty) course.department,
                        if (course.targetPromotion.isNotEmpty)
                          'Promo ${course.targetPromotion}',
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: feed.meta,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const CoursePriceRow(dense: true),
                        const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 16, color: Color(0xFFF69C08)),
                            const SizedBox(width: 3),
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: isDark
                                    ? const Color(0xFFF0C060)
                                    : const Color(0xFF4D3105),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '($ratingsCount)',
                              style: TextStyle(
                                fontSize: 12,
                                color: feed.meta,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (course.levelLabel.isNotEmpty)
                          _Badge(
                            label: course.levelLabel,
                            bg: isDark
                                ? const Color(0xFF1E3A36)
                                : const Color(0xFFACE4DB),
                            fg: isDark
                                ? const Color(0xFF7DCEC0)
                                : const Color(0xFF1E6055),
                          ),
                        if (course.targetPromotion.isNotEmpty)
                          _Badge(
                            label: course.targetPromotion,
                            bg: feed.softTint,
                            fg: primary,
                          ),
                        if (course.estimatedHours > 0)
                          _Badge(
                            label: '${course.estimatedHours} h',
                            bg: isDark
                                ? const Color(0xFF3A3020)
                                : const Color(0xFFF3CA8C),
                            fg: isDark
                                ? const Color(0xFFE0C070)
                                : const Color(0xFF3D3C0A),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// Stories domaines avec photos de couverture.
class DomainStoriesRow extends StatelessWidget {
  const DomainStoriesRow({
    super.key,
    required this.domains,
    required this.courseCounts,
    required this.onTap,
  });

  final List<LearnDomain> domains;
  final Map<String, int> courseCounts;
  final void Function(LearnDomain domain) onTap;

  static const _photos = <String, String>{
    'informatique':
        'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=600&q=80',
    'droit':
        'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=600&q=80',
    'medecine':
        'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=600&q=80',
    'economie':
        'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=600&q=80',
    'sciences':
        'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=600&q=80',
    'lettres':
        'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?w=600&q=80',
    'ingenierie':
        'https://images.unsplash.com/photo-1581094794329-c8112a89af12?w=600&q=80',
    'agronomie':
        'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=600&q=80',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: domains.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          if (i == 0) {
            return _CreateDomainCard(onTap: () => context.push('/lmd'));
          }
          final d = domains[i - 1];
          return _DomainStoryCard(
            name: d.name,
            photoUrl: _photos[d.id],
            colors: d.colors,
            count: courseCounts[d.id] ?? 0,
            onTap: () => onTap(d),
          );
        },
      ),
    );
  }
}

class _CreateDomainCard extends StatelessWidget {
  const _CreateDomainCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 104,
        decoration: BoxDecoration(
          color: feed.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: feed.divider),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: feed.softTint,
                    shape: BoxShape.circle,
                    border: Border.all(color: primary, width: 2),
                  ),
                  child: Icon(Icons.add, color: primary),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              child: Text(
                'Guide LMD',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: feed.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DomainStoryCard extends StatelessWidget {
  const _DomainStoryCard({
    required this.name,
    required this.colors,
    required this.count,
    required this.onTap,
    this.photoUrl,
  });

  final String name;
  final String? photoUrl;
  final List<Color> colors;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 104,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photoUrl != null)
              CachedNetworkImage(
                imageUrl: photoUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const SizedBox.shrink(),
              ),
            Container(color: Colors.black.withValues(alpha: 0.35)),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1877F2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 24, 8, 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
