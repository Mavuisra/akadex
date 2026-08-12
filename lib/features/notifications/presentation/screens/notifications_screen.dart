import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/timeline_tokens.dart';
import '../../../../core/widgets/feed_subpage_scaffold.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/models.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(notificationsProvider);
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(notificationsProvider);
    await ref.read(notificationsProvider.future);
  }

  Future<void> _markAllRead() async {
    await ref.read(authRepositoryProvider).markAllNotificationsRead();
    ref.invalidate(notificationsProvider);
  }

  Future<void> _open(AppNotification notif) async {
    if (!notif.isRead) {
      await ref.read(authRepositoryProvider).markNotificationRead(notif.id);
      ref.invalidate(notificationsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    final notifsAsync = ref.watch(notificationsProvider);

    return FeedSubpageScaffold(
      title: 'Notifications',
      actions: [
        TextButton(
          onPressed: () async {
            final list = notifsAsync.valueOrNull ?? const [];
            if (list.any((n) => !n.isRead)) await _markAllRead();
          },
          child: Text(
            'Tout lire',
            style: TextStyle(
              color: feed.linkBlue,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: notifsAsync.when(
          loading: () => ListView(
            children: const [
              SizedBox(height: 120),
              Center(child: CupertinoActivityIndicator()),
            ],
          ),
          error: (e, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(apiErrorMessage(e)),
              ),
            ],
          ),
          data: (notifs) {
            if (notifs.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Icon(Icons.notifications_none_rounded,
                      size: 48, color: feed.meta),
                  const SizedBox(height: 12),
                  Text(
                    'Aucune notification',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: feed.ink,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Les notes sur tes documents et les validations apparaîtront ici.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: feed.meta, fontSize: 13),
                  ),
                ],
              );
            }

            final fmt = DateFormat('d MMM · HH:mm', 'fr_FR');
            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 40),
              itemCount: notifs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final n = notifs[i];
                return FeedPanel(
                  child: Material(
                    color: n.isRead
                        ? Colors.transparent
                        : feed.softTint.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _open(n),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _iconFor(n.kind),
                              size: 22,
                              color: n.isRead ? feed.meta : feed.linkBlue,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: feed.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    n.message,
                                    style: TextStyle(
                                      color: feed.ink,
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    fmt.format(n.createdAt.toLocal()),
                                    style: TextStyle(
                                      color: feed.meta,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!n.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE53935),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  IconData _iconFor(String kind) => switch (kind) {
        'document_approved' => Icons.verified_rounded,
        'document_rejected' => Icons.cancel_outlined,
        'post_approved' => Icons.check_circle_outline,
        'post_rejected' => Icons.block_outlined,
        'points' => Icons.stars_rounded,
        _ => Icons.star_rounded,
      };
}
