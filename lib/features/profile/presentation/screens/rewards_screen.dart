import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/timeline_tokens.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/feed_subpage_scaffold.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../widgets/reward_wheel.dart';

final rewardsStatusProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('rewards/status/');
  return Map<String, dynamic>.from(res.data as Map);
});

final rewardsListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('rewards/');
  return unwrapList(res.data);
});

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  bool _spinning = false;
  String? _targetPrizeId;
  Map<String, dynamic>? _wonPrize;
  Map<String, dynamic>? _spinPayload;

  Future<void> _spin(List<Map<String, dynamic>> prizes) async {
    if (_spinning || prizes.isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _spinning = true;
      _wonPrize = null;
      _targetPrizeId = null;
      _spinPayload = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post('rewards/spin/');
      final payload = Map<String, dynamic>.from(res.data as Map);
      final prize = Map<String, dynamic>.from(payload['prize'] as Map);
      final prizeId = prize['id']?.toString() ?? '';

      setState(() {
        _targetPrizeId = prizeId;
        _spinPayload = payload;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _spinning = false;
        _targetPrizeId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    }
  }

  void _finishSpin(Map<String, dynamic> prize) {
    if (!mounted || _wonPrize != null) return;
    setState(() {
      _spinning = false;
      _wonPrize = prize;
    });
    ref.invalidate(rewardsStatusProvider);
    ref.invalidate(authStateProvider);
    HapticFeedback.heavyImpact();
    _showWinDialog(prize, _spinPayload ?? const {});
  }

  void _showWinDialog(Map<String, dynamic> prize, Map<String, dynamic> payload) {
    final feed = TimelineTokens.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: feed.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.celebration_rounded, color: feed.linkBlue),
            const SizedBox(width: 8),
            Text('Félicitations !', style: TextStyle(color: feed.ink)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              prize['name']?.toString() ?? 'Récompense',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: feed.ink,
              ),
            ),
            if ((prize['description']?.toString() ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                prize['description']!.toString(),
                style: TextStyle(color: feed.meta, height: 1.4),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '${payload['points_spent'] ?? '—'} pts utilisés · '
              '${payload['points_remaining'] ?? '—'} pts restants',
              style: TextStyle(color: feed.meta, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Super !', style: TextStyle(color: feed.linkBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    final auth = ref.watch(authStateProvider);
    final statusAsync = ref.watch(rewardsStatusProvider);
    final prizesAsync = ref.watch(rewardsListProvider);
    final badges = auth.asData?.value?.badges ?? const [];
    final pad = TimelineTokens.feedHorizontal(context);

    return FeedSubpageScaffold(
      title: 'Récompenses',
      body: statusAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(child: Text(apiErrorMessage(e))),
        data: (status) {
          final points = status['points'] as int? ?? 0;
          final unlock = status['unlock_points'] as int? ?? 100;
          final canSpin = status['can_spin'] == true && points >= unlock;
          final history = (status['history'] as List?) ?? [];
          final progress = (points / unlock).clamp(0.0, 1.0);
          final remaining = (unlock - points).clamp(0, unlock);
          final spinCost = status['spin_cost'] as int? ?? 100;
          final peerRequired = status['peer_validations_required'] as int? ?? 10;
          final highPts = status['high_tier_points'] as int? ?? 10;
          final lowPts = status['low_tier_points'] as int? ?? 5;

          return prizesAsync.when(
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error: (e, _) => Center(child: Text(apiErrorMessage(e))),
            data: (prizes) {
              final segments = wheelSegmentsFromPrizes(prizes);

              return RefreshIndicator(
                color: feed.linkBlue,
                onRefresh: () async {
                  ref.invalidate(rewardsStatusProvider);
                  ref.invalidate(rewardsListProvider);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.only(bottom: 40),
                  children: [
                    const SizedBox(height: 8),
                    FeedPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tes points',
                            style: TextStyle(
                              color: feed.meta,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$points',
                            style: TextStyle(
                              color: feed.linkBlue,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: feed.feedBg,
                              color: feed.linkBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            canSpin
                                ? 'Roue débloquée — chaque tour coûte $spinCost pts'
                                : 'Encore $remaining pts pour débloquer la roue (seuil : $unlock)',
                            style: TextStyle(
                              color: feed.meta,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(pad.left, 16, pad.right, 0),
                      child: Column(
                        children: [
                          RewardWheel(
                            segments: segments,
                            spinning: _spinning,
                            targetSegmentId: _targetPrizeId,
                            hubColor: feed.linkBlue,
                            pointerColor: feed.likeActive,
                            onSpinComplete: () {
                              if (_wonPrize != null || _targetPrizeId == null) {
                                return;
                              }
                              final prize = prizes.firstWhere(
                                (p) => p['id']?.toString() == _targetPrizeId,
                                orElse: () => prizes.first,
                              );
                              _finishSpin(prize);
                            },
                          ),
                          const SizedBox(height: 12),
                          FeedPrimaryButton(
                            label: _spinning
                                ? 'La roue tourne…'
                                : canSpin
                                    ? 'Tourner la roue ($spinCost pts)'
                                    : 'Encore $remaining pts',
                            icon: Icons.casino_rounded,
                            loading: _spinning,
                            enabled: canSpin,
                            onPressed: canSpin ? () => _spin(prizes) : null,
                          ),
                        ],
                      ),
                    ),
                    if (badges.isNotEmpty) ...[
                      const FeedSectionLabel('Tes badges'),
                      Padding(
                        padding: EdgeInsets.fromLTRB(pad.left, 0, pad.right, 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final badge in badges)
                              FeedTagChip(
                                label: badge,
                                icon: Icons.military_tech_rounded,
                              ),
                          ],
                        ),
                      ),
                    ],
                    const FeedSectionLabel('Comment gagner des points'),
                    FeedPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _EarnRow(
                            icon: Icons.upload_file_rounded,
                            title: 'Publier un document',
                            subtitle:
                                '$highPts pts (TFC, mémoire, projet tuteuré, résumé) · '
                                '$lowPts pts (examen, TD, TP, interro)',
                          ),
                          Divider(color: feed.divider, height: 24),
                          _EarnRow(
                            icon: Icons.groups_outlined,
                            title: 'Validation par ta faculté',
                            subtitle:
                                '$peerRequired étudiants de la même fac valident le doc',
                          ),
                          Divider(color: feed.divider, height: 24),
                          _EarnRow(
                            icon: Icons.admin_panel_settings_outlined,
                            title: 'Validation admin Akadex',
                            subtitle: 'Confirmation finale avant crédit des points',
                          ),
                          const SizedBox(height: 14),
                          FeedPrimaryButton(
                            label: 'Proposer une contribution',
                            icon: Icons.add_rounded,
                            onPressed: () => context.push('/contribute'),
                          ),
                          const SizedBox(height: 8),
                          FeedPrimaryButton(
                            label: 'Noter des docs de ma fac',
                            icon: Icons.fact_check_outlined,
                            onPressed: () => context.push('/peer-review'),
                          ),
                        ],
                      ),
                    ),
                    const FeedSectionLabel('Lots disponibles'),
                    for (final p in prizes)
                      FeedPanel(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: feed.softTint,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                prizeCategoryIcon(p['category']?.toString()),
                                color: feed.linkBlue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['name']?.toString() ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: feed.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    p['description']?.toString() ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: feed.meta,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DocTypeTag(
                              p['category_display']?.toString() ??
                                  p['category']?.toString() ??
                                  '',
                            ),
                          ],
                        ),
                      ),
                    if (history.isNotEmpty) ...[
                      const FeedSectionLabel('Historique des gains'),
                      for (final h in history)
                        _HistoryTile(
                          entry: Map<String, dynamic>.from(h as Map),
                        ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EarnRow extends StatelessWidget {
  const _EarnRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);

    return Row(
      children: [
        Icon(icon, color: feed.linkBlue, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: feed.ink,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: feed.meta),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    final prize = entry['prize_detail'] as Map?;
    final name = prize?['name']?.toString() ?? 'Récompense';
    final category = prize?['category']?.toString();
    final spent = entry['points_spent']?.toString() ?? '';
    final created = entry['created_at']?.toString();
    final date = created != null
        ? DateFormat('d MMM yyyy · HH:mm', 'fr_FR').format(DateTime.parse(created))
        : '';

    return FeedPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(
            prizeCategoryIcon(category),
            color: feed.linkBlue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: feed.ink,
                  ),
                ),
                if (date.isNotEmpty)
                  Text(date, style: TextStyle(fontSize: 12, color: feed.meta)),
              ],
            ),
          ),
          Text(
            '-$spent pts',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: feed.meta,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
