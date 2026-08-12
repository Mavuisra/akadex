import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/timeline_tokens.dart';
import '../../../../core/widgets/feed_subpage_scaffold.dart';
import '../../../../core/widgets/ma_fac_document_row.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/repositories/repositories.dart';

class PeerReviewScreen extends ConsumerWidget {
  const PeerReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = TimelineTokens.of(context);
    final queueAsync = ref.watch(peerReviewQueueProvider);

    return FeedSubpageScaffold(
      title: 'À noter',
      body: queueAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  apiErrorMessage(e),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: feed.ink),
                ),
                const SizedBox(height: 12),
                FeedPrimaryButton(
                  label: 'Réessayer',
                  onPressed: () => ref.invalidate(peerReviewQueueProvider),
                ),
              ],
            ),
          ),
        ),
        data: (docs) {
          if (docs.isEmpty) {
            return FeedEmptyState(
              icon: Icons.fact_check_outlined,
              title: 'Rien à noter',
              message:
                  'Aucun document de ta faculté n’attend ta note.',
              actionLabel: 'Ma Fac',
              onAction: () => context.go('/library'),
            );
          }

          return RefreshIndicator(
            color: feed.linkBlue,
            onRefresh: () async => ref.invalidate(peerReviewQueueProvider),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final doc = docs[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  decoration: BoxDecoration(
                    color: feed.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: feed.divider),
                  ),
                  child: MaFacDocumentRow(
                    doc: doc,
                    onOpen: () => context.push('/library/document/${doc.id}'),
                    onValidated: (_) {
                      ref.invalidate(peerReviewQueueProvider);
                      ref.invalidate(documentProvider(doc.id));
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
