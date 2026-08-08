import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/timeline_tokens.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/shimmer_skeletons.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/document_type.dart';
import '../../data/ma_fac_categories.dart';
import 'ma_fac_screen.dart';

/// Liste des documents d’une catégorie Ma Fac (filtrés au parcours).
class MaFacDocsScreen extends ConsumerWidget {
  const MaFacDocsScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = MaFacCategories.byId(categoryId);
    final me = ref.watch(authStateProvider).valueOrNull;
    final feed = TimelineTokens.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final docsAsync = ref.watch(
      documentsProvider(
        DocumentQuery(
          universityId:
              me?.universityId.isNotEmpty == true ? me!.universityId : null,
          departmentId:
              me?.departmentId.isNotEmpty == true ? me!.departmentId : null,
          facultyId: me?.facultyId.isNotEmpty == true ? me!.facultyId : null,
          ordering: '-created_at',
        ),
      ),
    );

    return Scaffold(
      backgroundColor: feed.feedBg,
      appBar: AppBar(
        backgroundColor: feed.cardBg,
        foregroundColor: feed.ink,
        surfaceTintColor: Colors.transparent,
        title: Text(
          cat?.label ?? 'Documents',
          style: TextStyle(fontWeight: FontWeight.w800, color: feed.ink),
        ),
      ),
      body: docsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: ListFeedSkeleton(count: 8),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(apiErrorMessage(e), style: TextStyle(color: feed.ink)),
              TextButton(
                onPressed: () => ref.invalidate(documentsProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (docs) {
          final filtered = cat == null
              ? docs
              : docs.where((d) => cat.matches(d.type)).toList();
          if (filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  'Aucun document dans cette catégorie pour ton parcours.\nTu peux en partager via Contribuer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: feed.meta, height: 1.4),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final doc = filtered[i];
              return SoftCard(
                onTap: () => context.push('/library/document/${doc.id}'),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: feed.softTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.picture_as_pdf_outlined,
                        color: primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: feed.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${doc.type.label} · ${doc.downloads} téléchargements',
                            style: TextStyle(
                              color: feed.meta,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: feed.meta,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Tous les cours du parcours étudiant.
class MaFacCoursesScreen extends ConsumerWidget {
  const MaFacCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authStateProvider).valueOrNull;
    final coursesAsync = ref.watch(coursesProvider);
    final feed = TimelineTokens.of(context);

    return Scaffold(
      backgroundColor: feed.feedBg,
      appBar: AppBar(
        backgroundColor: feed.cardBg,
        foregroundColor: feed.ink,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Cours de ma promo',
          style: TextStyle(fontWeight: FontWeight.w800, color: feed.ink),
        ),
      ),
      body: coursesAsync.when(
        loading: () => const LearnScreenSkeleton(cardCount: 4),
        error: (e, _) => Center(
          child: Text(apiErrorMessage(e), style: TextStyle(color: feed.ink)),
        ),
        data: (all) {
          final courses = MaFacScreen.filterCourses(all, me);
          if (courses.isEmpty) {
            return Center(
              child: Text(
                'Aucun cours pour ton parcours.',
                style: TextStyle(color: feed.meta),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            itemCount: courses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final c = courses[i];
              return SoftCard(
                onTap: () => context.push('/library/ue/${c.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: feed.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        c.code,
                        c.displayTeacher,
                        if (c.targetPromotion.isNotEmpty) c.targetPromotion,
                      ].where((e) => e.isNotEmpty).join(' · '),
                      style: TextStyle(
                        color: feed.meta,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
