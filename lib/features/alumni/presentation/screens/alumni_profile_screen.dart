import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/alumni_video_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/follow_chip.dart';
import '../../../../core/widgets/moderation_chip.dart';
import '../../../../core/widgets/post_detail_sheet.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/mappers/mappers.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/models.dart';

class AlumniProfileScreen extends ConsumerStatefulWidget {
  const AlumniProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<AlumniProfileScreen> createState() =>
      _AlumniProfileScreenState();
}

class _AlumniProfileScreenState extends ConsumerState<AlumniProfileScreen> {
  bool? _following;

  Future<void> _toggleFollow() async {
    try {
      final following = await ref
          .read(communityRepositoryProvider)
          .toggleFollowAlumni(widget.userId);
      setState(() => _following = following);
      ref.invalidate(postsProvider('alumni'));
      ref.invalidate(alumniProfileProvider(widget.userId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(following ? 'Abonnement activé' : 'Abonnement retiré'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(alumniProfileProvider(widget.userId));
    final postsAsync = ref.watch(alumniPostsByAuthorProvider(widget.userId));
    final me = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AkadexColors.background,
      body: profileAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(apiErrorMessage(e), textAlign: TextAlign.center),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(alumniProfileProvider(widget.userId)),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (user) {
          final isRoxie = user.name.toLowerCase().contains('roxie');
          final followingFromPosts = postsAsync.maybeWhen(
            data: (posts) =>
                posts.any((p) => p.isFollowingAuthor),
            orElse: () => false,
          );
          final following = _following ?? followingFromPosts;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 148,
                pinned: true,
                backgroundColor: AkadexColors.primary,
                leading: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: user.coverUrl != null &&
                          user.coverUrl!.isNotEmpty
                      ? Image.network(
                          user.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _CoverFallback(),
                        )
                      : const _CoverFallback(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo à cheval sur la couverture ; boutons alignés à droite.
                      Transform.translate(
                        offset: const Offset(0, -40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 88,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.12),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 42,
                                      backgroundColor: AkadexColors.primarySoft,
                                      backgroundImage: user.avatarUrl != null &&
                                              user.avatarUrl!.isNotEmpty
                                          ? NetworkImage(user.avatarUrl!)
                                          : null,
                                      child: user.avatarUrl == null ||
                                              user.avatarUrl!.isEmpty
                                          ? Text(
                                              user.name.isEmpty
                                                  ? '?'
                                                  : user.name[0].toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 34,
                                                fontWeight: FontWeight.w800,
                                                color: AkadexColors.primary,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (me?.id != user.id)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FollowChip(
                                            following: following,
                                            onPressed: _toggleFollow,
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            height: 32,
                                            child: FilledButton(
                                              onPressed: () {
                                                if (me == null) {
                                                  context.push('/login');
                                                  return;
                                                }
                                                context.push(
                                                  '/messages/with/${user.id}',
                                                );
                                              },
                                              style: FilledButton.styleFrom(
                                                backgroundColor:
                                                    AkadexColors.primary,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                ),
                                                minimumSize: const Size(0, 32),
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                visualDensity:
                                                    VisualDensity.compact,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                              ),
                                              child: const Text(
                                                'Contacter',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            if (user.headline.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                user.headline,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (user.role == 'alumni') 'Alumni · Mentor',
                                if (user.professionalDomain.isNotEmpty)
                                  user.professionalDomain,
                                if (user.company.isNotEmpty) user.company,
                              ].join(' · '),
                              style: const TextStyle(
                                color: AkadexColors.inkMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              [
                                if (user.university.isNotEmpty)
                                  user.university,
                                if (user.department.isNotEmpty)
                                  user.department,
                                if (user.promotion.isNotEmpty)
                                  user.promotion,
                                if (user.graduationYear != null)
                                  'Diplômé ${user.graduationYear}',
                              ].join(' · '),
                              style: const TextStyle(
                                color: AkadexColors.inkSoft,
                                fontSize: 13,
                              ),
                            ),
                            if (isRoxie) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AkadexColors.accentSoft,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Créatrice TikTok @roxientumba',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: Color(0xFF8A5A00),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _StatPill(
                                  value: formatCount(
                                    user.postsCount > 0
                                        ? user.postsCount
                                        : user.contributions,
                                  ),
                                  label: 'Publications',
                                ),
                                const SizedBox(width: 8),
                                _StatPill(
                                  value: formatCount(user.followersCount),
                                  label: 'Abonnés',
                                ),
                                const SizedBox(width: 8),
                                _StatPill(
                                  value: formatCount(user.followingCount),
                                  label: 'Abonnements',
                                ),
                                const SizedBox(width: 8),
                                _StatPill(
                                  value: formatCount(user.reputation),
                                  label: 'Points',
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'À propos',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SoftCard(
                              child: Text(
                                user.bio.isEmpty
                                    ? 'Aucune bio pour le moment.'
                                    : user.bio,
                                style: const TextStyle(height: 1.45),
                              ),
                            ),
                            if (user.badges.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              const Text(
                                'Réalisations',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final b in user.badges)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AkadexColors.border,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.verified_rounded,
                                            size: 16,
                                            color: AkadexColors.primary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            b,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 18),
                            const Text(
                              'Publications',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 8),
                            postsAsync.when(
                              loading: () => const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                  child: CupertinoActivityIndicator(),
                                ),
                              ),
                              error: (e, _) => Text(apiErrorMessage(e)),
                              data: (posts) {
                                if (posts.isEmpty) {
                                  return const SoftCard(
                                    child: Text(
                                      'Aucune publication pour l’instant.',
                                    ),
                                  );
                                }
                                CommunityPost? featuredVideo;
                                for (final p in posts) {
                                  if (p.videoUrl.trim().isNotEmpty) {
                                    featuredVideo = p;
                                    break;
                                  }
                                }
                                final textPosts = posts
                                    .where(
                                      (p) => p.videoUrl.trim().isEmpty,
                                    )
                                    .toList();

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (featuredVideo != null) ...[
                                      SoftCard(
                                        onTap: () => showPostDetailSheet(
                                          context,
                                          post: featuredVideo!,
                                          ref: ref,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Text(
                                                  'Vidéo mise en avant',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: AkadexColors.primary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const Spacer(),
                                                if (featuredVideo
                                                        .needsModerationBadge ||
                                                    me?.id ==
                                                        featuredVideo
                                                            .authorId)
                                                  ModerationChip(
                                                    status: featuredVideo
                                                        .moderationStatus,
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              featuredVideo.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            AlumniVideoCard(
                                              url: featuredVideo.videoUrl,
                                              title: featuredVideo.title,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    for (final p in textPosts) ...[
                                      _ProfilePostCard(
                                        post: p,
                                        showModeration:
                                            p.needsModerationBadge ||
                                                me?.id == p.authorId,
                                        onTap: () => showPostDetailSheet(
                                          context,
                                          post: p,
                                          ref: ref,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AkadexColors.brandGradient),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: 20,
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 140,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SoftCard(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AkadexColors.primary,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: AkadexColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePostCard extends StatelessWidget {
  const _ProfilePostCard({
    required this.post,
    required this.onTap,
    this.showModeration = false,
  });

  final CommunityPost post;
  final VoidCallback onTap;
  final bool showModeration;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (post.kindDisplay.isNotEmpty)
                Text(
                  post.kindDisplay,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AkadexColors.primary,
                  ),
                ),
              const Spacer(),
              if (showModeration)
                ModerationChip(status: post.moderationStatus),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            post.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            post.content,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            '${post.likes} j’aime · ${post.comments} commentaires',
            style: const TextStyle(fontSize: 12, color: AkadexColors.inkMuted),
          ),
        ],
      ),
    );
  }
}
