import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/shimmer_skeletons.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/models/messaging_models.dart';
import '../../../../data/repositories/messaging_repository.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final user = auth.valueOrNull;

    if (user == null) {
      return Scaffold(
        backgroundColor: AkadexColors.background,
        appBar: AppBar(
          title: const Text('Messages'),
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
                  color: AkadexColors.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Connecte-toi pour voir tes messages',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: AkadexColors.ink,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.go('/login'),
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
      backgroundColor: AkadexColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: AkadexColors.background.withValues(alpha: 0.94),
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: const Text('Messages'),
            actions: [
              IconButton(
                tooltip: 'Actualiser',
                onPressed: () => ref.invalidate(conversationsProvider),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          listAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: ConversationListSkeleton(count: 7),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        apiErrorMessage(e),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(conversationsProvider),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            data: (conversations) {
              if (conversations.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: AkadexColors.primarySoft,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: const Icon(
                              Icons.forum_outlined,
                              size: 42,
                              color: AkadexColors.primary,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Aucune conversation',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: AkadexColors.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Contacte un alumni ou un camarade pour démarrer une discussion privée.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AkadexColors.inkMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList.separated(
                  itemCount: conversations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    return _ConversationTile(
                      conversation: conv,
                      delay: Duration(milliseconds: 40 * index.clamp(0, 8)),
                      onTap: () =>
                          context.push('/messages/chat/${conv.id}'),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.onTap,
    this.delay = Duration.zero,
  });

  final ChatConversation conversation;
  final VoidCallback onTap;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final peer = conversation.peer;
    final last = conversation.lastMessage;
    final unread = conversation.unreadCount;
    final preview = _previewText(last, conversation);
    final timeLabel = last != null ? _formatInboxTime(last.createdAt) : '';

    return SoftCard(
      delay: delay,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Stack(
            children: [
              _PeerAvatar(
                name: conversation.displayName,
                avatarUrl: conversation.avatarUrl,
                size: 54,
              ),
              if (peer?.isOnline == true)
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AkadexColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
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
                              unread > 0 ? FontWeight.w800 : FontWeight.w700,
                          fontSize: 16,
                          color: AkadexColors.ink,
                        ),
                      ),
                    ),
                    if (timeLabel.isNotEmpty)
                      Text(
                        timeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              unread > 0 ? FontWeight.w700 : FontWeight.w500,
                          color: unread > 0
                              ? AkadexColors.primary
                              : AkadexColors.inkSoft,
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
                          color: unread > 0
                              ? AkadexColors.inkMuted
                              : AkadexColors.inkSoft,
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
                          color: AkadexColors.primary,
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
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AkadexColors.brandGradient,
        boxShadow: [
          BoxShadow(
            color: AkadexColors.primary.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
