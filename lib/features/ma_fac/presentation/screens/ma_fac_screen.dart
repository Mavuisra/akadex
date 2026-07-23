import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/theme/timeline_tokens.dart';
import '../../../../core/widgets/moderation_chip.dart';
import '../../../../core/widgets/shimmer_skeletons.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/mappers/mappers.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/document_type.dart';
import '../../../../domain/models/models.dart';
import '../../../learn/data/learn_domains.dart';
import '../../data/career_outlets.dart';
import '../../data/ma_fac_categories.dart';
import '../../data/ma_fac_scope.dart';

/// Portail Ma Fac — style feed Accueil (Facebook), structure fac / dépts / promos.
class MaFacScreen extends ConsumerStatefulWidget {
  const MaFacScreen({super.key});

  static List<Course> filterCourses(List<Course> all, UserProfile? me) =>
      MaFacScope.filterCourses(all, me);

  @override
  ConsumerState<MaFacScreen> createState() => _MaFacScreenState();
}

class _MaFacScreenState extends ConsumerState<MaFacScreen> {
  int _tab = 0;
  String? _selectedDeptId;
  String? _selectedPromoId;

  static const _tabs = <(String, String)>[
    ('parcours', 'Parcours'),
    ('travaux', 'Travaux'),
    ('debouches', 'Débouchés'),
  ];

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authStateProvider).valueOrNull;
    final coursesAsync = ref.watch(coursesProvider);
    final allCourses = coursesAsync.valueOrNull ?? const <Course>[];
    final coursesBusy = coursesAsync.isLoading && allCourses.isEmpty;
    final coursesError = coursesAsync.hasError && allCourses.isEmpty;

    // Docs : Parcours (compteur) + Travaux.
    final needDocs = _tab == 0 || _tab == 1;
    final docsAsync = needDocs
        ? ref.watch(
            documentsProvider(
              DocumentQuery(
                universityId: me?.universityId.isNotEmpty == true
                    ? me!.universityId
                    : null,
                departmentId: me?.departmentId.isNotEmpty == true
                    ? me!.departmentId
                    : null,
                facultyId:
                    me?.facultyId.isNotEmpty == true ? me!.facultyId : null,
                ordering: '-created_at',
              ),
            ),
          )
        : const AsyncValue<List<AcademicDocument>>.data([]);
    final deptsAsync = ref.watch(
      facultyDepartmentsProvider(
        me?.facultyId.isNotEmpty == true ? me!.facultyId : null,
      ),
    );
    final promosAsync = ref.watch(
      promotionsProvider(
        _selectedDeptId ??
            (me?.departmentId.isNotEmpty == true ? me!.departmentId : null),
      ),
    );

    if (coursesError) {
      return Scaffold(
        backgroundColor: TimelineTokens.feedBg,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(apiErrorMessage(coursesAsync.error!)),
                TextButton(
                  onPressed: () => ref.invalidate(coursesProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final facName =
        me?.faculty.isNotEmpty == true ? me!.faculty : 'Ma faculté';
    final docs = docsAsync.valueOrNull ?? const <AcademicDocument>[];
    final career = CareerOutlets.forProfile(me);

    final allDepts = deptsAsync.valueOrNull ?? const <DepartmentItem>[];
    final facId = me?.facultyId ?? '';
    final facLabel = (me?.faculty ?? '').toLowerCase();
    // Uniquement les départements de la faculté de l’étudiant (pas toute l’univ).
    final depts = facId.isEmpty
        ? const <DepartmentItem>[]
        : allDepts
            .where((d) => d.facultyId.isEmpty || d.facultyId == facId)
            .toList();

    final activeDeptId = _selectedDeptId ??
        (me?.departmentId.isNotEmpty == true
            ? me!.departmentId
            : (depts.isNotEmpty ? depts.first.id : null));

    final promos = promosAsync.valueOrNull ?? const <PromotionItem>[];
    final activePromoId = _selectedPromoId ??
        (me?.promotionId.isNotEmpty == true ? me!.promotionId : null);

    // Ma Fac = contributions / programmes réels uniquement (jamais les AKX vitrine).
    final realCourses =
        allCourses.where((c) => !c.code.startsWith('AKX-')).toList();
    final facCourses = realCourses.where((c) {
      if (me != null && MaFacScope.courseMatchesUser(c, me)) return true;
      final hay =
          '${c.faculty} ${c.department} ${c.university}'.toLowerCase();
      if (facLabel.isNotEmpty &&
          hay.contains(facLabel.split(' ').first)) {
        return true;
      }
      return false;
    }).toList();

    List<Course> scopedCourses = facCourses;
    if (activeDeptId != null) {
      final deptName = depts
          .where((d) => d.id == activeDeptId)
          .map((d) => d.name.toLowerCase())
          .firstOrNull;
      if (deptName != null && deptName.isNotEmpty) {
        final byDept = facCourses
            .where((c) => c.department.toLowerCase().contains(
                  deptName.split(' ').first,
                ))
            .toList();
        if (byDept.isNotEmpty) scopedCourses = byDept;
      }
    }
    if (activePromoId != null) {
      final promo = promos.where((p) => p.id == activePromoId).firstOrNull;
      if (promo != null) {
        final lvl = promo.level.toLowerCase();
        final pname = promo.name.toLowerCase();
        final byPromo = scopedCourses.where((c) {
          final h =
              '${c.semester} ${c.targetPromotion} ${c.levelLabel}'.toLowerCase();
          return (lvl.isNotEmpty && h.contains(lvl)) ||
              (pname.isNotEmpty && h.contains(pname.split(' ').first));
        }).toList();
        if (byPromo.isNotEmpty) scopedCourses = byPromo;
      }
    }

    return Scaffold(
      backgroundColor: TimelineTokens.feedBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _FbHeader(user: me),
            _FbTabBar(
              tabs: _tabs,
              selected: _tab,
              onSelected: (i) => setState(() => _tab = i),
            ),
            Expanded(
              child: coursesBusy && _tab == 0
                  ? const LearnScreenSkeleton(cardCount: 2)
                  : IndexedStack(
                      index: _tab,
                      children: [
                        _ParcoursFeed(
                          facultyName: facName,
                          universityName: me?.university ?? '',
                          departmentName: me?.department.isNotEmpty == true
                              ? me!.department
                              : (depts
                                      .where((d) => d.id == activeDeptId)
                                      .map((d) => d.name)
                                      .firstOrNull ??
                                  ''),
                          userName: me?.name ?? '',
                          departments: depts,
                          selectedDeptId: activeDeptId,
                          promotions: promos,
                          selectedPromoId: activePromoId,
                          courses: scopedCourses,
                          courseCount: scopedCourses.length,
                          docCount: docs.length,
                          onOpenTab: (i) => setState(() => _tab = i),
                          onExploreDept: (d) {
                            setState(() {
                              _selectedDeptId = d.id;
                              _selectedPromoId = null;
                            });
                            final params = {
                              'departmentId': d.id,
                              'departmentName': d.name,
                              if (facName.isNotEmpty) 'facultyName': facName,
                            };
                            final qs = params.entries
                                .map(
                                  (e) =>
                                      '${e.key}=${Uri.encodeComponent(e.value)}',
                                )
                                .join('&');
                            context.push('/library/explore?$qs');
                          },
                          onExplorePromo: (p) {
                            setState(() => _selectedPromoId = p.id);
                            final dept = depts
                                .where((d) => d.id == activeDeptId)
                                .firstOrNull;
                            final promoLabel = p.level.isNotEmpty
                                ? '${p.level} · ${p.name}'
                                : p.name;
                            final params = {
                              if (dept != null) 'departmentId': dept.id,
                              if (dept != null) 'departmentName': dept.name,
                              'promotionId': p.id,
                              'promotionName': promoLabel,
                              if (facName.isNotEmpty) 'facultyName': facName,
                            };
                            final qs = params.entries
                                .map(
                                  (e) =>
                                      '${e.key}=${Uri.encodeComponent(e.value)}',
                                )
                                .join('&');
                            context.push('/library/explore?$qs');
                          },
                        ),
                        _TravauxTab(docs: docs),
                        _DebouchesTab(outlet: career),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header + tabs style Accueil / Facebook ─────────────────────────────────

class _FbHeader extends StatelessWidget {
  const _FbHeader({required this.user});

  final UserProfile? user;

  @override
  Widget build(BuildContext context) {
    final avatar = user?.avatarUrl;
    final name = user?.name ?? '';

    return Container(
      height: TimelineTokens.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: TimelineTokens.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 4),
            child: Text(
              'Ma Fac',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AkadexColors.primary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/search'),
              child: Container(
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: TimelineTokens.feedBg,
                  borderRadius:
                      BorderRadius.circular(TimelineTokens.searchRadius),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search_rounded,
                        size: 18, color: TimelineTokens.meta),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rechercher dans ma fac',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: TimelineTokens.meta,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Proposer un cours',
            onPressed: () => context.push('/contribute/course'),
            icon: const Icon(Icons.playlist_add_rounded, size: 26),
          ),
          IconButton(
            tooltip: 'Contribuer',
            onPressed: () => context.push('/contribute'),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 26),
          ),
          GestureDetector(
            onTap: () => context.push('/profile/me'),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AkadexColors.primarySoft,
                backgroundImage: avatar != null && avatar.isNotEmpty
                    ? CachedNetworkImageProvider(avatar)
                    : null,
                child: avatar != null && avatar.isNotEmpty
                    ? null
                    : Text(
                        name.isEmpty
                            ? '?'
                            : name.characters.first.toUpperCase(),
                        style: const TextStyle(
                          color: AkadexColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FbTabBar extends StatelessWidget {
  const _FbTabBar({
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final List<(String, String)> tabs;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: TimelineTokens.filterHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: TimelineTokens.divider, width: 0.5),
        ),
      ),
      alignment: Alignment.centerLeft,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final active = i == selected;
          return FilterChip(
            label: Text(tabs[i].$2),
            selected: active,
            onSelected: (_) => onSelected(i),
            showCheckmark: false,
            selectedColor: AkadexColors.primarySoft,
            labelStyle: TextStyle(
              color: active ? AkadexColors.primary : const Color(0xFF050505),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            backgroundColor: TimelineTokens.feedBg,
            side: BorderSide(
              color: active ? AkadexColors.primary : Colors.transparent,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TimelineTokens.chipRadius),
            ),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }
}

// ─── Parcours = page Facebook de la faculté ─────────────────────────────────

class _ParcoursFeed extends StatelessWidget {
  const _ParcoursFeed({
    required this.facultyName,
    required this.universityName,
    required this.departmentName,
    required this.userName,
    required this.departments,
    required this.selectedDeptId,
    required this.promotions,
    required this.selectedPromoId,
    required this.courses,
    required this.courseCount,
    required this.docCount,
    required this.onOpenTab,
    required this.onExploreDept,
    required this.onExplorePromo,
  });

  final String facultyName;
  final String universityName;
  final String departmentName;
  final String userName;
  final List<DepartmentItem> departments;
  final String? selectedDeptId;
  final List<PromotionItem> promotions;
  final String? selectedPromoId;
  final List<Course> courses;
  final int courseCount;
  final int docCount;
  final ValueChanged<int> onOpenTab;
  final ValueChanged<DepartmentItem> onExploreDept;
  final ValueChanged<PromotionItem> onExplorePromo;

  @override
  Widget build(BuildContext context) {
    final shortFac = facultyName
        .replaceFirst(
          RegExp(r'^Faculté\s+(de(s)?\s+)?', caseSensitive: false),
          '',
        )
        .trim();
    final metaLine = [
      if (universityName.isNotEmpty) universityName,
      if (departmentName.isNotEmpty) departmentName,
      '$courseCount cours',
      '$docCount docs',
    ].join(' · ');
    final followersHint = docCount > 0
        ? '$docCount ressources partagées dans ta fac'
        : 'Page de ta faculté';

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        // ── Cover (page Facebook) ──
        Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 2.7,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1A47B8),
                            Color(0xFF0F2F7A),
                            Color(0xFF163A8A),
                          ],
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomPaint(painter: _CoverPatternPainter()),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 56, 16),
                              child: Text(
                                shortFac.isEmpty
                                    ? 'Ta faculté'
                                    : 'Étudier à $shortFac',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  height: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black38,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Proposer un travail',
                        onPressed: () => context.push('/contribute'),
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Color(0xFF050505),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      facultyName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF050505),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      metaLine,
                      style: const TextStyle(
                        color: TimelineTokens.meta,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    if (userName.isNotEmpty || followersHint.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        userName.isEmpty
                            ? followersHint
                            : '$userName · $followersHint',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: TimelineTokens.meta,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: FilledButton.icon(
                              onPressed: () {
                                final dept = departments
                                    .where((d) => d.id == selectedDeptId)
                                    .firstOrNull;
                                final params = {
                                  if (dept != null) 'departmentId': dept.id,
                                  if (dept != null)
                                    'departmentName': dept.name,
                                  if (facultyName.isNotEmpty)
                                    'facultyName': facultyName,
                                };
                                final qs = params.entries
                                    .map(
                                      (e) =>
                                          '${e.key}=${Uri.encodeComponent(e.value)}',
                                    )
                                    .join('&');
                                context.push(
                                  qs.isEmpty
                                      ? '/library/explore'
                                      : '/library/explore?$qs',
                                );
                              },
                              icon: const Icon(Icons.search_rounded, size: 18),
                              label: const Text('Explorer'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AkadexColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: OutlinedButton(
                            onPressed: () => onOpenTab(2),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF050505),
                              side: const BorderSide(color: Color(0xFFCED0D4)),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Icon(Icons.more_horiz, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Départements
        _FbSection(
          title: 'Départements',
          child: departments.isEmpty
              ? const Text(
                  'Aucun département trouvé pour ta faculté.',
                  style: TextStyle(color: TimelineTokens.meta),
                )
              : SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: departments.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final d = departments[i];
                      final active = d.id == selectedDeptId;
                      return FilterChip(
                        label: Text(d.name),
                        selected: active,
                        showCheckmark: false,
                        onSelected: (_) => onExploreDept(d),
                        selectedColor: AkadexColors.primarySoft,
                        labelStyle: TextStyle(
                          color: active
                              ? AkadexColors.primary
                              : const Color(0xFF050505),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        backgroundColor: TimelineTokens.feedBg,
                        side: BorderSide(
                          color: active
                              ? AkadexColors.primary
                              : const Color(0xFFCED0D4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            TimelineTokens.chipRadius,
                          ),
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      );
                    },
                  ),
                ),
        ),
        const SizedBox(height: 8),
        // Promotions
        _FbSection(
          title: 'Promotions',
          child: promotions.isEmpty
              ? const Text(
                  'Choisis un département pour voir ses promotions.',
                  style: TextStyle(color: TimelineTokens.meta),
                )
              : SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: promotions.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final p = promotions[i];
                      final active = p.id == selectedPromoId;
                      final label = p.level.isNotEmpty
                          ? '${p.level} · ${p.name}'
                          : p.name;
                      return FilterChip(
                        label: Text(label),
                        selected: active,
                        showCheckmark: false,
                        onSelected: (_) => onExplorePromo(p),
                        selectedColor: AkadexColors.primarySoft,
                        labelStyle: TextStyle(
                          color: active
                              ? AkadexColors.primary
                              : const Color(0xFF050505),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        backgroundColor: TimelineTokens.feedBg,
                        side: BorderSide(
                          color: active
                              ? AkadexColors.primary
                              : const Color(0xFFCED0D4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            TimelineTokens.chipRadius,
                          ),
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      );
                    },
                  ),
                ),
        ),
        const SizedBox(height: 8),
        // Feed posts (cours)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Publications',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: Color(0xFF050505),
                  ),
                ),
              ),
              Text(
                '$courseCount',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AkadexColors.primary,
                ),
              ),
            ],
          ),
        ),
        if (courses.isEmpty)
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: const Text(
              'Aucune publication de cours pour l’instant.\nPropose un cours pour enrichir la page.',
              style: TextStyle(color: TimelineTokens.meta, height: 1.4),
            ),
          )
        else
          for (final c in courses.take(30)) _CoursePostCard(course: c),
      ],
    );
  }
}

class _CoverPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 8; i++) {
      canvas.drawCircle(
        Offset(size.width * (0.15 + i * 0.12), size.height * (0.2 + (i % 3) * 0.25)),
        18 + i * 4.0,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FbSection extends StatelessWidget {
  const _FbSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: Color(0xFF050505),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _CoursePostCard extends StatelessWidget {
  const _CoursePostCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final initial = course.title.trim().isEmpty
        ? 'C'
        : course.title.characters.first.toUpperCase();
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            leading: CircleAvatar(
              backgroundColor: AkadexColors.primarySoft,
              child: Text(
                initial,
                style: const TextStyle(
                  color: AkadexColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            title: Text(
              course.title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Color(0xFF050505),
              ),
            ),
            subtitle: Text(
              [
                if (course.code.isNotEmpty) course.code,
                if (course.displayTeacher.isNotEmpty) course.displayTeacher,
                if (course.targetPromotion.isNotEmpty) course.targetPromotion,
              ].join(' · '),
              style: const TextStyle(
                color: TimelineTokens.meta,
                fontSize: 12.5,
              ),
            ),
            trailing: course.needsModerationBadge
                ? ModerationChip(status: course.moderationStatus)
                : null,
            onTap: () => context.push('/library/ue/${course.id}'),
          ),
          if (course.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                course.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: Color(0xFF050505),
                ),
              ),
            ),
          const Divider(height: 1, color: TimelineTokens.divider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () =>
                        context.push('/library/ue/${course.id}'),
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: const Text('Voir le cours'),
                    style: TextButton.styleFrom(
                      foregroundColor: TimelineTokens.action,
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      final slug = LearnDomains.resolveDomainSlug(course);
                      if (slug != null && slug.isNotEmpty) {
                        context.push('/learn/domain/$slug');
                      } else {
                        context.push('/learn');
                      }
                    },
                    icon: const Icon(Icons.play_circle_outline, size: 18),
                    label: const Text('Apprendre'),
                    style: TextButton.styleFrom(
                      foregroundColor: TimelineTokens.action,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Travaux ────────────────────────────────────────────────────────────────

class _TravauxTab extends StatelessWidget {
  const _TravauxTab({required this.docs});

  static const _logoDoc = 'assets/images/logodoc.jpg';
  static const _ink = Color(0xFF1C1E21);
  static const _softBlue = Color(0xFFE8EEF8);
  static const _rowBg = Color(0xFFF7F8FA);

  final List<AcademicDocument> docs;

  @override
  Widget build(BuildContext context) {
    final categories = MaFacCategories.all;
    final counts = <String, int>{
      for (final cat in categories)
        cat.id: docs.where((d) => cat.matches(d.type)).length,
    };
    final withDocs = categories.where((c) => (counts[c.id] ?? 0) > 0).toList();
    final recent = docs.take(8).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        Container(
          color: Colors.white,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Travaux',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                docs.isEmpty
                    ? 'Examens, TP, TFC, projets, stages et mémoires de ta filière.'
                    : '${docs.length} ressource${docs.length > 1 ? 's' : ''} · '
                        '${withDocs.length} catégorie${withDocs.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: TimelineTokens.meta,
                  height: 1.35,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: FilledButton.icon(
                  onPressed: () => context.push('/contribute'),
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: const Text('Partager un travail'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AkadexColors.primary,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...categories.map((cat) {
          final n = counts[cat.id] ?? 0;
          return Container(
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _softBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(7),
                    child: Image.asset(
                      _logoDoc,
                      fit: BoxFit.contain,
                    ),
                  ),
                  title: Text(
                    cat.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  subtitle: Text(
                    n == 0
                        ? 'Aucun document'
                        : '$n document${n > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: TimelineTokens.meta,
                      fontSize: 13,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF8A8D91),
                  ),
                  onTap: () => context.push('/library/docs/${cat.id}'),
                ),
                const Divider(height: 1, color: TimelineTokens.divider),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        if (docs.isEmpty)
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _softBlue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(_logoDoc, fit: BoxFit.contain),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Aucun travail partagé pour l’instant',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sois le premier à déposer un examen, un TP ou un TFC pour ta promo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TimelineTokens.meta,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          )
        else ...[
          _FeedBlock(
            title: 'Récents',
            trailing: TextButton(
              onPressed: () => context.push('/contribute'),
              child: const Text(
                'Ajouter',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AkadexColors.primary,
                ),
              ),
            ),
            child: Column(
              children: [
                for (var i = 0; i < recent.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: TimelineTokens.divider),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _rowBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(_logoDoc, fit: BoxFit.contain),
                    ),
                    title: Text(
                      recent[i].title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    subtitle: Text(
                      '${recent[i].type.label}'
                      '${recent[i].downloads > 0 ? ' · ${recent[i].downloads} téléch.' : ''}',
                      style: const TextStyle(
                        color: TimelineTokens.meta,
                        fontSize: 13,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF8A8D91),
                    ),
                    onTap: () =>
                        context.push('/library/document/${recent[i].id}'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DebouchesTab extends StatefulWidget {
  const _DebouchesTab({required this.outlet});

  final CareerOutlet outlet;

  @override
  State<_DebouchesTab> createState() => _DebouchesTabState();
}

class _DebouchesTabState extends State<_DebouchesTab> {
  /// Une seule section ouverte à la fois.
  int? _openIndex = 0;

  static const _ink = Color(0xFF1C1E21);
  static const _softBlue = Color(0xFFE8EEF8);
  static const _cardBorder = Color(0xFFE4E6EB);

  List<_DeboucheSection> get _sections {
    final o = widget.outlet;
    return [
      _DeboucheSection(
        icon: Icons.work_outline_rounded,
        title: 'Ce que tu peux devenir',
        subtitle: 'Métiers et postes accessibles après ton parcours',
        items: o.jobs,
      ),
      _DeboucheSection(
        icon: Icons.psychology_outlined,
        title: 'Ce qu’il faut maîtriser',
        subtitle: 'Compétences à renforcer pendant tes études',
        items: o.skills,
      ),
      _DeboucheSection(
        icon: Icons.apartment_outlined,
        title: 'Où tu peux travailler',
        subtitle: 'Secteurs et types d’organisations qui recrutent',
        items: o.sectors,
      ),
      _DeboucheSection(
        icon: Icons.rocket_launch_outlined,
        title: 'Stages et opportunités',
        subtitle: 'Expériences concrètes pour démarrer ta carrière',
        items: o.opportunities,
      ),
      _DeboucheSection(
        icon: Icons.school_outlined,
        title: 'Pour aller plus loin',
        subtitle: 'Études complémentaires et certifications utiles',
        items: [
          ...o.furtherStudies,
          ...o.certifications,
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final outlet = widget.outlet;
    final quote = outlet.testimonials.isNotEmpty
        ? outlet.testimonials.first
        : '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
      children: [
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _softBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Orientation',
                  style: TextStyle(
                    color: AkadexColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                outlet.title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Des pistes claires pour ta filière : métiers, compétences, '
                'lieux de travail, stages et suites d’études.',
                style: TextStyle(
                  color: TimelineTokens.meta,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (var i = 0; i < _sections.length; i++) ...[
                _DeboucheAccordion(
                  section: _sections[i],
                  expanded: _openIndex == i,
                  onToggle: () => setState(() {
                    _openIndex = _openIndex == i ? null : i;
                  }),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        if (quote.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ce que disent les alumni',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  quote,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFF3A3B3C),
                  ),
                ),
              ],
            ),
          ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
          decoration: BoxDecoration(
            color: _softBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    outlet.internshipsHint,
                    style: const TextStyle(
                      color: Color(0xFF3A3B3C),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/alumni'),
                child: const Text(
                  'Voir Alumni',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AkadexColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeboucheSection {
  const _DeboucheSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> items;
}

class _DeboucheAccordion extends StatelessWidget {
  const _DeboucheAccordion({
    required this.section,
    required this.expanded,
    required this.onToggle,
  });

  static const _ink = Color(0xFF1C1E21);
  static const _softBlue = Color(0xFFE8EEF8);
  static const _cardBorder = Color(0xFFE4E6EB);

  final _DeboucheSection section;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: expanded ? AkadexColors.primary.withValues(alpha: 0.35) : _cardBorder,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _softBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      section.icon,
                      color: AkadexColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: _ink,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          section.subtitle,
                          style: const TextStyle(
                            color: TimelineTokens.meta,
                            fontSize: 13.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: expanded
                            ? AkadexColors.primary
                            : const Color(0xFF8A8D91),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1, color: _cardBorder),
                  const SizedBox(height: 14),
                  for (var i = 0; i < section.items.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 7),
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AkadexColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            section.items[i],
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}

class _FeedBlock extends StatelessWidget {
  const _FeedBlock({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: Color(0xFF050505),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
