import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/repositories.dart';

/// Icône notifications avec pastille si non lues.
class NotificationIconButton extends ConsumerWidget {
  const NotificationIconButton({
    super.key,
    this.iconSize = 26,
    this.route = '/notifications',
  });

  final double iconSize;
  final String route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsCountProvider);

    return IconButton(
      tooltip: unread > 0 ? '$unread notification${unread > 1 ? 's' : ''}' : 'Notifications',
      onPressed: () => context.push(route),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        backgroundColor: const Color(0xFFE53935),
        child: Icon(Icons.notifications_none_rounded, size: iconSize),
      ),
    );
  }
}
