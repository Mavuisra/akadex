import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sync/sync_service.dart';

/// Bandeau visible hors ligne / sync partielle (catalogue local).
class OfflineStatusBanner extends ConsumerWidget {
  const OfflineStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sans override localStore (ex. tests unitaires), on n’affiche rien.
    try {
      ref.read(localStoreProvider);
    } catch (_) {
      return const SizedBox.shrink();
    }

    final sync = ref.watch(syncStateProvider);
    if (sync.status != SyncStatus.offline &&
        sync.status != SyncStatus.error) {
      return const SizedBox.shrink();
    }

    final isOffline = sync.status == SyncStatus.offline;
    final bg = isOffline ? const Color(0xFF5D4037) : const Color(0xFF4E342E);
    final label = sync.message.isNotEmpty
        ? sync.message
        : (isOffline
            ? 'Hors ligne — données locales'
            : 'Sync partielle — cache local');

    return Material(
      color: bg,
      child: InkWell(
        onTap: () => ref.read(syncStateProvider.notifier).syncNow(force: true),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Icon(
                isOffline
                    ? Icons.cloud_off_rounded
                    : Icons.sync_problem_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
              ),
              if (sync.localCourses > 0 || sync.localDocuments > 0)
                Text(
                  '${sync.localCourses} cours · ${sync.localDocuments} docs',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(width: 6),
              Icon(
                Icons.refresh_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
