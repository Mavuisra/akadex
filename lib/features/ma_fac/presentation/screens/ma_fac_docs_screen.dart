import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
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
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          cat?.label ?? 'Documents',
          style: const TextStyle(fontWeight: FontWeight.w800),
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
              Text(apiErrorMessage(e)),
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
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'Aucun document dans cette catégorie pour ton parcours.\nTu peux en partager via Contribuer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AkadexColors.inkMuted, height: 1.4),
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
                        color: AkadexColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_outlined,
                        color: AkadexColors.primary,
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
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${doc.type.label} · ${doc.downloads} téléchargements',
                            style: const TextStyle(
                              color: AkadexColors.inkMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AkadexColors.inkSoft,
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

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Cours de ma promo',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: coursesAsync.when(
        loading: () => const LearnScreenSkeleton(cardCount: 4),
        error: (e, _) => Center(child: Text(apiErrorMessage(e))),
        data: (all) {
          // Même filtre que l’accueil Ma Fac.
          final courses = MaFacScreen.filterCourses(all, me);
          if (courses.isEmpty) {
            return const Center(
              child: Text(
                'Aucun cours pour ton parcours.',
                style: TextStyle(color: AkadexColors.inkMuted),
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
                onTap: () => context.push('/library/course/${c.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        c.code,
                        c.displayTeacher,
                        if (c.targetPromotion.isNotEmpty) c.targetPromotion,
                      ].where((e) => e.isNotEmpty).join(' · '),
                      style: const TextStyle(
                        color: AkadexColors.inkMuted,
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
