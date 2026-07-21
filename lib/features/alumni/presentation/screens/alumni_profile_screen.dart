import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/theme/timeline_tokens.dart';
import '../../../../core/widgets/follow_chip.dart';
import '../../../../core/widgets/timeline_post_card.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/mappers/mappers.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/document_type.dart';
import '../../../../domain/models/models.dart';

/// Profil public style Facebook (comme « Mon profil »).
class AlumniProfileScreen extends ConsumerStatefulWidget {
  const AlumniProfileScreen({
    super.key,
    required this.userId,
    this.focusDocumentId,
    this.focusPostId,
  });

  final String userId;
  final String? focusDocumentId;
  final String? focusPostId;

  @override
  ConsumerState<AlumniProfileScreen> createState() =>
      _AlumniProfileScreenState();
}

class _AlumniProfileScreenState extends ConsumerState<AlumniProfileScreen> {
  String _tab = 'Publications';
  bool? _following;
  bool _bioExpanded = false;
  final _focusKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if ((widget.focusDocumentId ?? '').trim().isNotEmpty) {
      _tab = 'Documents';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFocus());
  }

  void _scrollToFocus() {
    final ctx = _focusKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOut,
      alignment: 0.1,
    );
  }

  Future<void> _toggleFollow() async {
    try {
      final following = await ref
          .read(communityRepositoryProvider)
          .toggleFollowAlumni(widget.userId);
      setState(() => _following = following);
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
    final docsAsync = ref.watch(authorDocumentsProvider(widget.userId));
    final me = ref.watch(authStateProvider).valueOrNull;
    final isMe = me?.id == widget.userId;
    final focusDocId = widget.focusDocumentId?.trim() ?? '';
    final focusPostId = widget.focusPostId?.trim() ?? '';

    return Scaffold(
      backgroundColor: TimelineTokens.feedBg,
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
          final following = _following ?? false;
          final posts = postsAsync.valueOrNull ?? const <CommunityPost>[];
          final docs = docsAsync.valueOrNull ?? const <AcademicDocument>[];

          // Mettre la publication ciblée en tête
          final orderedDocs = [
            ...docs.where((d) => d.id == focusDocId),
            ...docs.where((d) => d.id != focusDocId),
          ];
          final orderedPosts = [
            ...posts.where((p) => p.id == focusPostId),
            ...posts.where((p) => p.id != focusPostId),
          ];

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                (focusDocId.isNotEmpty || focusPostId.isNotEmpty)) {
              _scrollToFocus();
            }
          });

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _FbCoverHeader(user: user),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF050505),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatCount(user.followersCount)} followers · '
                        '${formatCount(user.followingCount)} suivi(e)s · '
                        '${formatCount(user.postsCount > 0 ? user.postsCount : user.contributions)} publications',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF65676B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (user.bio.isNotEmpty || user.headline.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          user.bio.isNotEmpty ? user.bio : user.headline,
                          maxLines: _bioExpanded ? null : 3,
                          overflow: _bioExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.35,
                            color: Color(0xFF050505),
                          ),
                        ),
                        if ((user.bio.isNotEmpty ? user.bio : user.headline)
                                .length >
                            90)
                          GestureDetector(
                            onTap: () =>
                                setState(() => _bioExpanded = !_bioExpanded),
                            child: Text(
                              _bioExpanded ? 'Voir moins' : 'Voir plus',
                              style: const TextStyle(
                                color: TimelineTokens.likeActive,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: 10),
                      if (user.university.isNotEmpty)
                        _InfoLine(
                          icon: Icons.school_outlined,
                          text: user.university,
                        ),
                      if (user.faculty.isNotEmpty ||
                          user.department.isNotEmpty ||
                          user.promotion.isNotEmpty)
                        _InfoLine(
                          icon: Icons.account_tree_outlined,
                          text: [
                            if (user.faculty.isNotEmpty) user.faculty,
                            if (user.department.isNotEmpty) user.department,
                            if (user.level.isNotEmpty) user.level,
                            if (user.promotion.isNotEmpty) user.promotion,
                          ].join(' · '),
                        ),
                      const SizedBox(height: 14),
                      if (isMe)
                        Row(
                          children: [
                            Expanded(
                              child: _GreyBtn(
                                icon: Icons.edit_outlined,
                                label: 'Modifier le profil',
                                onTap: () => context.push('/profile/edit'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _BlueBtn(
                                icon: Icons.chat_bubble_outline_rounded,
                                label: 'Message',
                                onTap: () => context.push('/messages'),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: FollowChip(
                                following: following,
                                onPressed: _toggleFollow,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _BlueBtn(
                                icon: Icons.chat_bubble_outline_rounded,
                                label: 'Message',
                                onTap: () => context.push(
                                  '/messages/with/${widget.userId}',
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final t in const [
                              'Publications',
                              'Documents',
                              'À propos',
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(t),
                                  selected: _tab == t,
                                  onSelected: (_) =>
                                      setState(() => _tab = t),
                                  selectedColor: const Color(0xFFE7F3FF),
                                  labelStyle: TextStyle(
                                    color: _tab == t
                                        ? TimelineTokens.likeActive
                                        : const Color(0xFF050505),
                                    fontWeight: FontWeight.w700,
                                  ),
                                  side: BorderSide.none,
                                  showCheckmark: false,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1, color: Color(0xFFCED0D4)),
                    ],
                  ),
                ),
              ),
              if (_tab == 'À propos')
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informations',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (user.university.isNotEmpty)
                          _AboutRow(
                            icon: Icons.location_on_outlined,
                            title: 'Étudie à',
                            value: user.university,
                          ),
                        if (user.department.isNotEmpty)
                          _AboutRow(
                            icon: Icons.home_outlined,
                            title: 'Département',
                            value: user.department,
                          ),
                        if (user.professionalDomain.isNotEmpty)
                          _AboutRow(
                            icon: Icons.work_outline,
                            title: 'Domaine',
                            value: user.professionalDomain,
                          ),
                      ],
                    ),
                  ),
                ),
              if (_tab == 'Publications') ...[
                if (postsAsync.isLoading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CupertinoActivityIndicator()),
                    ),
                  )
                else if (orderedPosts.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(
                        child: Text(
                          'Aucune publication pour l’instant.',
                          style: TextStyle(color: TimelineTokens.meta),
                        ),
                      ),
                    ),
                  )
                else
                  for (final p in orderedPosts)
                    if (p.id == focusPostId)
                      SliverToBoxAdapter(
                        key: _focusKey,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: TimelineTokens.likeActive,
                                width: 2,
                              ),
                            ),
                            child: TimelinePostCard(post: p),
                          ),
                        ),
                      )
                    else
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TimelinePostCard(post: p),
                        ),
                      ),
              ],
              if (_tab == 'Documents') ...[
                if (docsAsync.isLoading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CupertinoActivityIndicator()),
                    ),
                  )
                else if (orderedDocs.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(
                        child: Text(
                          'Aucun document partagé.',
                          style: TextStyle(color: TimelineTokens.meta),
                        ),
                      ),
                    ),
                  )
                else
                  for (final d in orderedDocs)
                    SliverToBoxAdapter(
                      key: d.id == focusDocId ? _focusKey : null,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _FbDocumentCard(
                          doc: d,
                          author: user,
                          highlighted: d.id == focusDocId,
                          onOpen: () =>
                              context.push('/library/document/${d.id}'),
                        ),
                      ),
                    ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

final authorDocumentsProvider =
    FutureProvider.family<List<AcademicDocument>, String>((ref, authorId) {
  return ref.watch(academicRepositoryProvider).fetchMyDocuments(authorId);
});

class _FbCoverHeader extends StatelessWidget {
  const _FbCoverHeader({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final avatar = user.avatarUrl;
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: 180,
                width: double.infinity,
                child: user.coverUrl != null && user.coverUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: user.coverUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => const _CoverFallback(),
                      )
                    : const _CoverFallback(),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 4,
                left: 4,
                child: IconButton(
                  onPressed: () => context.pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                  ),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white),
                ),
              ),
              Positioned(
                left: 16,
                bottom: -36,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: CircleAvatar(
                    radius: 64,
                    backgroundColor: AkadexColors.primarySoft,
                    backgroundImage: avatar != null && avatar.isNotEmpty
                        ? CachedNetworkImageProvider(avatar)
                        : null,
                    child: avatar != null && avatar.isNotEmpty
                        ? null
                        : Text(
                            user.name.isEmpty
                                ? '?'
                                : user.name.characters.first.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: AkadexColors.primary,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 44),
        ],
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1877F2), Color(0xFF0A4DA6)],
        ),
      ),
    );
  }
}

class _FbDocumentCard extends StatelessWidget {
  const _FbDocumentCard({
    required this.doc,
    required this.author,
    required this.onOpen,
    this.highlighted = false,
  });

  final AcademicDocument doc;
  final UserProfile author;
  final VoidCallback onOpen;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      decoration: highlighted
          ? BoxDecoration(
              border: Border.all(color: TimelineTokens.likeActive, width: 2),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AkadexColors.primarySoft,
                  backgroundImage: author.avatarUrl != null &&
                          author.avatarUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(author.avatarUrl!)
                      : null,
                  child: author.avatarUrl == null || author.avatarUrl!.isEmpty
                      ? Text(
                          author.name.isEmpty
                              ? '?'
                              : author.name.characters.first.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AkadexColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFF050505),
                        ),
                      ),
                      Text(
                        doc.type.label,
                        style: const TextStyle(
                          color: TimelineTokens.meta,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (highlighted)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F3FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Trouvé',
                      style: TextStyle(
                        color: TimelineTokens.likeActive,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              doc.title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF050505),
                height: 1.3,
              ),
            ),
          ),
          if (doc.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Text(
                doc.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF050505),
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Text(
              '${formatCount(doc.downloads)} téléchargements · ${doc.sizeLabel}',
              style: const TextStyle(
                color: TimelineTokens.meta,
                fontSize: 13,
              ),
            ),
          ),
          const Divider(height: 1, color: TimelineTokens.divider),
          SizedBox(
            height: TimelineTokens.actionHeight,
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.download_outlined, size: 20),
                    label: const Text('Ouvrir'),
                    style: TextButton.styleFrom(
                      foregroundColor: TimelineTokens.action,
                    ),
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: TimelineTokens.meta),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF050505),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: TimelineTokens.meta),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: TimelineTokens.meta,
                    fontSize: 13,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
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

class _GreyBtn extends StatelessWidget {
  const _GreyBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE4E6EB),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF050505)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF050505),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlueBtn extends StatelessWidget {
  const _BlueBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TimelineTokens.likeActive,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
