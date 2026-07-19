import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/repositories/repositories.dart';

class ExplorerScreen extends ConsumerStatefulWidget {
  const ExplorerScreen({super.key});

  @override
  ConsumerState<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends ConsumerState<ExplorerScreen> {
  String _filter = 'Universités';
  static const _filters = ['Universités', 'Départements'];

  @override
  Widget build(BuildContext context) {
    final unisAsync = ref.watch(universitiesProvider);
    final depsAsync = ref.watch(departmentsProvider(null));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(universitiesProvider);
            ref.invalidate(departmentsProvider(null));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              const Text(
                'Explorer',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              SearchField(
                hint: 'Rechercher…',
                readOnly: true,
                onTap: () => context.push('/search'),
              ),
              const SizedBox(height: 12),
              FilterChipBar(
                items: _filters,
                selected: _filter,
                onSelected: (v) => setState(() => _filter = v),
              ),
              const SizedBox(height: 16),
              if (_filter == 'Universités')
                unisAsync.when(
                  loading: () => const Center(child: CupertinoActivityIndicator()),
                  error: (e, _) => Text(apiErrorMessage(e)),
                  data: (unis) => Column(
                    children: [
                      for (final u in unis)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SoftCard(
                            onTap: () => context.go('/library'),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AkadexColors.primarySoft,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                      child: Text(
                                      (u.slug.length >= 3
                                              ? u.slug.substring(0, 3)
                                              : u.slug)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: AkadexColors.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        u.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '${u.city}, ${u.country}',
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
                  ),
                )
              else
                depsAsync.when(
                  loading: () => const Center(child: CupertinoActivityIndicator()),
                  error: (e, _) => Text(apiErrorMessage(e)),
                  data: (deps) => Column(
                    children: [
                      for (final d in deps)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SoftCard(
                            onTap: () => context.go('/library'),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AkadexColors.primarySoft,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.account_tree_outlined,
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
                                        d.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        d.facultyName,
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
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
