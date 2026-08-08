import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/timeline_tokens.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/repositories/repositories.dart';
import '../../data/learn_domains.dart';
import '../widgets/course_udemy_card.dart';

/// Liste des cours d’un domaine (style Udemy « Trending courses »).
class DomainCoursesScreen extends ConsumerWidget {
  const DomainCoursesScreen({super.key, required this.domainId});

  final String domainId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final domain = LearnDomains.byId(domainId);
    final coursesAsync = ref.watch(coursesProvider);
    final feed = TimelineTokens.of(context);

    if (domain == null) {
      return Scaffold(
        backgroundColor: feed.feedBg,
        appBar: AppBar(
          backgroundColor: feed.cardBg,
          foregroundColor: feed.ink,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: Center(
          child: Text('Domaine introuvable.', style: TextStyle(color: feed.ink)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: feed.feedBg,
      appBar: AppBar(
        backgroundColor: feed.cardBg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: feed.ink,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          domain.name,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: feed.ink,
          ),
        ),
      ),
      body: coursesAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(
          child: Text(apiErrorMessage(e), style: TextStyle(color: feed.ink)),
        ),
        data: (all) {
          final courses = LearnDomains.filterCourses(all, domain);
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cours tendance',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color.lerp(
                            domain.colors.first,
                            feed.ink,
                            0.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${courses.length} cours · ${domain.name}',
                        style: TextStyle(
                          color: feed.meta,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (courses.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Aucun cours vidéo dans ce domaine pour l’instant.\n'
                        'Les UE de ta fac restent dans Ma Fac ; ici ce sont '
                        'uniquement les ressources Apprendre.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: feed.meta, height: 1.4),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  sliver: SliverList.separated(
                    itemCount: courses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => CourseUdemyCard(course: courses[i]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
