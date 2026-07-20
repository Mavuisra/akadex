import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/shimmer_skeletons.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/repositories/repositories.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _filter = 'Tous';
  static const _filters = [
    'Tous',
    'L1',
    'L2',
    'L3',
    'Master 1',
    'Master 2',
  ];

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(coursesProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Bibliothèque',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/search'),
                    icon: const Icon(Icons.search_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FilterChipBar(
                items: _filters,
                selected: _filter,
                onSelected: (v) => setState(() => _filter = v),
              ),
              const SizedBox(height: 16),
              coursesAsync.when(
                loading: () => const ListFeedSkeleton(count: 6),
                error: (e, _) => SoftCard(
                  child: Column(
                    children: [
                      Text(apiErrorMessage(e), textAlign: TextAlign.center),
                      TextButton(
                        onPressed: () => ref.invalidate(coursesProvider),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
                data: (courses) {
                  final filtered = _filter == 'Tous'
                      ? courses
                      : courses.where((c) => c.semester == _filter).toList();
                  if (filtered.isEmpty) {
                    return const Text(
                      'Aucun cours trouvé.',
                      style: TextStyle(color: AkadexColors.inkMuted),
                    );
                  }
                  return Column(
                    children: [
                      for (final c in filtered)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SoftCard(
                            onTap: () =>
                                context.push('/library/course/${c.id}'),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AkadexColors.primarySoft,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.menu_book_rounded,
                                    color: AkadexColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${c.code} — ${c.title}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AkadexColors.ink,
                                        ),
                                      ),
                                      Text(
                                        '${c.department} · ${c.semester} · ${c.documentCount} docs',
                                        style: const TextStyle(
                                          color: AkadexColors.inkMuted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
