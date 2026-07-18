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

class DocumentDetailScreen extends ConsumerWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docAsync = ref.watch(documentProvider(documentId));

    return docAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CupertinoActivityIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: Center(child: Text(apiErrorMessage(e))),
      ),
      data: (doc) => Scaffold(
        backgroundColor: AkadexColors.background,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 32),
              decoration: const BoxDecoration(
                color: AkadexColors.primary,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DocTypeTag(doc.type.label),
                          const SizedBox(height: 10),
                          Text(
                            doc.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${doc.author} · ${doc.year} · ${doc.sizeLabel}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  SoftCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Metric(
                          label: 'Téléch.',
                          value: formatCount(doc.downloads),
                        ),
                        _Metric(
                          label: 'Vues',
                          value: formatCount(doc.views),
                        ),
                        _Metric(
                          label: 'Favoris',
                          value: formatCount(doc.favorites),
                        ),
                        _Metric(
                          label: 'Note',
                          value: doc.rating.toStringAsFixed(1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'À propos',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          doc.description.isEmpty
                              ? 'Pas de description.'
                              : doc.description,
                          style: const TextStyle(
                            color: AkadexColors.inkMuted,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${doc.university} · ${doc.department}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        if (doc.course.isNotEmpty)
                          Text(
                            'Cours : ${doc.course}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AkadexColors.inkMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () async {
                      try {
                        await ref
                            .read(academicRepositoryProvider)
                            .downloadDocument(documentId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Téléchargement enregistré.'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(apiErrorMessage(e))),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Télécharger'),
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

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        Text(
          label,
          style: const TextStyle(color: AkadexColors.inkMuted, fontSize: 12),
        ),
      ],
    );
  }
}
