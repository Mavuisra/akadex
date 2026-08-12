import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/timeline_tokens.dart';
import '../../../../core/widgets/notification_icon_button.dart';
import '../../../../core/widgets/shimmer_skeletons.dart';
import '../../../../core/widgets/timeline_post_card.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/mappers/mappers.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/models.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  TimelineQuery _query = TimelineQuery.empty;
  String? _uniLabel;
  String? _facLabel;
  String? _deptLabel;
  String? _promoLabel;
  String? _tagLabel;
  String? _yearLabel;
  String? _lastPersonalizedUserId;
  bool _forYouMode = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(notificationsProvider);
    });
  }

  static const _kinds = <(String, String)>[
    ('all', 'Pour toi'),
    ('exam', 'Examens'),
    ('tp', 'TP / TD'),
    ('summary', 'Résumés'),
    ('notes', 'Notes'),
    ('support', 'Supports'),
    ('rapport', 'Rapports de stage'),
    ('projet_tutore', 'Projets tuteurés'),
    ('tfc', 'TFC'),
    ('memoire', 'Mémoires'),
    ('discussion', 'Discussions'),
    ('question', 'Questions'),
  ];

  static const _domains = [
    'Informatique',
    'Réseaux',
    'Mathématiques',
    'Gestion',
    'Pédagogie',
  ];

  static const _subjects = [
    'POO',
    'Algorithmique',
    'Bases de données',
    'Compta',
    'Probabilités',
  ];

  static const _years = ['2026', '2025', '2024', '2023'];

  /// Applique fac / département / promotion de l’utilisateur connecté.
  void _applyUserAcademicScope(UserProfile? me, {String? kind}) {
    final keepKind = kind ?? (_forYouMode ? null : _query.kind);
    if (me == null) {
      _query = TimelineQuery(kind: keepKind);
      _uniLabel = null;
      _facLabel = null;
      _deptLabel = null;
      _promoLabel = null;
      _lastPersonalizedUserId = null;
      return;
    }

    final uniId = me.universityId.trim();
    final facId = me.facultyId.trim();
    final deptId = me.departmentId.trim();
    final promoId = me.promotionId.trim();

    _query = TimelineQuery(
      kind: keepKind,
      universityId: uniId.isEmpty ? null : uniId,
      facultyId: facId.isEmpty ? null : facId,
      departmentId: deptId.isEmpty ? null : deptId,
      promotionId: promoId.isEmpty ? null : promoId,
      tag: _query.tag,
      year: _query.year,
    );
    _uniLabel = me.university.trim().isEmpty ? null : me.university.trim();
    _facLabel = me.faculty.trim().isEmpty ? null : me.faculty.trim();
    _deptLabel = me.department.trim().isEmpty ? null : me.department.trim();
    _promoLabel = () {
      final p = me.promotion.trim();
      final lvl = me.level.trim();
      if (p.isEmpty && lvl.isEmpty) return null;
      if (p.isEmpty) return lvl;
      if (lvl.isEmpty || p.toLowerCase().contains(lvl.toLowerCase())) return p;
      return '$p ($lvl)';
    }();
    _lastPersonalizedUserId = me.id;
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authStateProvider).valueOrNull;

    // Personnalise « Pour toi » dès que le profil est dispo / change.
    if (_forYouMode && me?.id != _lastPersonalizedUserId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _applyUserAcademicScope(me));
      });
    }

    final postsAsync = ref.watch(timelinePostsProvider(_query));
    final kindSelected = _forYouMode ? 'all' : (_query.kind ?? 'all');

    return Scaffold(
      backgroundColor: TimelineTokens.of(context).feedBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TimelineHeader(user: me),
            _KindFilterBar(
              filters: _kinds,
              selected: kindSelected,
              onSelected: (v) {
                setState(() {
                  if (v == 'all') {
                    _forYouMode = true;
                    _applyUserAcademicScope(me);
                  } else {
                    _forYouMode = false;
                    // Garde le cadre académique de l’étudiant, change seulement le type.
                    _applyUserAcademicScope(me, kind: v);
                  }
                });
              },
            ),
            _AcademicFilterBar(
              uniLabel: _uniLabel,
              facLabel: _facLabel,
              deptLabel: _deptLabel,
              promoLabel: _promoLabel,
              tagLabel: _tagLabel,
              yearLabel: _yearLabel,
              onPickUniversity: () => _pickUniversity(),
              onPickFaculty: () => _pickFaculty(),
              onPickDepartment: () => _pickDepartment(),
              onPickPromotion: () => _pickPromotion(),
              onPickDomain: () => _pickChipList(
                title: 'Domaine',
                items: _domains,
                onPick: (v) => setState(() {
                  _tagLabel = v;
                  _query = _query.copyWith(tag: v);
                }),
              ),
              onPickSubject: () => _pickChipList(
                title: 'Matière',
                items: _subjects,
                onPick: (v) => setState(() {
                  _tagLabel = v;
                  _query = _query.copyWith(tag: v);
                }),
              ),
              onPickYear: () => _pickChipList(
                title: 'Année académique',
                items: _years,
                onPick: (v) => setState(() {
                  _yearLabel = v;
                  _query = _query.copyWith(year: v);
                }),
              ),
              onClear: () => setState(() {
                _tagLabel = null;
                _yearLabel = null;
                if (_forYouMode) {
                  // Repart sur le parcours de l’utilisateur connecté.
                  _applyUserAcademicScope(me);
                } else {
                  final kind = _query.kind;
                  _query = TimelineQuery(kind: kind);
                  _uniLabel = null;
                  _facLabel = null;
                  _deptLabel = null;
                  _promoLabel = null;
                }
              }),
            ),
            Expanded(
              child: RefreshIndicator(
                color: TimelineTokens.of(context).linkBlue,
                onRefresh: () async {
                  ref.invalidate(timelinePostsProvider(_query));
                  await ref.read(timelinePostsProvider(_query).future);
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _ComposerCard(
                        user: me,
                        onTap: () {
                          if (me == null) {
                            context.push('/login');
                            return;
                          }
                          context.push('/community/publish');
                        },
                      ),
                    ),
                    postsAsync.when(
                      loading: () => const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(0, 4, 0, 100),
                          child: PostFeedSkeleton(count: 4),
                        ),
                      ),
                      error: (e, _) => SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Text(
                                apiErrorMessage(e),
                                textAlign: TextAlign.center,
                              ),
                              TextButton(
                                onPressed: () => ref
                                    .invalidate(timelinePostsProvider(_query)),
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      data: (posts) {
                        if (posts.isEmpty) {
                          final scopeHint = [
                            ?_facLabel,
                            ?_deptLabel,
                            ?_promoLabel,
                          ].join(' · ');
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(28),
                                child: Text(
                                  _forYouMode && scopeHint.isNotEmpty
                                      ? 'Aucune ressource pour ton parcours.\n$scopeHint\n\nPartage un TP, un résumé ou un examen corrigé.'
                                      : 'Aucune publication pour ces filtres.\nPartage un TP, un résumé ou un examen corrigé.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: TimelineTokens.of(context).meta,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 110),
                          sliver: SliverList.builder(
                            itemCount: posts.length,
                            itemBuilder: (_, i) {
                              return TimelinePostCard(post: posts[i]);
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickUniversity() async {
    final list = await ref.read(universitiesProvider.future);
    if (!mounted) return;
    final picked = await _showPickerSheet<UniversityItem>(
      title: 'Université',
      items: list,
      labelOf: (u) => u.name,
    );
    if (picked == null) return;
    setState(() {
      _uniLabel = picked.name;
      _facLabel = null;
      _deptLabel = null;
      _promoLabel = null;
      _query = _query.copyWith(
        universityId: picked.id,
        clearFaculty: true,
        clearDepartment: true,
        clearPromotion: true,
      );
    });
  }

  Future<void> _pickFaculty() async {
    final list = await ref.read(
      facultiesProvider(_query.universityId).future,
    );
    if (!mounted) return;
    final picked = await _showPickerSheet<FacultyItem>(
      title: 'Faculté',
      items: list,
      labelOf: (f) => f.name,
    );
    if (picked == null) return;
    setState(() {
      _facLabel = picked.name;
      _deptLabel = null;
      _promoLabel = null;
      _query = _query.copyWith(
        facultyId: picked.id,
        universityId: picked.universityId.isNotEmpty
            ? picked.universityId
            : _query.universityId,
        clearDepartment: true,
        clearPromotion: true,
      );
    });
  }

  Future<void> _pickDepartment() async {
    final list = await ref.read(
      departmentsProvider(_query.universityId).future,
    );
    if (!mounted) return;
    var filtered = list;
    if (_query.facultyId != null) {
      filtered = list
          .where((d) => d.facultyId == _query.facultyId || d.facultyId.isEmpty)
          .toList();
      if (filtered.isEmpty) filtered = list;
    }
    final picked = await _showPickerSheet<DepartmentItem>(
      title: 'Département / Filière',
      items: filtered,
      labelOf: (d) => d.name,
    );
    if (picked == null) return;
    setState(() {
      _deptLabel = picked.name;
      _promoLabel = null;
      _query = _query.copyWith(
        departmentId: picked.id,
        clearPromotion: true,
      );
    });
  }

  Future<void> _pickPromotion() async {
    final list = await ref.read(
      promotionsProvider(_query.departmentId).future,
    );
    if (!mounted) return;
    final picked = await _showPickerSheet<PromotionItem>(
      title: 'Promotion',
      items: list,
      labelOf: (p) => p.level.isNotEmpty ? '${p.name} (${p.level})' : p.name,
    );
    if (picked == null) return;
    setState(() {
      _promoLabel = picked.name;
      _query = _query.copyWith(promotionId: picked.id);
    });
  }

  Future<void> _pickChipList({
    required String title,
    required List<String> items,
    required ValueChanged<String> onPick,
  }) async {
    final picked = await _showPickerSheet<String>(
      title: title,
      items: items,
      labelOf: (s) => s,
    );
    if (picked != null) onPick(picked);
  }

  Future<T?> _showPickerSheet<T>({
    required String title,
    required List<T> items,
    required String Function(T) labelOf,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      backgroundColor: TimelineTokens.of(context).cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return ListTile(
                      title: Text(labelOf(item)),
                      onTap: () => Navigator.pop(ctx, item),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimelineHeader extends StatelessWidget {
  const _TimelineHeader({this.user});

  // Reserved for future personalization (kept for call-site stability).
  // ignore: unused_field
  final UserProfile? user;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: TimelineTokens.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: TimelineTokens.of(context).cardBg,
        border: Border(
          bottom: BorderSide(color: TimelineTokens.of(context).divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 6),
            child: Text(
              'Akadex',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: TimelineTokens.of(context).linkBlue,
                letterSpacing: -0.6,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                height: 36,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/search'),
                  icon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: TimelineTokens.of(context).meta,
                  ),
                  label: Text(
                    'Rechercher',
                    style: TextStyle(
                      color: TimelineTokens.of(context).ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: TimelineTokens.of(context).feedBg,
                    side: BorderSide(color: TimelineTokens.of(context).divider),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(TimelineTokens.searchRadius),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ),
          ),
          const NotificationIconButton(),
          IconButton(
            tooltip: 'Messages',
            onPressed: () => context.push('/messages'),
            icon: const Icon(Icons.messenger_outline_rounded, size: 24),
          ),
        ],
      ),
    );
  }
}

class _KindFilterBar extends StatelessWidget {
  const _KindFilterBar({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<(String, String)> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: TimelineTokens.filterHeight,
      color: TimelineTokens.of(context).cardBg,
      alignment: Alignment.centerLeft,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final f = filters[i];
          final active = f.$1 == selected;
          return FilterChip(
            label: Text(f.$2),
            selected: active,
            onSelected: (_) => onSelected(f.$1),
            selectedColor: TimelineTokens.of(context).softTint,
            checkmarkColor: TimelineTokens.of(context).linkBlue,
            labelStyle: TextStyle(
              color: active ? TimelineTokens.of(context).linkBlue : TimelineTokens.of(context).ink,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            backgroundColor: TimelineTokens.of(context).feedBg,
            side: TimelineTokens.tabBorderSide,
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

class _AcademicFilterBar extends StatelessWidget {
  const _AcademicFilterBar({
    required this.onPickUniversity,
    required this.onPickFaculty,
    required this.onPickDepartment,
    required this.onPickPromotion,
    required this.onPickDomain,
    required this.onPickSubject,
    required this.onPickYear,
    required this.onClear,
    this.uniLabel,
    this.facLabel,
    this.deptLabel,
    this.promoLabel,
    this.tagLabel,
    this.yearLabel,
  });

  final VoidCallback onPickUniversity;
  final VoidCallback onPickFaculty;
  final VoidCallback onPickDepartment;
  final VoidCallback onPickPromotion;
  final VoidCallback onPickDomain;
  final VoidCallback onPickSubject;
  final VoidCallback onPickYear;
  final VoidCallback onClear;
  final String? uniLabel;
  final String? facLabel;
  final String? deptLabel;
  final String? promoLabel;
  final String? tagLabel;
  final String? yearLabel;

  @override
  Widget build(BuildContext context) {
    final chips = <(String, VoidCallback, bool)>[
      (uniLabel ?? 'Université', onPickUniversity, uniLabel != null),
      (facLabel ?? 'Faculté', onPickFaculty, facLabel != null),
      (deptLabel ?? 'Département', onPickDepartment, deptLabel != null),
      (promoLabel ?? 'Promotion', onPickPromotion, promoLabel != null),
      (tagLabel ?? 'Domaine', onPickDomain, tagLabel != null),
      ('Matière', onPickSubject, false),
      (yearLabel ?? 'Année', onPickYear, yearLabel != null),
    ];

    return Container(
      height: TimelineTokens.filterHeight,
      color: TimelineTokens.of(context).cardBg,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              itemCount: chips.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final c = chips[i];
                return ActionChip(
                  label: Text(c.$1),
                  onPressed: c.$2,
                  backgroundColor:
                      c.$3 ? TimelineTokens.of(context).softTint : TimelineTokens.of(context).feedBg,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.$3
                        ? TimelineTokens.of(context).linkBlue
                        : TimelineTokens.of(context).ink,
                  ),
                  side: TimelineTokens.tabBorderSide,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(TimelineTokens.chipRadius),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              },
            ),
          ),
          IconButton(
            tooltip: 'Réinitialiser les filtres',
            onPressed: onClear,
            icon: const Icon(Icons.filter_alt_off_outlined, size: 20),
          ),
        ],
      ),
    );
  }
}

class _ComposerCard extends StatelessWidget {
  const _ComposerCard({required this.user, required this.onTap});

  final UserProfile? user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = user?.avatarUrl;
    final name = user?.name ?? '';
    final pad = TimelineTokens.feedHorizontal(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(pad.left, 8, pad.right, 8),
      child: Material(
        color: TimelineTokens.of(context).cardBg,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: TimelineTokens.of(context).softTint,
                  backgroundImage: avatar != null && avatar.isNotEmpty
                      ? CachedNetworkImageProvider(avatar)
                      : null,
                  child: avatar != null && avatar.isNotEmpty
                      ? null
                      : Text(
                          name.isEmpty
                              ? '?'
                              : name.characters.first.toUpperCase(),
                          style: TextStyle(
                            color: TimelineTokens.of(context).linkBlue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: TimelineTokens.of(context).feedBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Quoi de neuf ? Partage un TP, résumé, examen…',
                      style: TextStyle(
                        color: TimelineTokens.of(context).meta,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
