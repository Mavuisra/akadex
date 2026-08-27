import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/timeline_tokens.dart';
import '../../../../core/widgets/shimmer_skeletons.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/models.dart';
import '../../data/cart_provider.dart';
import '../../data/learn_domains.dart';
import '../widgets/course_udemy_card.dart';

/// Onglet Apprendre : stories domaines + aperçu cours (style Facebook / Udemy).
class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);
    final domains =
        ref.watch(learningDomainsProvider).valueOrNull ?? LearnDomains.fallback;
    final me = ref.watch(authStateProvider).valueOrNull;
    final courses = coursesAsync.valueOrNull ?? const <Course>[];
    final busy = coursesAsync.isLoading && courses.isEmpty;
    final failed = coursesAsync.hasError && courses.isEmpty;
    final feed = TimelineTokens.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    if (busy) {
      return Scaffold(
        backgroundColor: feed.feedBg,
        body: const LearnScreenSkeleton(),
      );
    }

    if (failed) {
      return Scaffold(
        backgroundColor: feed.feedBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  apiErrorMessage(coursesAsync.error!),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: feed.ink),
                ),
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

    final counts = LearnDomains.vitrineCounts(courses, domains);
    final trending = LearnDomains.vitrineCourses(courses, limit: 3);

    return Scaffold(
      backgroundColor: feed.feedBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: feed.cardBg,
            surfaceTintColor: Colors.transparent,
            foregroundColor: feed.ink,
            title: Text(
              'Apprendre',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: feed.ink,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Panier',
                onPressed: () => context.push('/cart'),
                icon: Badge(
                  isLabelVisible: ref.watch(cartProvider).isNotEmpty,
                  label: Text('${ref.watch(cartProvider).length}'),
                  child: Icon(Icons.shopping_cart_outlined, color: feed.ink),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              color: feed.cardBg,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: feed.softTint,
                    backgroundImage: me?.avatarUrl != null &&
                            me!.avatarUrl!.isNotEmpty
                        ? NetworkImage(me.avatarUrl!)
                        : null,
                    child: me?.avatarUrl == null || me!.avatarUrl!.isEmpty
                        ? Text(
                            (me?.name.isNotEmpty == true ? me!.name[0] : '?')
                                .toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: primary,
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
                          color: feed.feedBg,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          'Rechercher un cours, module ou domaine…',
                          style: TextStyle(
                            color: feed.meta,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(
            child: Container(
              color: feed.cardBg,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: DomainStoriesRow(
                domains: domains,
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
              color: feed.cardBg,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Cours vidéo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: feed.ink,
                ),
              ),
            ),
          ),
          if (trending.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Aucun cours vidéo pour le moment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: feed.meta),
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
