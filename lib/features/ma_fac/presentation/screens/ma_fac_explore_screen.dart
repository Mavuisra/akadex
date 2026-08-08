import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/timeline_tokens.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/moderation_chip.dart';
import '../../../../core/widgets/shimmer_skeletons.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/models.dart';

/// Recherche dans un département / une promotion (depuis Ma Fac).
class MaFacExploreScreen extends ConsumerStatefulWidget {
  const MaFacExploreScreen({
    super.key,
    this.departmentId = '',
    this.departmentName = '',
    this.promotionId = '',
    this.promotionName = '',
    this.facultyName = '',
  });

  final String departmentId;
  final String departmentName;
  final String promotionId;
  final String promotionName;
  final String facultyName;

  @override
  ConsumerState<MaFacExploreScreen> createState() => _MaFacExploreScreenState();
}

class _MaFacExploreScreenState extends ConsumerState<MaFacExploreScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Course> _filter(List<Course> all) {
    var list = all.where((c) => !c.code.startsWith('AKX-')).toList();

    final dept = widget.departmentName.trim().toLowerCase();
    if (dept.isNotEmpty) {
      final token = dept.split(RegExp(r'\s+')).firstWhere(
            (t) => t.length > 2,
            orElse: () => dept,
          );
      final byDept = list
          .where((c) => c.department.toLowerCase().contains(token))
          .toList();
      if (byDept.isNotEmpty) list = byDept;
    }

    final promo = widget.promotionName.trim().toLowerCase();
    if (promo.isNotEmpty) {
      final byPromo = list.where((c) {
        final h =
            '${c.semester} ${c.targetPromotion} ${c.levelLabel}'.toLowerCase();
        return h.contains(promo) ||
            promo.split(RegExp(r'[·\s]+')).any((t) => t.length > 1 && h.contains(t));
      }).toList();
      if (byPromo.isNotEmpty) list = byPromo;
    }

    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) {
        final hay = [
          c.title,
          c.code,
          c.displayTeacher,
          c.department,
          c.description,
        ].join(' ').toLowerCase();
        return hay.contains(q);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);
    final feed = TimelineTokens.of(context);
    final scopeParts = [
      if (widget.facultyName.isNotEmpty) widget.facultyName,
      if (widget.departmentName.isNotEmpty) widget.departmentName,
      if (widget.promotionName.isNotEmpty) widget.promotionName,
    ];

    return Scaffold(
      backgroundColor: feed.feedBg,
      appBar: AppBar(
        backgroundColor: feed.cardBg,
        foregroundColor: feed.ink,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.promotionName.isNotEmpty
              ? 'Promo ${widget.promotionName}'
              : (widget.departmentName.isNotEmpty
                  ? widget.departmentName
                  : 'Recherche Ma Fac'),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: feed.ink,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: feed.cardBg,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (scopeParts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      scopeParts.join(' · '),
                      style: TextStyle(
                        color: feed.meta,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                TextField(
                  controller: _controller,
                  style: TextStyle(color: feed.ink),
                  textInputAction: TextInputAction.search,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un cours, un code, un titulaire…',
                    hintStyle: TextStyle(color: feed.meta),
                    prefixIcon: Icon(Icons.search_rounded, color: feed.meta),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                            icon: Icon(Icons.close_rounded, color: feed.meta),
                          ),
                    filled: true,
                    fillColor: feed.feedBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: coursesAsync.when(
              loading: () => const LearnScreenSkeleton(cardCount: 4),
              error: (e, _) => Center(
                child: Text(
                  apiErrorMessage(e),
                  style: TextStyle(color: feed.ink),
                ),
              ),
              data: (all) {
                final courses = _filter(all);
                if (courses.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _query.isEmpty
                            ? 'Aucun cours pour cette sélection.\nPropose un cours manquant.'
                            : 'Aucun résultat pour « $_query ».',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: feed.meta,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                  itemCount: courses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final c = courses[i];
                    return SoftCard(
                      onTap: () => context.push('/library/ue/${c.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  c.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: feed.ink,
                                  ),
                                ),
                              ),
                              if (c.needsModerationBadge)
                                ModerationChip(status: c.moderationStatus),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              c.code,
                              if (c.displayTeacher.isNotEmpty) c.displayTeacher,
                              if (c.targetPromotion.isNotEmpty)
                                c.targetPromotion,
                              if (c.department.isNotEmpty) c.department,
                            ].where((e) => e.isNotEmpty).join(' · '),
                            style: TextStyle(
                              color: feed.meta,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/contribute/course'),
        icon: const Icon(Icons.playlist_add_rounded),
        label: const Text('Proposer un cours'),
      ),
    );
  }
}
