import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/living_ui.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/mappers/mappers.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../data/sync/sync_service.dart';
import '../../../../domain/models/document_type.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _quick = [
    (Icons.account_balance_rounded, 'LMD', '/lmd'),
    (Icons.menu_book_rounded, 'Cours', '/search'),
    (Icons.assignment_rounded, 'Examens', '/search'),
    (Icons.science_rounded, 'TP / TD', '/search'),
    (Icons.auto_stories_rounded, 'Livres', '/search'),
    (Icons.play_circle_rounded, 'Vidéos', '/search'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(
      documentsProvider(const DocumentQuery(featuredOnly: true)),
    );
    final announcementsAsync = ref.watch(announcementsProvider);
    final sync = ref.watch(syncStateProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageAtmosphere(
        child: SafeArea(
          child: RefreshIndicator(
            color: AkadexColors.primary,
            onRefresh: () async {
              await ref.read(syncStateProvider.notifier).syncNow(force: true);
              ref.invalidate(documentsProvider);
              ref.invalidate(announcementsProvider);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                FadeSlideIn(
                  child: Row(
                    children: [
                      const Expanded(
                        child: AkadexBrandHeader(logoSize: 34, fontSize: 26),
                      ),
                      _SyncChip(sync: sync),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AkadexColors.border),
                        ),
                        child: IconButton(
                          onPressed: () => context.push('/calendar'),
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: AkadexColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 60),
                  child: SearchField(
                    hint: 'Rechercher un cours, document, prof…',
                    readOnly: true,
                    onTap: () => context.push('/search'),
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: LivingHeroBanner(
                    title: 'Bienvenue sur Akadex',
                    subtitle:
                        'Cours, examens et mentorat — ton campus numérique en un geste.',
                    ctaLabel: 'Explorer',
                    onCta: () => context.go('/library'),
                    trailing: const AkadexLogo(size: 68),
                  ),
                ),
                const SizedBox(height: 24),
                const FadeSlideIn(
                  delay: Duration(milliseconds: 160),
                  child: SectionTitle('Accès rapide'),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: SizedBox(
                    height: 108,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quick.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final q = _quick[i];
                        return SizedBox(
                          width: 88,
                          child: QuickAccessTile(
                            icon: q.$1,
                            label: q.$2,
                            onTap: () => context.push(q.$3),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const SectionTitle('Documents populaires'),
                const SizedBox(height: 12),
                docsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CupertinoActivityIndicator()),
                  ),
                  error: (e, _) => _ErrorBox(
                    message: apiErrorMessage(e),
                    onRetry: () => ref.invalidate(documentsProvider),
                  ),
                  data: (docs) {
                    if (docs.isEmpty) {
                      return const Text(
                        'Aucun document pour le moment.',
                        style: TextStyle(color: AkadexColors.inkMuted),
                      );
                    }
                    return Column(
                      children: [
                        for (var i = 0; i < docs.take(5).length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SoftCard(
                              delay: Duration(milliseconds: 40 * i),
                              onTap: () => context.push(
                                '/library/document/${docs[i].id}',
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AkadexColors.primarySoft,
                                          AkadexColors.accentSoft
                                              .withValues(alpha: 0.65),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.description_rounded,
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
                                          docs[i].title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: AkadexColors.ink,
                                          ),
                                        ),
                                        Text(
                                          '${docs[i].type.label} · ${formatCount(docs[i].downloads)} téléch.',
                                          style: const TextStyle(
                                            color: AkadexColors.inkMuted,
                                            fontSize: 13,
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
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                SoftCard(
                  accentBorder: true,
                  onTap: () => context.push('/ai'),
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    children: [
                      AkadexLogo(size: 40),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Akadex IA',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AkadexColors.ink,
                              ),
                            ),
                            Text(
                              'Ton assistant d’étude intelligent',
                              style: TextStyle(
                                color: AkadexColors.inkMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SoftCard(
                  onTap: () => context.push('/calendar'),
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    children: [
                      Icon(Icons.calendar_month_rounded,
                          color: AkadexColors.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Calendrier',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AkadexColors.ink,
                              ),
                            ),
                            Text(
                              'Examens, délibérations, événements',
                              style: TextStyle(
                                color: AkadexColors.inkMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const SectionTitle('Annonces'),
                const SizedBox(height: 12),
                announcementsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (items) => Column(
                    children: [
                      for (final a in items.take(3))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SoftCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DocTypeTag(a.category),
                                const SizedBox(height: 8),
                                Text(
                                  a.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  a.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AkadexColors.inkMuted,
                                    fontSize: 13,
                                  ),
                                ),
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
      ),
    );
  }
}

class _SyncChip extends ConsumerWidget {
  const _SyncChip({required this.sync});

  final SyncState sync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icon, label, color) = switch (sync.status) {
      SyncStatus.syncing => (
          Icons.sync_rounded,
          'Sync…',
          AkadexColors.primary,
        ),
      SyncStatus.offline => (
          Icons.cloud_off_rounded,
          'Hors ligne',
          Colors.orange.shade700,
        ),
      SyncStatus.error => (
          Icons.sync_problem_rounded,
          'Cache',
          Colors.orange.shade800,
        ),
      SyncStatus.online => (
          Icons.cloud_done_rounded,
          'À jour',
          Colors.teal.shade700,
        ),
      SyncStatus.idle => (
          Icons.cloud_outlined,
          sync.localCourses > 0 ? 'Local' : 'Sync',
          AkadexColors.inkMuted,
        ),
    };

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => ref.read(syncStateProvider.notifier).syncNow(force: true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AkadexColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sync.status == SyncStatus.syncing)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ],
      ),
    );
  }
}
