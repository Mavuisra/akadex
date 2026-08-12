import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/timeline_tokens.dart';
import '../../../../core/widgets/feed_subpage_scaffold.dart';
import '../../../../core/widgets/timeline_post_card.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/repositories/repositories.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = TimelineTokens.of(context);
    final savedAsync = ref.watch(savedPostsProvider);

    return FeedSubpageScaffold(
      title: 'Enregistrements',
      body: savedAsync.when(
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
                  onPressed: () => ref.invalidate(savedPostsProvider),
                ),
              ],
            ),
          ),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return FeedEmptyState(
              icon: Icons.bookmark_border_rounded,
              title: 'Aucun enregistrement',
              message:
                  'Enregistre des publications depuis le fil pour les retrouver ici.',
              actionLabel: 'Explorer le fil',
              onAction: () => context.go('/home'),
            );
          }

          return RefreshIndicator(
            color: feed.linkBlue,
            onRefresh: () async => ref.invalidate(savedPostsProvider),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.only(bottom: 40),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return TimelinePostCard(
                  post: post,
                  onChanged: (_) => ref.invalidate(savedPostsProvider),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
