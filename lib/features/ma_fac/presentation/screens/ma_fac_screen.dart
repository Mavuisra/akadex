import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/theme/timeline_tokens.dart';
import '../../../../core/widgets/shimmer_skeletons.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/mappers/mappers.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/document_type.dart';
import '../../../../domain/models/models.dart';
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
    ('enseignements', 'Enseignements'),
    ('travaux', 'Travaux'),
    ('agenda', 'Agenda'),
    ('documents', 'Documents'),
    ('debouches', 'Débouchés'),
  ];

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authStateProvider).valueOrNull;
    final coursesAsync = ref.watch(coursesProvider);
    final allCourses = coursesAsync.valueOrNull ?? const <Course>[];
    final coursesBusy = coursesAsync.isLoading && allCourses.isEmpty;
    final coursesError = coursesAsync.hasError && allCourses.isEmpty;

    // Docs / agenda : chargés dès que l’onglet en a besoin (pas au 1er paint).
    final needDocs = _tab == 0 || _tab == 2 || _tab == 4;
    final needAgenda = _tab == 0 || _tab == 3;
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
    final eventsAsync =
        needAgenda ? ref.watch(eventsProvider) : const AsyncValue.data(<CalendarEventItem>[]);
    final announcementsAsync = needAgenda
        ? ref.watch(announcementsProvider)
        : const AsyncValue.data(<UniversityAnnouncement>[]);
    final deptsAsync = ref.watch(departmentsProvider(me?.universityId));
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
    final events = eventsAsync.valueOrNull ?? const <CalendarEventItem>[];
    final announcements =
        announcementsAsync.valueOrNull ?? const <UniversityAnnouncement>[];
    final career = CareerOutlets.forProfile(me);

    final allDepts = deptsAsync.valueOrNull ?? const <DepartmentItem>[];
    final facId = me?.facultyId ?? '';
    final facLabel = (me?.faculty ?? '').toLowerCase();
    var depts = allDepts.where((d) {
      if (facId.isNotEmpty && d.facultyId == facId) return true;
      if (facLabel.isNotEmpty &&
          d.facultyName.toLowerCase().contains(facLabel.split(' ').first)) {
        return true;
      }
      return false;
    }).toList();
    if (depts.isEmpty) depts = allDepts;

    final activeDeptId = _selectedDeptId ??
        (me?.departmentId.isNotEmpty == true
            ? me!.departmentId
            : (depts.isNotEmpty ? depts.first.id : null));

    final promos = promosAsync.valueOrNull ?? const <PromotionItem>[];
    final activePromoId = _selectedPromoId ??
        (me?.promotionId.isNotEmpty == true ? me!.promotionId : null);

    final facCourses = allCourses.where((c) {
      final hay =
          '${c.faculty} ${c.department} ${c.university}'.toLowerCase();
      if (facLabel.isNotEmpty &&
          hay.contains(facLabel.split(' ').first)) {
        return true;
      }
      if (me == null) return false;
      return MaFacScope.courseMatchesUser(c, me);
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
              child: coursesBusy && (_tab == 0 || _tab == 1)
                  ? const LearnScreenSkeleton(cardCount: 2)
                  : IndexedStack(
                      index: _tab,
                      children: [
                        _ParcoursFeed(
                          facultyName: facName,
                          universityName: me?.university ?? '',
                          departments: depts,
                          selectedDeptId: activeDeptId,
                          promotions: promos,
                          selectedPromoId: activePromoId,
                          courses: scopedCourses,
                          courseCount: scopedCourses.length,
                          docCount: docs.length,
                          eventCount: events.length,
                          onSelectDept: (id) => setState(() {
                            _selectedDeptId = id;
                            _selectedPromoId = null;
                          }),
                          onSelectPromo: (id) =>
                              setState(() => _selectedPromoId = id),
                          onOpenTab: (i) => setState(() => _tab = i),
                        ),
                        _EnseignementsTab(
                          courses: scopedCourses,
                          user: me,
                        ),
                        _TravauxTab(docs: docs),
                        _AgendaTab(
                          events: events,
                          announcements: announcements,
                        ),
                        _DocumentsTab(docs: docs),
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

// ─── Parcours (feed fac) ────────────────────────────────────────────────────

class _ParcoursFeed extends StatelessWidget {
  const _ParcoursFeed({
    required this.facultyName,
    required this.universityName,
    required this.departments,
    required this.selectedDeptId,
    required this.promotions,
    required this.selectedPromoId,
    required this.courses,
    required this.courseCount,
    required this.docCount,
    required this.eventCount,
    required this.onSelectDept,
    required this.onSelectPromo,
    required this.onOpenTab,
  });

  final String facultyName;
  final String universityName;
  final List<DepartmentItem> departments;
  final String? selectedDeptId;
  final List<PromotionItem> promotions;
  final String? selectedPromoId;
  final List<Course> courses;
  final int courseCount;
  final int docCount;
  final int eventCount;
  final ValueChanged<String> onSelectDept;
  final ValueChanged<String> onSelectPromo;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        // Bannière fac (pas de profil perso)
        Container(
          color: Colors.white,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
              if (universityName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  universityName,
                  style: const TextStyle(
                    color: TimelineTokens.meta,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Stats
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              _StatCell(value: '$courseCount', label: 'Cours'),
              _StatCell(value: '$docCount', label: 'Documents'),
              _StatCell(value: '$eventCount', label: 'Agenda'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Accès rapide (sans Travaux & TFC)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Accès rapide',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: Color(0xFF050505),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickChip(
                    label: 'Horaires & UE',
                    icon: Icons.schedule_outlined,
                    onTap: () => onOpenTab(1),
                  ),
                  _QuickChip(
                    label: 'Examens / Annonces',
                    icon: Icons.campaign_outlined,
                    onTap: () => onOpenTab(3),
                  ),
                  _QuickChip(
                    label: 'Débouchés',
                    icon: Icons.work_outline,
                    onTap: () => onOpenTab(5),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Départements
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Départements',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: Color(0xFF050505),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (departments.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    'Aucun département trouvé pour ta faculté.',
                    style: TextStyle(color: TimelineTokens.meta),
                  ),
                )
              else
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: departments.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final d = departments[i];
                      final active = d.id == selectedDeptId;
                      return FilterChip(
                        label: Text(d.name),
                        selected: active,
                        showCheckmark: false,
                        onSelected: (_) => onSelectDept(d.id),
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
              const SizedBox(height: 8),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Promotions
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Promotions',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: Color(0xFF050505),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (promotions.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    'Choisis un département pour voir ses promotions.',
                    style: TextStyle(color: TimelineTokens.meta),
                  ),
                )
              else
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
                        onSelected: (_) => onSelectPromo(p.id),
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
              const SizedBox(height: 8),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Cours de la promotion
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Cours de la promotion',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: Color(0xFF050505),
                  ),
                ),
              ),
              Text(
                '${courses.length}',
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
              'Aucun cours pour cette sélection.',
              style: TextStyle(color: TimelineTokens.meta),
            ),
          )
        else
          for (final c in courses.take(30))
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(
                      c.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF050505),
                      ),
                    ),
                    subtitle: Text(
                      [
                        c.code,
                        if (c.displayTeacher.isNotEmpty) c.displayTeacher,
                        if (c.targetPromotion.isNotEmpty) c.targetPromotion,
                      ].join(' · '),
                      style: const TextStyle(
                        color: TimelineTokens.meta,
                        fontSize: 13,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: TimelineTokens.meta,
                    ),
                    onTap: () => context.push('/library/course/${c.id}'),
                  ),
                  const Divider(height: 1, color: TimelineTokens.divider),
                ],
              ),
            ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AkadexColors.primary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: TimelineTokens.meta,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AkadexColors.primary),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AkadexColors.primarySoft,
      side: BorderSide.none,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AkadexColors.primary,
        fontSize: 13,
      ),
    );
  }
}

// ─── Autres onglets (conservés, style feed) ─────────────────────────────────

class _EnseignementsTab extends StatelessWidget {
  const _EnseignementsTab({required this.courses, required this.user});

  final List<Course> courses;
  final UserProfile? user;

  @override
  Widget build(BuildContext context) {
    final teachers = <String>{
      for (final c in courses)
        if (c.displayTeacher.isNotEmpty) c.displayTeacher,
    }.toList();

    final byUe = <String, List<Course>>{};
    for (final c in courses) {
      final key = c.semester.isNotEmpty
          ? c.semester
          : (c.targetPromotion.isNotEmpty ? c.targetPromotion : 'UE générale');
      byUe.putIfAbsent(key, () => []).add(c);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        _FeedBlock(
          title: 'Synthèse',
          child: Text(
            '${courses.length} cours · ${byUe.length} unité(s) · ${teachers.length} enseignant(s)',
            style: const TextStyle(color: TimelineTokens.meta),
          ),
        ),
        const SizedBox(height: 8),
        _FeedBlock(
          title: 'Unités d’enseignement',
          child: byUe.isEmpty
              ? const Text(
                  'Aucune UE pour cette sélection.',
                  style: TextStyle(color: TimelineTokens.meta),
                )
              : Column(
                  children: [
                    for (final e in byUe.entries) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          e.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AkadexColors.primary,
                          ),
                        ),
                      ),
                      for (final c in e.value)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            c.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(c.displayTeacher),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () =>
                              context.push('/library/course/${c.id}'),
                        ),
                      const Divider(),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 8),
        _FeedBlock(
          title: 'Horaires de cours',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Emploi du temps synchronisé avec le calendrier de ta faculté.',
                style: TextStyle(color: TimelineTokens.meta, height: 1.35),
              ),
              TextButton.icon(
                onPressed: () => context.push('/calendar'),
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('Ouvrir le calendrier'),
              ),
            ],
          ),
        ),
        if (teachers.isNotEmpty) ...[
          const SizedBox(height: 8),
          _FeedBlock(
            title: 'Professeurs responsables',
            child: Column(
              children: [
                for (final t in teachers)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AkadexColors.primarySoft,
                      child: Icon(Icons.person_outline,
                          color: AkadexColors.primary),
                    ),
                    title: Text(
                      t,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TravauxTab extends StatelessWidget {
  const _TravauxTab({required this.docs});

  final List<AcademicDocument> docs;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        _FeedBlock(
          title: 'Travaux académiques',
          child: const Text(
            'Examens, TP, TFC, projets tuteurés, mémoires — PDF de ta filière.',
            style: TextStyle(color: TimelineTokens.meta, height: 1.35),
          ),
        ),
        const SizedBox(height: 8),
        for (final cat in MaFacCategories.all)
          Container(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 1),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: cat.colors.first,
                child: Icon(cat.icon, color: Colors.white, size: 20),
              ),
              title: Text(
                cat.label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${docs.where((d) => cat.matches(d.type)).length} document(s)',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/library/docs/${cat.id}'),
            ),
          ),
      ],
    );
  }
}

class _AgendaTab extends StatelessWidget {
  const _AgendaTab({
    required this.events,
    required this.announcements,
  });

  final List<CalendarEventItem> events;
  final List<UniversityAnnouncement> announcements;

  @override
  Widget build(BuildContext context) {
    final exams = events
        .where((e) =>
            e.eventType.toLowerCase().contains('exam') ||
            e.title.toLowerCase().contains('examen'))
        .toList();
    final other = events.where((e) => !exams.contains(e)).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        _FeedBlock(
          title: 'Annonces de la faculté',
          child: announcements.isEmpty
              ? const Text('Aucune annonce.',
                  style: TextStyle(color: TimelineTokens.meta))
              : Column(
                  children: [
                    for (final a in announcements.take(6))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.campaign_outlined,
                            color: AkadexColors.primary),
                        title: Text(a.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: a.body.isEmpty
                            ? null
                            : Text(a.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 8),
        _FeedBlock(
          title: 'Examens programmés',
          child: exams.isEmpty
              ? const Text('Aucun examen planifié.',
                  style: TextStyle(color: TimelineTokens.meta))
              : Column(
                  children: [
                    for (final e in exams)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.quiz_outlined,
                            color: AkadexColors.primary),
                        title: Text(e.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(e.eventType),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 8),
        _FeedBlock(
          title: 'Événements académiques',
          child: other.isEmpty
              ? const Text('Pas d’événement.',
                  style: TextStyle(color: TimelineTokens.meta))
              : Column(
                  children: [
                    for (final e in other.take(8))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_outlined,
                            color: AkadexColors.primary),
                        title: Text(e.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          [
                            e.eventType,
                            if (e.location.isNotEmpty) e.location,
                          ].join(' · '),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 8),
        _FeedBlock(
          title: 'Résultats publiés',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Les résultats s’afficheront ici dès publication.',
                style: TextStyle(color: TimelineTokens.meta, height: 1.35),
              ),
              TextButton(
                onPressed: () => context.push('/calendar'),
                child: const Text(
                  'Calendrier complet',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
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

class _DocumentsTab extends StatelessWidget {
  const _DocumentsTab({required this.docs});

  final List<AcademicDocument> docs;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        _FeedBlock(
          title: 'Documents pédagogiques',
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
          child: Text(
            '${docs.length} ressource(s)',
            style: const TextStyle(color: TimelineTokens.meta),
          ),
        ),
        if (docs.isEmpty)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Aucun document pour ta filière.',
              style: TextStyle(color: TimelineTokens.meta),
            ),
          )
        else
          for (final d in docs)
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AkadexColors.primarySoft,
                      child: Icon(Icons.picture_as_pdf_outlined,
                          color: AkadexColors.primary),
                    ),
                    title: Text(
                      d.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('${d.type.label} · ${d.downloads} téléch.'),
                    trailing: const Icon(Icons.download_outlined),
                    onTap: () => context.push('/library/document/${d.id}'),
                  ),
                  const Divider(height: 1, color: TimelineTokens.divider),
                ],
              ),
            ),
      ],
    );
  }
}

class _DebouchesTab extends StatelessWidget {
  const _DebouchesTab({required this.outlet});

  final CareerOutlet outlet;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        _FeedBlock(
          title: 'Débouchés et métiers',
          child: Text(
            outlet.title,
            style: const TextStyle(
              color: AkadexColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final block in [
          ('Métiers accessibles', outlet.jobs),
          ('Compétences attendues', outlet.skills),
          ('Secteurs d’activité', outlet.sectors),
          ('Opportunités', outlet.opportunities),
          ('Poursuite d’études', outlet.furtherStudies),
          ('Certifications', outlet.certifications),
          ('Témoignages alumni', outlet.testimonials),
        ]) ...[
          _FeedBlock(
            title: block.$1,
            child: Column(
              children: [
                for (final item in block.$2)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 18, color: AkadexColors.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        _FeedBlock(
          title: 'Stages & emplois',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                outlet.internshipsHint,
                style: const TextStyle(
                  color: TimelineTokens.meta,
                  height: 1.35,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/alumni'),
                child: const Text(
                  'Parcours Alumni',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
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
