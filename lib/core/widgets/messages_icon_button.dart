import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/messaging_repository.dart';

/// Icône messages avec pastille si conversations non lues.
class MessagesIconButton extends ConsumerWidget {
  const MessagesIconButton({
    super.key,
    this.iconSize = 26,
    this.color,
  });

  final double iconSize;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(conversationsProvider).maybeWhen(
          data: (list) =>
              list.fold<int>(0, (sum, c) => sum + c.unreadCount),
          orElse: () => 0,
        );

    return IconButton(
      tooltip: unread > 0
          ? '$unread message${unread > 1 ? 's' : ''} non lu${unread > 1 ? 's' : ''}'
          : 'Messages',
      onPressed: () => context.push('/messages'),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        backgroundColor: const Color(0xFFE53935),
        child: Icon(
          Icons.chat_bubble_outline_rounded,
          size: iconSize,
          color: color,
        ),
      ),
    );
  }
}
