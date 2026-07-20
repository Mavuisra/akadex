import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/alumni_video_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/follow_chip.dart';
import '../../../../core/widgets/living_ui.dart';
import '../../../../core/widgets/moderation_chip.dart';
import '../../../../core/widgets/post_detail_sheet.dart';
import '../../../../core/widgets/shimmer_skeletons.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/models.dart';

class AlumniScreen extends ConsumerStatefulWidget {
  const AlumniScreen({super.key});

  @override
  ConsumerState<AlumniScreen> createState() => _AlumniScreenState();
}

class _AlumniScreenState extends ConsumerState<AlumniScreen> {
  int _tab = 0;

  static const _tabs = [
    (0, 'Pour toi'),
    (1, 'Conseils'),
    (2, 'Carrières'),
    (3, 'TFC'),
    (4, 'Vidéos'),
  ];

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsProvider('alumni'));
    final auth = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: postsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: PostFeedSkeleton(count: 4),
          ),
          error: (e, _) => Center(child: Text(apiErrorMessage(e))),
          data: (posts) {
            final mentors = _uniqueMentors(posts);
            final filtered = posts.where((p) {
              return switch (_tab) {
                1 => p.kind == 'alumni_advice' || p.kind == 'alumni_path',
                2 => p.kind == 'alumni_career',
                3 => p.kind == 'alumni_tfc',
                4 => p.kind == 'alumni_video' || p.videoUrl.isNotEmpty,
                _ => true,
              };
            }).toList();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeSlideIn(
                          child: LivingHeroBanner(
                            title: 'Espace Alumni',
                            subtitle:
                                'Mentorat, parcours et vidéos des diplômés — dont Roxie Ntumba.',
                            ctaLabel: auth.valueOrNull?.isAlumni == true
                                ? 'Publier une vidéo'
                                : 'Poser une question',
                            onCta: () => context.push('/alumni/publish'),
                            trailing: const Icon(
                              Icons.school_rounded,
                              color: Colors.white70,
                              size: 48,
                            ),
                          ),
                        ),
                        if (mentors.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const FadeSlideIn(
                            delay: Duration(milliseconds: 80),
                            child: Text(
                              'Mentors à suivre',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 100),
                            child: SizedBox(
                              height: 96,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: mentors.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (_, i) {
                                  final m = mentors[i];
                                  return _MentorAvatar(
                                    name: m.$1,
                                    following: m.$2,
                                    avatarUrl: m.$4,
                                    onOpenProfile: m.$3.isEmpty
                                        ? null
                                        : () => context.push(
                                              '/alumni/profile/${m.$3}',
                                            ),
                                    onFollow: m.$3.isEmpty
                                        ? null
                                        : () async {
                                            try {
                                              await ref
                                                  .read(
                                                    communityRepositoryProvider,
                                                  )
                                                  .toggleFollowAlumni(m.$3);
                                              ref.invalidate(
                                                postsProvider('alumni'),
                                              );
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content:
                                                      Text(apiErrorMessage(e)),
                                                ),
                                              );
                                            }
                                          },
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _tabs.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 6),
                            itemBuilder: (_, i) {
                              final t = _tabs[i];
                              final selected = _tab == t.$1;
                              return ChoiceChip(
                                label: Text(t.$2),
                                selected: selected,
                                onSelected: (_) =>
                                    setState(() => _tab = t.$1),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('Aucun contenu alumni.')),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final post = filtered[i];
                        final me = auth.valueOrNull;
                        return FadeSlideIn(
                          delay: Duration(milliseconds: 40 * (i % 6)),
                          child: _AlumniPostCard(
                            post: post,
                            showModeration: post.needsModerationBadge ||
                                (me != null && me.id == post.authorId),
                            onOpen: () => showPostDetailSheet(
                              context,
                              post: post,
                              ref: ref,
                            ),
                            onOpenProfile: post.authorId.isEmpty
                                ? null
                                : () => context.push(
                                      '/alumni/profile/${post.authorId}',
                                    ),
                            onFollow: () async {
                              try {
                                await ref
                                    .read(communityRepositoryProvider)
                                    .toggleFollowAlumni(post.authorId);
                                ref.invalidate(postsProvider('alumni'));
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(apiErrorMessage(e))),
                                );
                              }
                            },
                            onLike: () async {
                              await ref
                                  .read(communityRepositoryProvider)
                                  .likePost(post.id);
                              ref.invalidate(postsProvider('alumni'));
                            },
                            onSave: () async {
                              await ref
                                  .read(communityRepositoryProvider)
                                  .savePost(post.id);
                              ref.invalidate(postsProvider('alumni'));
                            },
                            onComment: () => _askQuestion(context, post),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: auth.maybeWhen(
        data: (user) {
          if (user == null) return null;
          return FloatingActionButton.extended(
            onPressed: () => context.push('/alumni/publish'),
            icon: Icon(
              user.isAlumni
                  ? Icons.videocam_outlined
                  : Icons.edit_outlined,
            ),
            label: Text(user.isAlumni ? 'Publier' : 'Question'),
          );
        },
        orElse: () => null,
      ),
    );
  }

  /// (name, isFollowing, authorId, avatarUrl)
  List<(String, bool, String, String)> _uniqueMentors(
    List<CommunityPost> posts,
  ) {
    final seen = <String>{};
    final out = <(String, bool, String, String)>[];
    for (final p in posts) {
      if (p.author.isEmpty || seen.contains(p.authorId)) continue;
      seen.add(p.authorId);
      out.add((
        p.author,
        p.isFollowingAuthor,
        p.authorId,
        p.authorAvatarUrl,
      ));
    }
    out.sort((a, b) {
      final aR = a.$1.toLowerCase().contains('roxie') ? 0 : 1;
      final bR = b.$1.toLowerCase().contains('roxie') ? 0 : 1;
      return aR.compareTo(bR);
    });
    return out.take(8).toList();
  }

  Future<void> _askQuestion(BuildContext context, CommunityPost post) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Commenter / poser une question'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Écris ta question…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty) return;
    try {
      await ref
          .read(communityRepositoryProvider)
          .commentPost(post.id, ctrl.text.trim());
      ref.invalidate(postsProvider('alumni'));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commentaire publié')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    }
  }
}

class _MentorAvatar extends StatelessWidget {
  const _MentorAvatar({
    required this.name,
    required this.following,
    this.avatarUrl = '',
    this.onOpenProfile,
    this.onFollow,
  });

  final String name;
  final bool following;
  final String avatarUrl;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onFollow;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    final isRoxie = name.toLowerCase().contains('roxie');
    return SizedBox(
      width: 76,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: onOpenProfile,
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isRoxie
                        ? const LinearGradient(
                            colors: [AkadexColors.accent, AkadexColors.primary],
                          )
                        : AkadexColors.brandGradient,
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    backgroundImage: avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl.isNotEmpty
                        ? null
                        : Text(
                            initial,
                            style: const TextStyle(
                              color: AkadexColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                  ),
                ),
              ),
              if (onFollow != null)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: GestureDetector(
                    onTap: onFollow,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: following
                            ? AkadexColors.success
                            : AkadexColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        following ? Icons.check : Icons.add,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onOpenProfile,
            child: Text(
              name.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlumniPostCard extends StatelessWidget {
  const _AlumniPostCard({
    required this.post,
    required this.onFollow,
    required this.onLike,
    required this.onSave,
    required this.onComment,
    required this.onOpen,
    this.onOpenProfile,
    this.showModeration = false,
  });

  final CommunityPost post;
  final VoidCallback onFollow;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onComment;
  final VoidCallback onOpen;
  final VoidCallback? onOpenProfile;
  final bool showModeration;

  @override
  Widget build(BuildContext context) {
    final hasVideo = post.videoUrl.trim().isNotEmpty;
    return SoftCard(
      padding: EdgeInsets.zero,
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onOpenProfile,
                  child: CircleAvatar(
                    backgroundColor: AkadexColors.primarySoft,
                    backgroundImage: post.authorAvatarUrl.isNotEmpty
                        ? NetworkImage(post.authorAvatarUrl)
                        : null,
                    child: post.authorAvatarUrl.isNotEmpty
                        ? null
                        : Text(
                            post.author.isEmpty
                                ? '?'
                                : post.author[0].toUpperCase(),
                            style: const TextStyle(
                              color: AkadexColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onOpenProfile,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.author,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          [
                            if (post.kindDisplay.isNotEmpty) post.kindDisplay,
                            if (post.department.isNotEmpty) post.department,
                          ].join(' · '),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AkadexColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showModeration) ...[
                  ModerationChip(status: post.moderationStatus),
                  const SizedBox(width: 6),
                ],
                if (post.authorId.isNotEmpty)
                  FollowChip(
                    following: post.isFollowingAuthor,
                    onPressed: onFollow,
                    compact: true,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Text(
              post.title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
            child: Text(post.content, style: const TextStyle(height: 1.4)),
          ),
          if (hasVideo) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AlumniVideoCard(
                url: post.videoUrl,
                title: post.title,
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: onLike,
                  icon: Icon(
                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: AkadexColors.danger,
                  ),
                ),
                Text('${post.likes}'),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onComment,
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                ),
                Text('${post.comments}'),
                const Spacer(),
                IconButton(
                  onPressed: onSave,
                  icon: Icon(
                    post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: AkadexColors.primary,
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
