import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/theme/chat_ui.dart';
import '../../../../core/widgets/shimmer_skeletons.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/models/messaging_models.dart';
import '../../../../data/repositories/messaging_repository.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      ref.invalidate(conversationsProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _search.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.invalidate(conversationsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final user = auth.valueOrNull;

    if (user == null) {
      return Scaffold(
        backgroundColor: ChatUi.scaffold,
        appBar: AppBar(
          backgroundColor: ChatUi.appBar,
          foregroundColor: ChatUi.ink,
          title: const Text('Discussions'),
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 56,
                  color: ChatUi.accent.withValues(alpha: 0.85),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Connecte-toi pour voir tes messages',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: ChatUi.ink,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.go('/login'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ChatUi.accent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Se connecter'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final listAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: ChatUi.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: ChatUi.appBar,
            foregroundColor: ChatUi.ink,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            ),
            title: const Text(
              'Discussions',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: ChatUi.ink,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Actualiser',
                onPressed: () => ref.invalidate(conversationsProvider),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _search,
                  style: const TextStyle(color: ChatUi.ink, fontSize: 15),
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Rechercher…',
                    hintStyle: const TextStyle(color: ChatUi.meta),
                    prefixIcon: const Icon(Icons.search_rounded, color: ChatUi.meta),
                    filled: true,
                    fillColor: ChatUi.field,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          listAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 8),
                child: ConversationListSkeleton(count: 7),
              ),
            ),
            error: (e, _) => ContainedSliverError(
              message: apiErrorMessage(e),
              onRetry: () => ref.invalidate(conversationsProvider),
            ),
            data: (conversations) {
              final filtered = _query.isEmpty
                  ? conversations
                  : conversations
                      .where(
                        (c) => c.displayName.toLowerCase().contains(_query),
                      )
                      .toList();

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 52,
                            color: ChatUi.meta.withValues(alpha: 0.9),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            conversations.isEmpty
                                ? 'Aucune discussion'
                                : 'Aucun résultat',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: ChatUi.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tes conversations privées apparaîtront ici.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: ChatUi.meta,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverList.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  thickness: 0.4,
                  indent: 76,
                  color: ChatUi.listDivider,
                ),
                itemBuilder: (context, index) {
                  final conv = filtered[index];
                  return _ConversationTile(
                    conversation: conv,
                    onTap: () =>
                        context.push('/messages/chat/${conv.id}'),
                  );
                },
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

/// Erreur liste discussions (fond sombre).
class ContainedSliverError extends StatelessWidget {
  const ContainedSliverError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: ChatUi.ink),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(foregroundColor: ChatUi.accentSoft),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  final ChatConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final peer = conversation.peer;
    final last = conversation.lastMessage;
    final unread = conversation.unreadCount;
    final preview = _previewText(last, conversation);
    final timeLabel = last != null ? _formatInboxTime(last.createdAt) : '';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Stack(
              children: [
                _PeerAvatar(
                  name: conversation.displayName,
                  avatarUrl: conversation.avatarUrl,
                  size: 52,
                ),
                if (peer?.isOnline == true)
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: AkadexColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: ChatUi.scaffold, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight:
                                unread > 0 ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 16,
                            color: ChatUi.ink,
                          ),
                        ),
                      ),
                      if (timeLabel.isNotEmpty)
                        Text(
                          timeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                unread > 0 ? FontWeight.w600 : FontWeight.w500,
                            color: unread > 0 ? ChatUi.accentSoft : ChatUi.meta,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                unread > 0 ? FontWeight.w600 : FontWeight.w400,
                            color: unread > 0 ? ChatUi.ink : ChatUi.meta,
                          ),
                        ),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 22),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: ChatUi.accent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _previewText(ChatMessage? last, ChatConversation conv) {
    if (conv.peerIsRecording) return '🎤 Enregistre un message vocal…';
    if (conv.peerIsTyping) return 'écrit…';
    if (last == null) return 'Démarre la conversation';
    if (last.isAudio) return '🎤 Message vocal';
    final text = last.content.trim();
    return text.isEmpty ? 'Nouveau message' : text;
  }

  String _formatInboxTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    if (day == today) return DateFormat('HH:mm').format(local);
    if (day == today.subtract(const Duration(days: 1))) return 'Hier';
    if (now.difference(local).inDays < 7) {
      return DateFormat('EEE', 'fr_FR').format(local);
    }
    return DateFormat('dd/MM').format(local);
  }
}

class _PeerAvatar extends StatelessWidget {
  const _PeerAvatar({
    required this.name,
    required this.avatarUrl,
    this.size = 44,
  });

  final String name;
  final String avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AkadexColors.brandGradient,
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: avatarUrl,
              fit: BoxFit.cover,
              placeholder: (_, _) => _initial(initial),
              errorWidget: (_, _, _) => _initial(initial),
            )
          : _initial(initial),
    );
  }

  Widget _initial(String initial) {
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}
