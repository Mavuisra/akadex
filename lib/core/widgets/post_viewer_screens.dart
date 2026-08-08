import 'package:cached_network_image/cached_network_image.dart';
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
import '../theme/status_backgrounds.dart';
import '../theme/timeline_tokens.dart';
import 'status_text_block.dart';

/// Ouvre le bon viewer selon le type de publication.
Future<void> openPostViewer(
  BuildContext context, {
  required CommunityPost post,
}) {
  if (post.hasImage || post.hasPdf) {
    return context.push<void>('/posts/${post.id}/media', extra: post);
  }
  return context.push<void>('/posts/${post.id}', extra: post);
}

/// Publication texte (fond coloré éventuel) + commentaires style Facebook.
class TextPostViewerScreen extends ConsumerStatefulWidget {
  const TextPostViewerScreen({super.key, required this.post});

  final CommunityPost post;

  @override
  ConsumerState<TextPostViewerScreen> createState() =>
      _TextPostViewerScreenState();
}

class _TextPostViewerScreenState extends ConsumerState<TextPostViewerScreen> {
  late CommunityPost _post;
  final _comment = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _comment.text.trim();
    if (text.isEmpty) return;
    final me = ref.read(authStateProvider).valueOrNull;
    if (me == null) {
      context.push('/login');
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(communityRepositoryProvider).commentPost(_post.id, text);
      _comment.clear();
      ref.invalidate(postCommentsProvider(_post.id));
      setState(() => _post = _post.copyWith(comments: _post.comments + 1));
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
    final me = ref.watch(authStateProvider).valueOrNull;
    final commentsAsync = ref.watch(postCommentsProvider(_post.id));
    final feed = TimelineTokens.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final bg = StatusBackgrounds.resolveDisplayColor(
      content: _post.content,
      hasMedia: _post.hasMedia,
      backgroundColor: _post.backgroundColor,
      tags: _post.tags,
    );

    return Scaffold(
      backgroundColor: feed.feedBg,
      appBar: AppBar(
        backgroundColor: feed.cardBg,
        foregroundColor: feed.ink,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: feed.softTint,
              backgroundImage: _post.authorAvatarUrl.isNotEmpty
                  ? CachedNetworkImageProvider(_post.authorAvatarUrl)
                  : null,
              child: _post.authorAvatarUrl.isEmpty
                  ? Text(
                      _post.author.isEmpty
                          ? '?'
                          : _post.author[0].toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: primary,
                        fontSize: 12,
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
                    _post.author,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: feed.ink,
                    ),
                  ),
                  Text(
                    '${timeAgo(_post.createdAt)} · Public',
                    style: TextStyle(
                      fontSize: 12,
                      color: feed.meta,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (bg != null)
                  StatusTextBlock(
                    text: _post.content,
                    backgroundColor: bg,
                    minHeight: 320,
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Text(
                      _post.content,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.4,
                        color: feed.ink,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      if (_post.likes > 0) ...[
                        Icon(Icons.thumb_up,
                            size: 16, color: feed.likeActive),
                        const SizedBox(width: 6),
                        Text('${_post.likes}',
                            style: TextStyle(color: feed.meta)),
                      ],
                      const Spacer(),
                      if (_post.comments > 0)
                        Text(
                          '${_post.comments} commentaires',
                          style: TextStyle(color: feed.meta),
                        ),
                    ],
                  ),
                ),
                Divider(height: 1, color: feed.divider),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () async {
                            try {
                              final u = await ref
                                  .read(communityRepositoryProvider)
                                  .likePost(_post.id);
                              setState(() => _post = u);
                            } catch (_) {}
                          },
                          icon: Icon(
                            _post.isLiked
                                ? Icons.thumb_up
                                : Icons.thumb_up_outlined,
                            color: _post.isLiked
                                ? feed.likeActive
                                : feed.action,
                          ),
                          label: Text(
                            'J’aime',
                            style: TextStyle(
                              color: _post.isLiked
                                  ? feed.likeActive
                                  : feed.action,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.chat_bubble_outline,
                              color: feed.action),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.share_outlined,
                              color: feed.action),
                          label: Text(
                            'Partager',
                            style: TextStyle(
                              color: feed.action,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: feed.divider),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    'Commentaires',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: feed.ink,
                    ),
                  ),
                ),
                commentsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CupertinoActivityIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      apiErrorMessage(e),
                      style: TextStyle(color: feed.ink),
                    ),
                  ),
                  data: (list) {
                    if (list.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Aucun commentaire pour l’instant.',
                          style: TextStyle(color: feed.meta),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final c in list)
                          ListTile(
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: feed.softTint,
                              child: Text(
                                c.author.isEmpty
                                    ? '?'
                                    : c.author[0].toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: primary,
                                ),
                              ),
                            ),
                            title: Text(
                              c.author,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: feed.ink,
                              ),
                            ),
                            subtitle: Text(
                              c.content,
                              style: TextStyle(
                                color: feed.ink,
                                height: 1.35,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: feed.divider)),
                color: feed.cardBg,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: feed.softTint,
                    child: Text(
                      (me?.name.isNotEmpty == true)
                          ? me!.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _comment,
                      style: TextStyle(color: feed.ink),
                      decoration: InputDecoration(
                        hintText: me == null
                            ? 'Connecte-toi pour commenter'
                            : 'Commenter en tant que ${me.name.split(' ').first}…',
                        hintStyle: TextStyle(color: feed.meta),
                        filled: true,
                        fillColor: feed.commentBubble,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.send_rounded, color: feed.likeActive),
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

/// Publication photo / PDF plein écran style Facebook.
class MediaPostViewerScreen extends ConsumerStatefulWidget {
  const MediaPostViewerScreen({super.key, required this.post});

  final CommunityPost post;

  @override
  ConsumerState<MediaPostViewerScreen> createState() =>
      _MediaPostViewerScreenState();
}

class _MediaPostViewerScreenState extends ConsumerState<MediaPostViewerScreen> {
  late CommunityPost _post;
  final _comment = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _like() async {
    final me = ref.read(authStateProvider).valueOrNull;
    if (me == null) {
      context.push('/login');
      return;
    }
    try {
      final updated =
          await ref.read(communityRepositoryProvider).likePost(_post.id);
      if (mounted) setState(() => _post = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _sendComment() async {
    final text = _comment.text.trim();
    if (text.isEmpty || _sending) return;
    final me = ref.read(authStateProvider).valueOrNull;
    if (me == null) {
      context.push('/login');
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(communityRepositoryProvider).commentPost(_post.id, text);
      _comment.clear();
      ref.invalidate(postCommentsProvider(_post.id));
      setState(() => _post = _post.copyWith(comments: _post.comments + 1));
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

  void _openComments() {
    final me = ref.read(authStateProvider).valueOrNull;
    if (me == null) {
      context.push('/login');
      return;
    }
    final feed = TimelineTokens.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: feed.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final sheetFeed = TimelineTokens.of(ctx);
        final primary = Theme.of(ctx).colorScheme.primary;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.72,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: sheetFeed.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Commentaires',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: sheetFeed.ink,
                    ),
                  ),
                ),
                Divider(height: 1, color: sheetFeed.divider),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final commentsAsync =
                          ref.watch(postCommentsProvider(_post.id));
                      return commentsAsync.when(
                        loading: () => const Center(
                          child: CupertinoActivityIndicator(),
                        ),
                        error: (e, _) => Center(
                          child: Text(
                            apiErrorMessage(e),
                            style: TextStyle(color: sheetFeed.ink),
                          ),
                        ),
                        data: (list) {
                          if (list.isEmpty) {
                            return Center(
                              child: Text(
                                'Aucun commentaire pour l’instant.',
                                style: TextStyle(color: sheetFeed.meta),
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: list.length,
                            itemBuilder: (_, i) {
                              final c = list[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: sheetFeed.softTint,
                                      child: Text(
                                        c.author.isEmpty
                                            ? '?'
                                            : c.author[0].toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: sheetFeed.commentBubble,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              c.author,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: sheetFeed.ink,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              c.content,
                                              style: TextStyle(
                                                color: sheetFeed.ink,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _comment,
                            style: TextStyle(color: sheetFeed.ink),
                            decoration: InputDecoration(
                              hintText: 'Écrire un commentaire…',
                              hintStyle: TextStyle(color: sheetFeed.meta),
                              filled: true,
                              fillColor: sheetFeed.commentBubble,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            onSubmitted: (_) => _sendComment(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _sending ? null : _sendComment,
                          style: IconButton.styleFrom(
                            backgroundColor: sheetFeed.likeActive,
                            foregroundColor: Colors.white,
                          ),
                          icon: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _post.authorAvatarUrl;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: _post.hasImage
                  ? InteractiveViewer(
                      child: CachedNetworkImage(
                        imageUrl: _post.imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (_, _) => const CupertinoActivityIndicator(
                          color: Colors.white,
                        ),
                        errorWidget: (_, _, _) => Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white54,
                          size: 64,
                        ),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.picture_as_pdf,
                            color: Colors.white70, size: 64),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => context.push(
                            '/pdf-reader',
                            extra: {
                              'url': _post.attachmentUrl,
                              'title': _post.content.isEmpty
                                  ? 'Document'
                                  : _post.content,
                            },
                          ),
                          child: const Text('Ouvrir le PDF'),
                        ),
                      ],
                    ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_horiz, color: Colors.white),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AkadexColors.primarySoft,
                          backgroundImage: avatar.isNotEmpty
                              ? CachedNetworkImageProvider(avatar)
                              : null,
                          child: avatar.isEmpty
                              ? Text(
                                  _post.author.isEmpty
                                      ? '?'
                                      : _post.author[0].toUpperCase(),
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
                                _post.author,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${timeAgo(_post.createdAt)} · Public',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_post.content.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        _post.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Colors.white, height: 1.35),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        InkWell(
                          onTap: _like,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _post.isLiked
                                      ? Icons.thumb_up
                                      : Icons.thumb_up_outlined,
                                  color: _post.isLiked
                                      ? TimelineTokens.of(context).likeActive
                                      : Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_post.likes}',
                                  style: TextStyle(
                                    color: _post.isLiked
                                        ? TimelineTokens.of(context).likeActive
                                        : Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        InkWell(
                          onTap: _openComments,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_post.comments}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        const Icon(
                          Icons.share_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

