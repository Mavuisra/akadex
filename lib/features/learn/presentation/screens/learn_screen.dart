import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/theme/timeline_tokens.dart';
import '../../../../core/widgets/shimmer_skeletons.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/models.dart';
import '../../data/learn_domains.dart';
import '../widgets/course_udemy_card.dart';

/// Onglet Apprendre : stories domaines + aperçu cours (style Facebook / Udemy).
class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);
    final me = ref.watch(authStateProvider).valueOrNull;
    final courses = coursesAsync.valueOrNull ?? const <Course>[];
    final busy = coursesAsync.isLoading && courses.isEmpty;
    final failed = coursesAsync.hasError && courses.isEmpty;

    if (busy) {
      return const Scaffold(
        backgroundColor: Color(0xFFF0F2F5),
        body: LearnScreenSkeleton(),
      );
    }

    if (failed) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(apiErrorMessage(coursesAsync.error!), textAlign: TextAlign.center),
                TextButton(
                  onPressed: () => ref.invalidate(coursesProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final counts = <String, int>{
      for (final d in LearnDomains.all) d.id: courses.where(d.matches).length,
    };
    final trending = [
      ...courses.where((c) => c.code.startsWith('AKX-') && c.coverUrl.isNotEmpty),
      ...courses.where((c) => c.code.startsWith('AKX-') && c.coverUrl.isEmpty),
      ...courses.where((c) => !c.code.startsWith('AKX-')),
    ].take(8).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                title: const Text(
                  'Cours',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF050505),
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () => context.push('/lmd/assistant'),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AkadexColors.primarySoft,
                        backgroundImage: me?.avatarUrl != null &&
                                me!.avatarUrl!.isNotEmpty
                            ? NetworkImage(me.avatarUrl!)
                            : null,
                        child: me?.avatarUrl == null || me!.avatarUrl!.isEmpty
                            ? Text(
                                (me?.name.isNotEmpty == true
                                        ? me!.name[0]
                                        : '?')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AkadexColors.primary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/learn/search'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F2F5),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Text(
                              'Rechercher un cours, module ou domaine…',
                              style: TextStyle(
                                color: Color(0xFF65676B),
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        children: [
                          Icon(Icons.menu_book_outlined,
                              color: Colors.green.shade700, size: 22),
                          const SizedBox(height: 2),
                          Text(
                            'Cours',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: DomainStoriesRow(
                    domains: LearnDomains.all,
                    courseCounts: counts,
                    onTap: (domain) {
                      context.push('/learn/domain/${domain.id}');
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: const Text(
                    'Cours populaires',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D2F31),
                    ),
                  ),
                ),
              ),
              if (trending.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Aucun cours disponible pour le moment.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: TimelineTokens.meta),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList.separated(
                    itemCount: trending.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => CourseUdemyCard(course: trending[i]),
                  ),
                ),
            ],
          ),
    );
  }
}
