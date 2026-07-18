import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/mappers/mappers.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/document_type.dart';
import '../../../../domain/models/models.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _quick = [
    (Icons.menu_book_outlined, 'Cours', DocumentType.supportCours),
    (Icons.assignment_outlined, 'Examens', DocumentType.examen),
    (Icons.science_outlined, 'TP / TD', DocumentType.tp),
    (Icons.auto_stories_outlined, 'Livres', DocumentType.livre),
    (Icons.play_circle_outline, 'Vidéos', DocumentType.video),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(
      documentsProvider(const DocumentQuery(featuredOnly: true)),
    );
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(documentsProvider);
            ref.invalidate(announcementsProvider);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: AkadexBrandHeader(logoSize: 34, fontSize: 26),
                  ),
                  IconButton(
                    onPressed: () => context.push('/calendar'),
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SearchField(
                hint: 'Rechercher un cours, document, prof…',
                readOnly: true,
                onTap: () => context.push('/search'),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A47B8), Color(0xFF3B6BE0)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bienvenue sur Akadex',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tes ressources académiques\nen un seul endroit.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 14),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AkadexColors.primary,
                              minimumSize: const Size(0, 36),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                            ),
                            onPressed: () => context.go('/library'),
                            child: const Text('Explorer'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const AkadexLogo(size: 72),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionTitle('Accès rapide'),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final q in _quick)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: SoftCard(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          onTap: () => context.push('/search'),
                          child: Column(
                            children: [
                              Icon(q.$1, color: AkadexColors.primary, size: 22),
                              const SizedBox(height: 6),
                              Text(
                                q.$2,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AkadexColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
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
                      for (final doc in docs.take(5))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SoftCard(
                            onTap: () =>
                                context.push('/library/document/${doc.id}'),
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
                                    Icons.description_outlined,
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
                                        doc.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AkadexColors.ink,
                                        ),
                                      ),
                                      Text(
                                        '${doc.type.label} · ${formatCount(doc.downloads)} téléch.',
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
              const SizedBox(height: 16),
              SoftCard(
                onTap: () => context.push('/ai'),
                padding: const EdgeInsets.all(16),
                child: const Row(
                  children: [
                    AkadexLogo(size: 36),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Akadex IA',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
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
                    Icon(Icons.calendar_month_outlined,
                        color: AkadexColors.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calendrier',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
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
                error: (_, __) => const SizedBox.shrink(),
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
                                  fontWeight: FontWeight.w700,
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
