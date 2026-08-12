import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/timeline_tokens.dart';
import '../../../../core/widgets/feed_subpage_scaffold.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/mappers/mappers.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/models.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = TimelineTokens.of(context);
    final followingAsync = ref.watch(followingAlumniProvider);

    return FeedSubpageScaffold(
      title: 'Ami(e)s',
      actions: [
        TextButton(
          onPressed: () => context.go('/alumni'),
          child: Text('Découvrir', style: TextStyle(color: feed.linkBlue)),
        ),
      ],
      body: followingAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  apiErrorMessage(e),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: feed.ink),
                ),
                const SizedBox(height: 12),
                FeedPrimaryButton(
                  label: 'Réessayer',
                  onPressed: () => ref.invalidate(followingAlumniProvider),
                ),
              ],
            ),
          ),
        ),
        data: (following) {
          if (following.isEmpty) {
            return FeedEmptyState(
              icon: Icons.people_outline_rounded,
              title: 'Aucun abonnement',
              message: 'Suis des alumni pour suivre leurs publications et conseils.',
              actionLabel: 'Parcourir les alumni',
              onAction: () => context.go('/alumni'),
            );
          }

          return RefreshIndicator(
            color: feed.linkBlue,
            onRefresh: () async => ref.invalidate(followingAlumniProvider),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.only(top: 8, bottom: 40),
              itemCount: following.length,
              itemBuilder: (context, index) {
                return _FollowRow(
                  alumni: following[index],
                  onOpen: () => context.push(
                    '/alumni/profile/${following[index].alumniId}',
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _FollowRow extends StatelessWidget {
  const _FollowRow({
    required this.alumni,
    required this.onOpen,
  });

  final FollowedAlumni alumni;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    final initials = alumni.name.isNotEmpty
        ? alumni.name.trim()[0].toUpperCase()
        : '?';

    return FeedPanel(
      onTap: onOpen,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: feed.softTint,
            backgroundImage: alumni.avatarUrl.isNotEmpty
                ? CachedNetworkImageProvider(alumni.avatarUrl)
                : null,
            child: alumni.avatarUrl.isEmpty
                ? Text(
                    initials,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: feed.linkBlue,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alumni.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: feed.ink,
                    fontSize: 16,
                  ),
                ),
                if (alumni.department.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    alumni.department,
                    style: TextStyle(color: feed.meta, fontSize: 13),
                  ),
                ],
                if (alumni.bio.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    alumni.bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: feed.meta, fontSize: 13, height: 1.3),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Suivi ${timeAgo(alumni.followedAt)}',
                  style: TextStyle(color: feed.meta, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: feed.meta),
        ],
      ),
    );
  }
}
