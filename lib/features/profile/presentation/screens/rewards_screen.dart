import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';

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
  String? _lastPrize;

  Future<void> _spin() async {
    setState(() {
      _spinning = true;
      _lastPrize = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post('rewards/spin/');
      final prize = res.data['prize'] as Map?;
      setState(() {
        _lastPrize = prize?['name']?.toString() ?? 'Récompense gagnée';
      });
      ref.invalidate(rewardsStatusProvider);
      ref.invalidate(authStateProvider);
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _spinning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(rewardsStatusProvider);
    final prizesAsync = ref.watch(rewardsListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Récompenses')),
      body: statusAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(child: Text(apiErrorMessage(e))),
        data: (status) {
          final points = status['points'] as int? ?? 0;
          final unlock = status['unlock_points'] as int? ?? 100;
          final canSpin = status['can_spin'] == true;
          final history = (status['history'] as List?) ?? [];

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$points points',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AkadexColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      canSpin
                          ? 'Tu peux tourner la roue des récompenses.'
                          : 'Encore ${unlock - points} points pour débloquer la roue (seuil : $unlock).',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.65),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: canSpin && !_spinning ? _spin : null,
                        child: _spinning
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Tourner la roue'),
                      ),
                    ),
                    if (_lastPrize != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Bravo : $_lastPrize',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AkadexColors.warning,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionTitle('Comment ça marche'),
              const SizedBox(height: 8),
              SoftCard(
                child: Text(
                  'Publie des résumés, examens, TP ou fiches. Après validation, '
                  'tu gagnes des points. Cumule-les pour gagner de l’argent, '
                  'des livres, du Premium, des accès professeurs ou des réductions.',
                  style: TextStyle(
                    height: 1.45,
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SectionTitle('Lots possibles'),
              const SizedBox(height: 8),
              prizesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: CupertinoActivityIndicator(),
                ),
                error: (e, _) => Text(apiErrorMessage(e)),
                data: (prizes) => Column(
                  children: [
                    for (final p in prizes) ...[
                      SoftCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['name']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    p['description']?.toString() ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black.withValues(alpha: 0.6),
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
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
              if (history.isNotEmpty) ...[
                const SizedBox(height: 12),
                const SectionTitle('Mes gains'),
                const SizedBox(height: 8),
                for (final h in history)
                  SoftCard(
                    child: Text(
                      (h as Map)['prize_detail']?['name']?.toString() ??
                          'Récompense',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
