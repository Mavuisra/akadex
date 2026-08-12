import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/timeline_tokens.dart';
import '../../../../core/widgets/feed_subpage_scaffold.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import 'rewards_screen.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = TimelineTokens.of(context);
    final auth = ref.watch(authStateProvider);
    final rewardsAsync = ref.watch(rewardsStatusProvider);
    final pad = TimelineTokens.feedHorizontal(context);

    return FeedSubpageScaffold(
      title: 'Tableau de bord',
      body: auth.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(child: Text(apiErrorMessage(e))),
        data: (user) {
          if (user == null) {
            return FeedEmptyState(
              icon: Icons.person_outline_rounded,
              title: 'Non connecté',
              message: 'Connecte-toi pour voir ton tableau de bord.',
              actionLabel: 'Se connecter',
              onAction: () => context.go('/login'),
            );
          }

          final rewards = rewardsAsync.asData?.value;
          final points = rewards?['points'] as int? ?? user.reputation;
          final unlock = rewards?['unlock_points'] as int? ?? 100;
          final canSpin = rewards?['can_spin'] == true;
          final progress = (points / unlock).clamp(0.0, 1.0);

          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              const SizedBox(height: 8),
              FeedPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour, ${user.firstName.isNotEmpty ? user.firstName : user.name}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: feed.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.faculty.isNotEmpty ? user.faculty : user.university,
                      style: TextStyle(color: feed.meta, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$points pts',
                      style: TextStyle(
                        color: feed.linkBlue,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      canSpin
                          ? 'Roue débloquée — tente ta chance !'
                          : 'Encore ${unlock - points} pts pour la roue',
                      style: TextStyle(color: feed.meta, fontSize: 13),
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
                    if (canSpin) ...[
                      const SizedBox(height: 14),
                      FeedPrimaryButton(
                        label: 'Tourner la roue',
                        icon: Icons.casino_rounded,
                        onPressed: () => context.push('/rewards'),
                      ),
                    ],
                  ],
                ),
              ),
              const FeedSectionLabel('Accès rapide'),
              Padding(
                padding: EdgeInsets.fromLTRB(pad.left, 0, pad.right, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _QuickChip(
                      icon: Icons.upload_file_rounded,
                      label: 'Contribuer',
                      onTap: () => context.push('/contribute'),
                    ),
                    _QuickChip(
                      icon: Icons.card_giftcard_rounded,
                      label: 'Récompenses',
                      onTap: () => context.push('/rewards'),
                    ),
                    _QuickChip(
                      icon: Icons.explore_outlined,
                      label: 'Apprendre',
                      onTap: () => context.go('/learn'),
                    ),
                    _QuickChip(
                      icon: Icons.fact_check_outlined,
                      label: 'Noter docs',
                      onTap: () => context.push('/peer-review'),
                    ),
                    _QuickChip(
                      icon: Icons.bookmark_border_rounded,
                      label: 'Enregistrements',
                      onTap: () => context.push('/saved'),
                    ),
                  ],
                ),
              ),
              if (user.badges.isNotEmpty) ...[
                const FeedSectionLabel('Badges'),
                Padding(
                  padding: EdgeInsets.fromLTRB(pad.left, 0, pad.right, 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final badge in user.badges)
                        FeedTagChip(label: badge),
                    ],
                  ),
                ),
              ],
              const FeedSectionLabel('Activité'),
              _StatRow(
                icon: Icons.star_rounded,
                label: 'Points de réputation',
                value: '$points',
              ),
              _StatRow(
                icon: Icons.description_outlined,
                label: 'Contributions validées',
                value: '${user.contributions}',
              ),
              _StatRow(
                icon: Icons.people_outline_rounded,
                label: 'Abonnements',
                value: '${user.followingCount}',
              ),
              _StatRow(
                icon: Icons.article_outlined,
                label: 'Publications',
                value: '${user.postsCount}',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);

    return Material(
      color: feed.cardBg,
      borderRadius: BorderRadius.circular(TimelineTokens.chipRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TimelineTokens.chipRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TimelineTokens.chipRadius),
            border: Border.all(color: feed.divider, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: feed.linkBlue),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: feed.ink,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);

    return FeedPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: feed.meta, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: feed.ink, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: feed.ink,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
