import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/api/api_client.dart';
import '../../data/auth/auth_repository.dart';
import '../../data/mappers/mappers.dart';
import '../../data/repositories/repositories.dart';
import '../../domain/models/models.dart';
import '../theme/akadex_theme.dart';
import '../theme/timeline_tokens.dart';
import 'moderation_chip.dart';
import 'post_academic_tags.dart';
import 'post_media_carousel.dart';
import 'post_viewer_screens.dart';
import 'status_text_block.dart';

class TimelinePostCard extends ConsumerStatefulWidget {
  const TimelinePostCard({
    super.key,
    required this.post,
    this.onChanged,
  });

  final CommunityPost post;
  final ValueChanged<CommunityPost>? onChanged;

  @override
  ConsumerState<TimelinePostCard> createState() => _TimelinePostCardState();
}

class _TimelinePostCardState extends ConsumerState<TimelinePostCard> {
  late CommunityPost _post;
  bool _busy = false;
  bool _showComposer = false;
  final _commentCtrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TimelinePostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.likes != widget.post.likes ||
        oldWidget.post.isLiked != widget.post.isLiked ||
        oldWidget.post.comments != widget.post.comments) {
      _post = widget.post;
    }
  }

  Future<void> _like() async {
    final me = ref.read(authStateProvider).valueOrNull;
    if (me == null) {
      context.push('/login');
      return;
    }
    if (_busy) return;
    setState(() {
      _busy = true;
      _post = _post.copyWith(
        isLiked: !_post.isLiked,
        likes: _post.isLiked ? (_post.likes - 1).clamp(0, 999999) : _post.likes + 1,
      );
    });
    HapticFeedback.selectionClick();
    try {
      final updated =
          await ref.read(communityRepositoryProvider).likePost(_post.id);
      if (!mounted) return;
      setState(() => _post = updated);
      widget.onChanged?.call(updated);
      ref.invalidate(timelinePostsProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() => _post = widget.post);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final me = ref.read(authStateProvider).valueOrNull;
    if (me == null) {
      context.push('/login');
      return;
    }
    if (_busy) return;
    setState(() {
      _busy = true;
      _post = _post.copyWith(isSaved: !_post.isSaved);
    });
    HapticFeedback.lightImpact();
    try {
      final updated =
          await ref.read(communityRepositoryProvider).savePost(_post.id);
      if (!mounted) return;
      setState(() => _post = updated);
      widget.onChanged?.call(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _post = widget.post);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(
        text:
            '${_post.content}\n\n— via Akadex${_post.hasPdf ? '\n${_post.attachmentUrl}' : ''}',
        subject: 'Akadex',
      ),
    );
  }

  void _openPdf() {
    if (!_post.hasPdf) return;
    context.push(
      '/pdf-reader',
      extra: {'url': _post.attachmentUrl, 'title': _post.title},
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la publication ?'),
        content: const Text(
          'Cette action est définitive. La publication disparaîtra du fil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFB3261E)),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(communityRepositoryProvider).deletePost(_post.id);
      ref.invalidate(timelinePostsProvider);
      ref.invalidate(postsProvider('community'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publication supprimée.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendComment() async {
    final me = ref.read(authStateProvider).valueOrNull;
    if (me == null) {
      context.push('/login');
      return;
    }
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(communityRepositoryProvider).commentPost(_post.id, text);
      _commentCtrl.clear();
      ref.invalidate(postCommentsProvider(_post.id));
      setState(() {
        _post = _post.copyWith(comments: _post.comments + 1);
        _showComposer = true;
      });
      widget.onChanged?.call(_post);
      HapticFeedback.lightImpact();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String get _metaLine {
    final parts = <String>[
      if (_post.authorUniversity.isNotEmpty) _post.authorUniversity,
      if (_post.authorPromotion.isNotEmpty) _post.authorPromotion,
      if (_post.department.isNotEmpty && _post.authorUniversity.isEmpty)
        _post.department,
    ];
    final who = parts.isEmpty ? '' : '${parts.join(' · ')} · ';
    return '$who${timeAgo(_post.createdAt)}';
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authStateProvider).valueOrNull;
    final commentsAsync = ref.watch(postCommentsProvider(_post.id));
    final pad = TimelineTokens.feedHorizontal(context);

    return Padding(
      padding: EdgeInsets.only(
        left: pad.left,
        right: pad.right,
        bottom: TimelineTokens.sectionGap,
      ),
      child: Material(
        color: TimelineTokens.cardBg,
        elevation: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TimelineTokens.cardPadH,
                TimelineTokens.cardPadV,
                8,
                8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _post.authorId.isEmpty
                        ? null
                        : () {
                            if (me?.id == _post.authorId) {
                              context.push('/profile/me');
                            } else {
                              context.push('/alumni/profile/${_post.authorId}');
                            }
                          },
                    child: _Avatar(
                      url: _post.authorAvatarUrl,
                      name: _post.author,
                      size: TimelineTokens.avatar,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _post.author,
                          style: const TextStyle(
                            fontSize: TimelineTokens.nameSize,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF050505),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _metaLine,
                                style: const TextStyle(
                                  fontSize: TimelineTokens.metaSize,
                                  color: TimelineTokens.meta,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.public,
                              size: 12,
                              color: TimelineTokens.meta,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_post.kindDisplay.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: 4),
                      child: Text(
                        _post.kindDisplay,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: TimelineTokens.linkBlue,
                        ),
                      ),
                    ),
                  if (_post.needsModerationBadge || me?.id == _post.authorId)
                    ModerationChip(status: _post.moderationStatus),
                  if (me != null && me.id == _post.authorId)
                    PopupMenuButton<String>(
                      tooltip: 'Options',
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.more_horiz,
                        color: TimelineTokens.meta,
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          context.push('/community/publish', extra: _post);
                        } else if (value == 'delete') {
                          _confirmDelete();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Modifier'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.delete_outline,
                              color: Color(0xFFB3261E),
                            ),
                            title: Text(
                              'Supprimer',
                              style: TextStyle(color: Color(0xFFB3261E)),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (_post.content.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => openPostViewer(context, post: _post),
                child: PostBodyText(
                  content: _post.content,
                  backgroundColor: _post.backgroundColor,
                  tags: _post.tags,
                  hasMedia: _post.hasMedia,
                ),
              ),
            ],
            if (_post.hasImage || _post.hasPdf) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => openPostViewer(context, post: _post),
                child: PostMediaCarousel(
                  imageUrl: _post.imageUrl,
                  pdfUrl: _post.attachmentUrl,
                  pdfPageCount: _post.pageCount,
                  onOpenPdf: _post.hasPdf ? _openPdf : null,
                  height: 280,
                ),
              ),
            ],
            PostAcademicTagsRow(post: _post),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(
                children: [
                  if (_post.likes > 0) ...[
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: TimelineTokens.likeActive,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.thumb_up,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_post.likes}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: TimelineTokens.meta,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (_post.comments > 0)
                    GestureDetector(
                      onTap: () => setState(() => _showComposer = true),
                      child: Text(
                        '${_post.comments} commentaire${_post.comments > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: TimelineTokens.meta,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.5, color: TimelineTokens.divider),
            SizedBox(
              height: TimelineTokens.actionHeight,
              child: Row(
                children: [
                  _Action(
                    icon: _post.isLiked
                        ? Icons.thumb_up_alt_rounded
                        : Icons.thumb_up_alt_outlined,
                    label: 'J’aime',
                    active: _post.isLiked,
                    activeColor: TimelineTokens.likeActive,
                    onTap: _like,
                  ),
                  _Action(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '',
                    onTap: () {
                      final me = ref.read(authStateProvider).valueOrNull;
                      if (me == null) {
                        context.push('/login');
                        return;
                      }
                      setState(() => _showComposer = true);
                    },
                  ),
                  _Action(
                    icon: _post.isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    label: 'Enregistrer',
                    active: _post.isSaved,
                    onTap: _save,
                  ),
                  _Action(
                    icon: Icons.share_outlined,
                    label: 'Partager',
                    onTap: _share,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.5, color: TimelineTokens.divider),
            commentsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (comments) {
                if (comments.isEmpty && !_showComposer) {
                  return const SizedBox.shrink();
                }
                final preview = comments.take(2).toList();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final c in preview) _CommentBubble(comment: c),
                      if (comments.length > 2)
                        TextButton(
                          onPressed: () => openPostViewer(context, post: _post),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Voir les ${comments.length} commentaires',
                            style: const TextStyle(
                              color: TimelineTokens.meta,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      if (_showComposer || comments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _FacebookCommentField(
                          controller: _commentCtrl,
                          avatarUrl: me?.avatarUrl,
                          name: me?.name ?? '',
                          sending: _sending,
                          onSend: _sendComment,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  const _CommentBubble({required this.comment});

  final CourseCommentItem comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(
            url: '',
            name: comment.author,
            size: TimelineTokens.commentAvatar,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: TimelineTokens.commentBubble,
                borderRadius: BorderRadius.circular(TimelineTokens.commentRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.author,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF050505),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    comment.content,
                    style: const TextStyle(
                      fontSize: TimelineTokens.commentSize,
                      height: 1.35,
                      color: Color(0xFF050505),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FacebookCommentField extends StatelessWidget {
  const _FacebookCommentField({
    required this.controller,
    required this.onSend,
    required this.sending,
    this.avatarUrl,
    this.name = '',
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool sending;
  final String? avatarUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Avatar(
          url: avatarUrl ?? '',
          name: name,
          size: TimelineTokens.commentAvatar,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: TimelineTokens.commentBubble,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: const InputDecoration(
                      hintText: 'Écrire un commentaire…',
                      hintStyle: TextStyle(
                        color: TimelineTokens.meta,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                IconButton(
                  onPressed: sending ? null : onSend,
                  icon: sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: TimelineTokens.likeActive,
                          size: 22,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.url,
    required this.name,
    required this.size,
  });

  final String url;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AkadexColors.primarySoft,
      backgroundImage: url.isNotEmpty ? CachedNetworkImageProvider(url) : null,
      child: url.isNotEmpty
          ? null
          : Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: TextStyle(
                color: AkadexColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.35,
              ),
            ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.activeColor = AkadexColors.primary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : TimelineTokens.action;
    final iconOnly = label.trim().isEmpty;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: TimelineTokens.iconAction, color: color),
            if (!iconOnly) ...[
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: TimelineTokens.actionLabelSize,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
