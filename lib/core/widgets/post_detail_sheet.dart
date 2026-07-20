import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/api_client.dart';
import '../../data/auth/auth_repository.dart';
import '../../data/mappers/mappers.dart';
import '../../data/repositories/repositories.dart';
import '../../domain/models/models.dart';
import '../theme/akadex_theme.dart';
import 'alumni_video_card.dart';
import 'moderation_chip.dart';
import 'status_text_block.dart';

Future<void> showPostDetailSheet(
  BuildContext context, {
  required CommunityPost post,
  required WidgetRef ref,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AkadexColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _PostDetailBody(post: post, parentRef: ref),
  );
}

class _PostDetailBody extends ConsumerStatefulWidget {
  const _PostDetailBody({required this.post, required this.parentRef});

  final CommunityPost post;
  final WidgetRef parentRef;

  @override
  ConsumerState<_PostDetailBody> createState() => _PostDetailBodyState();
}

class _PostDetailBodyState extends ConsumerState<_PostDetailBody> {
  late CommunityPost _post;
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

  void _openAuthor() {
    if (_post.authorId.isEmpty) return;
    Navigator.pop(context);
    final me = widget.parentRef.read(authStateProvider).valueOrNull;
    if (me != null && me.id == _post.authorId) {
      context.push('/profile/me');
    } else {
      context.push('/alumni/profile/${_post.authorId}');
    }
  }

  Future<void> _like() async {
    try {
      final updated = await widget.parentRef
          .read(communityRepositoryProvider)
          .likePost(_post.id);
      setState(() => _post = updated);
      widget.parentRef.invalidate(postsProvider('alumni'));
      widget.parentRef.invalidate(postsProvider('community'));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    }
  }

  Future<void> _save() async {
    try {
      final updated = await widget.parentRef
          .read(communityRepositoryProvider)
          .savePost(_post.id);
      setState(() => _post = updated);
      widget.parentRef.invalidate(postsProvider('alumni'));
      widget.parentRef.invalidate(postsProvider('community'));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    }
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await widget.parentRef
          .read(communityRepositoryProvider)
          .commentPost(_post.id, text);
      _commentCtrl.clear();
      widget.parentRef.invalidate(postCommentsProvider(_post.id));
      widget.parentRef.invalidate(postsProvider('alumni'));
      widget.parentRef.invalidate(postsProvider('community'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commentaire publié')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(postCommentsProvider(_post.id));
    final me = widget.parentRef.watch(authStateProvider).valueOrNull;
    final showMod = _post.needsModerationBadge ||
        (me != null && me.id == _post.authorId);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _openAuthor,
                    child: CircleAvatar(
                      backgroundColor: AkadexColors.primarySoft,
                      backgroundImage: _post.authorAvatarUrl.isNotEmpty
                          ? NetworkImage(_post.authorAvatarUrl)
                          : null,
                      child: _post.authorAvatarUrl.isNotEmpty
                          ? null
                          : Text(
                              _post.author.isEmpty
                                  ? '?'
                                  : _post.author[0].toUpperCase(),
                              style: const TextStyle(
                                color: AkadexColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _openAuthor,
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _post.author,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            [
                              if (_post.kindDisplay.isNotEmpty)
                                _post.kindDisplay,
                              if (_post.department.isNotEmpty)
                                _post.department,
                              timeAgo(_post.createdAt),
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
                  if (showMod) ModerationChip(status: _post.moderationStatus),
                  if (_post.authorId.isNotEmpty &&
                      (me == null || me.id != _post.authorId))
                    IconButton(
                      tooltip: 'Contacter',
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (me == null) {
                          context.push('/login');
                          return;
                        }
                        context.push('/messages/with/${_post.authorId}');
                      },
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AkadexColors.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              PostBodyText(
                content: _post.content,
                backgroundColor: _post.backgroundColor,
                tags: _post.tags,
                hasMedia: _post.hasMedia,
                padded: false,
              ),
              if (_post.rejectionReason.isNotEmpty &&
                  _post.moderationStatus == 'rejected') ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECEC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Motif : ${_post.rejectionReason}',
                    style: const TextStyle(
                      color: AkadexColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (_post.videoUrl.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                AlumniVideoCard(url: _post.videoUrl, title: _post.title),
              ],
              if (_post.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final t in _post.tags)
                      Chip(
                        label: Text(t),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: _like,
                    icon: Icon(
                      _post.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: AkadexColors.danger,
                    ),
                  ),
                  Text('${_post.likes}'),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _save,
                    icon: Icon(
                      _post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: AkadexColors.primary,
                    ),
                  ),
                  Text(_post.isSaved ? 'Enregistré' : 'Enregistrer'),
                ],
              ),
              const Divider(height: 28),
              const Text(
                'Commentaires',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 10),
              commentsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CupertinoActivityIndicator()),
                ),
                error: (e, _) => Text(
                  apiErrorMessage(e),
                  style: const TextStyle(color: AkadexColors.inkMuted),
                ),
                data: (comments) {
                  if (comments.isEmpty) {
                    return const Text(
                      'Aucun commentaire pour l’instant.',
                      style: TextStyle(color: AkadexColors.inkMuted),
                    );
                  }
                  return Column(
                    children: [
                      for (final c in comments)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AkadexColors.primarySoft,
                                child: Text(
                                  c.author.isEmpty
                                      ? '?'
                                      : c.author[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AkadexColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.author,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(c.content),
                                    const SizedBox(height: 2),
                                    Text(
                                      timeAgo(c.createdAt),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AkadexColors.inkSoft,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AkadexColors.primarySoft,
                    child: Text(
                      (ref.watch(authStateProvider).valueOrNull?.name ?? '?')
                          .characters
                          .first
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AkadexColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _commentCtrl,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendComment(),
                        decoration: const InputDecoration(
                          hintText: 'Écrire un commentaire…',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : _sendComment,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Color(0xFF1877F2),
                          ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
