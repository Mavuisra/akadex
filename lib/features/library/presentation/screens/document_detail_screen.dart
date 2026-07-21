import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/theme/timeline_tokens.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/mappers/mappers.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/document_type.dart';

/// Détail document — style feed Facebook (pas de hero bleu).
class DocumentDetailScreen extends ConsumerWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docAsync = ref.watch(documentProvider(documentId));

    return docAsync.when(
      loading: () => const Scaffold(
        backgroundColor: TimelineTokens.feedBg,
        body: Center(child: CupertinoActivityIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: TimelineTokens.feedBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: Center(child: Text(apiErrorMessage(e))),
      ),
      data: (doc) => Scaffold(
        backgroundColor: TimelineTokens.feedBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text(
            'Publication',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: ListView(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (doc.authorId.isEmpty) return;
                      context.push('/alumni/profile/${doc.authorId}');
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AkadexColors.primarySoft,
                          child: Text(
                            doc.author.isEmpty
                                ? '?'
                                : doc.author.characters.first.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AkadexColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.author.isEmpty ? 'Auteur' : doc.author,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: Color(0xFF050505),
                                ),
                              ),
                              Text(
                                doc.type.label,
                                style: const TextStyle(
                                  color: TimelineTokens.meta,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: TimelineTokens.meta,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    doc.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Color(0xFF050505),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    doc.description.isEmpty
                        ? 'Pas de description.'
                        : doc.description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: Color(0xFF050505),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    [
                      if (doc.university.isNotEmpty) doc.university,
                      if (doc.department.isNotEmpty) doc.department,
                      if (doc.course.isNotEmpty) doc.course,
                      if (doc.year.isNotEmpty) doc.year,
                    ].join(' · '),
                    style: const TextStyle(
                      color: TimelineTokens.meta,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${formatCount(doc.downloads)} téléch. · '
                    '${formatCount(doc.views)} vues · '
                    '${doc.sizeLabel}',
                    style: const TextStyle(
                      color: TimelineTokens.meta,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: TimelineTokens.divider),
                  SizedBox(
                    height: TimelineTokens.actionHeight,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () async {
                              try {
                                await ref
                                    .read(academicRepositoryProvider)
                                    .downloadDocument(documentId);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Téléchargement enregistré.',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(apiErrorMessage(e)),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.download_outlined),
                            label: const Text('Télécharger'),
                            style: TextButton.styleFrom(
                              foregroundColor: TimelineTokens.likeActive,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
