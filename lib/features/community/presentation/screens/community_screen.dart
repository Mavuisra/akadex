import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/moderation_chip.dart';
import '../../../../core/widgets/post_detail_sheet.dart';
import '../../../../core/widgets/shimmer_skeletons.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/mappers/mappers.dart';
import '../../../../data/repositories/repositories.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  String _tab = 'Pour toi';
  static const _tabs = ['Pour toi', 'Questions', 'Discussions'];

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsProvider('community'));
    final me = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connexion requise pour publier.')),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(postsProvider('community')),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              const Text(
                'Communauté',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              FilterChipBar(
                items: _tabs,
                selected: _tab,
                onSelected: (v) => setState(() => _tab = v),
              ),
              const SizedBox(height: 16),
              postsAsync.when(
                loading: () => const PostFeedSkeleton(count: 4),
                error: (e, _) => SoftCard(
                  child: Column(
                    children: [
                      Text(apiErrorMessage(e), textAlign: TextAlign.center),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(postsProvider('community')),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
                data: (posts) {
                  final filtered = switch (_tab) {
                    'Questions' => posts
                        .where(
                          (p) =>
                              p.title.contains('?') ||
                              p.tags.any((t) => t.contains('exam')),
                        )
                        .toList(),
                    'Discussions' =>
                      posts.where((p) => !p.title.contains('?')).toList(),
                    _ => posts,
                  };
                  if (filtered.isEmpty) {
                    return const Text(
                      'Aucune publication.',
                      style: TextStyle(color: AkadexColors.inkMuted),
                    );
                  }
                  return Column(
                    children: [
                      for (final p in filtered)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SoftCard(
                            onTap: () => showPostDetailSheet(
                              context,
                              post: p,
                              ref: ref,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: p.authorId.isEmpty
                                          ? null
                                          : () {
                                              if (me?.id == p.authorId) {
                                                context.go('/profile');
                                              } else {
                                                context.push(
                                                  '/alumni/profile/${p.authorId}',
                                                );
                                              }
                                            },
                                      child: CircleAvatar(
                                        radius: 18,
                                        backgroundColor:
                                            AkadexColors.primarySoft,
                                        backgroundImage:
                                            p.authorAvatarUrl.isNotEmpty
                                                ? NetworkImage(
                                                    p.authorAvatarUrl,
                                                  )
                                                : null,
                                        child: p.authorAvatarUrl.isNotEmpty
                                            ? null
                                            : Text(
                                                p.author.isEmpty
                                                    ? '?'
                                                    : p.author.characters.first
                                                        .toUpperCase(),
                                                style: const TextStyle(
                                                  color: AkadexColors.primary,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: p.authorId.isEmpty
                                            ? null
                                            : () {
                                                if (me?.id == p.authorId) {
                                                  context.go('/profile');
                                                } else {
                                                  context.push(
                                                    '/alumni/profile/${p.authorId}',
                                                  );
                                                }
                                              },
                                        behavior: HitTestBehavior.opaque,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.author,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              '${p.department} · ${timeAgo(p.createdAt)}',
                                              style: const TextStyle(
                                                color: AkadexColors.inkMuted,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (p.needsModerationBadge ||
                                        me?.id == p.authorId)
                                      ModerationChip(
                                        status: p.moderationStatus,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  p.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  p.content,
                                  style: const TextStyle(
                                    color: AkadexColors.inkMuted,
                                    height: 1.4,
                                  ),
                                ),
                                if (p.tags.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      for (final t in p.tags) DocTypeTag(t),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.favorite_border,
                                      size: 18,
                                      color: AkadexColors.inkMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${p.likes}',
                                      style: const TextStyle(
                                        color: AkadexColors.inkMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(
                                      Icons.chat_bubble_outline,
                                      size: 18,
                                      color: AkadexColors.inkMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${p.comments}',
                                      style: const TextStyle(
                                        color: AkadexColors.inkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
