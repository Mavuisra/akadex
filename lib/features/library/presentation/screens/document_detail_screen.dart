import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/timeline_tokens.dart';
import '../../../../core/widgets/feed_subpage_scaffold.dart';
import '../../../../core/widgets/ma_fac_document_row.dart';
import '../../../../core/widgets/moderation_chip.dart';
import '../../../../core/widgets/document_rate_button.dart';
import '../../../../core/widgets/timeline/pdf_page_carousel.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/mappers/mappers.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/document_type.dart';
import '../../../../domain/models/models.dart';

/// Détail document : aperçu horizontal + notes fac + téléchargement verrouillé.
class DocumentDetailScreen extends ConsumerWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = TimelineTokens.of(context);
    final docAsync = ref.watch(documentProvider(documentId));

    return docAsync.when(
      loading: () => Scaffold(
        backgroundColor: feed.feedBg,
        body: const Center(child: CupertinoActivityIndicator()),
      ),
      error: (e, _) => FeedSubpageScaffold(
        title: 'Document',
        body: Center(child: Text(apiErrorMessage(e))),
      ),
      data: (doc) => _DocumentDetailBody(documentId: documentId, doc: doc),
    );
  }
}

class _DocumentDetailBody extends ConsumerStatefulWidget {
  const _DocumentDetailBody({
    required this.documentId,
    required this.doc,
  });

  final String documentId;
  final AcademicDocument doc;

  @override
  ConsumerState<_DocumentDetailBody> createState() =>
      _DocumentDetailBodyState();
}

class _DocumentDetailBodyState extends ConsumerState<_DocumentDetailBody> {
  bool _downloading = false;

  AcademicDocument get doc => widget.doc;

  bool get _canDownload {
    if (doc.canDownload) return true;
    final me = ref.read(authStateProvider).valueOrNull;
    if (me == null) return false;
    // Auteur / staff : accès au fichier même avant 10 validations.
    if (doc.authorId.isNotEmpty && doc.authorId == me.id) return true;
    return me.role == 'admin' || me.role == 'teacher';
  }

  Future<void> _download() async {
    if (!_canDownload) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Téléchargement après ${doc.peerValidationsRequired} notes '
            '(${doc.peerValidationCount}/${doc.peerValidationsRequired}).',
          ),
        ),
      );
      return;
    }

    setState(() => _downloading = true);
    try {
      final payload = await ref
          .read(academicRepositoryProvider)
          .downloadDocument(widget.documentId);
      if (!mounted) return;

      final url = absoluteMediaUrl(
        payload['file'] ?? payload['external_url'] ?? doc.previewUrl,
      );
      if (url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fichier introuvable.')),
        );
        return;
      }

      ref.invalidate(documentProvider(widget.documentId));
      await context.push(
        '/pdf-reader',
        extra: {'url': url, 'title': doc.title},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _openPreview() {
    final url = doc.previewUrl;
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun fichier à prévisualiser.')),
      );
      return;
    }
    // Preview libre ; téléchargement reste verrouillé séparément.
    context.push('/pdf-reader', extra: {'url': url, 'title': doc.title});
  }

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    final remaining =
        (doc.peerValidationsRequired - doc.peerValidationCount).clamp(0, 999);

    return FeedSubpageScaffold(
      title: 'Document',
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          FeedPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (doc.authorId.isEmpty) return;
                          context.push('/alumni/profile/${doc.authorId}');
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: feed.softTint,
                              child: Text(
                                doc.author.isEmpty
                                    ? '?'
                                    : doc.author.characters.first.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: feed.linkBlue,
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: feed.ink,
                                    ),
                                  ),
                                  Text(
                                    doc.type.label,
                                    style: TextStyle(
                                      color: feed.meta,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (doc.canPeerValidate || doc.userHasPeerValidated) ...[
                      const SizedBox(width: 8),
                      DocumentRateButton(
                        doc: doc,
                        compact: true,
                        onRated: (_) {
                          ref.invalidate(documentProvider(widget.documentId));
                          ref.invalidate(peerReviewQueueProvider);
                          ref.invalidate(documentsProvider);
                        },
                      ),
                    ],
                    const SizedBox(width: 6),
                    ModerationChip(status: doc.moderationStatus),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  doc.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: feed.ink,
                    height: 1.25,
                  ),
                ),
                if (doc.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    doc.description,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: feed.ink,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  [
                    if (doc.university.isNotEmpty) doc.university,
                    if (doc.department.isNotEmpty) doc.department,
                    if (doc.course.isNotEmpty) doc.course,
                    if (doc.year.isNotEmpty) doc.year,
                  ].join(' · '),
                  style: TextStyle(color: feed.meta, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  '${formatCount(doc.downloads)} téléch. · '
                  '${formatCount(doc.views)} vues'
                  '${doc.sizeLabel.isEmpty || doc.sizeLabel == '—' ? '' : ' · ${doc.sizeLabel}'}',
                  style: TextStyle(
                    color: feed.meta,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ── Aperçu document (scroll horizontal) ──
          FeedPanel(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        'Aperçu',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: feed.ink,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Glisse pour feuilleter',
                        style: TextStyle(color: feed.meta, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (doc.hasPreviewFile)
                  PdfPageCarousel(
                    url: doc.previewUrl,
                    height: 280,
                    onOpen: _openPreview,
                  )
                else
                  _EmptyPreview(type: doc.type),
              ],
            ),
          ),

          // ── Notes fac + notation ──
          FeedPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'Notes de ta faculté',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: feed.ink,
                      ),
                    ),
                    const Spacer(),
                    if (doc.canPeerValidate || doc.userHasPeerValidated)
                      DocumentRateButton(
                        doc: doc,
                        compact: true,
                        onRated: (_) {
                          ref.invalidate(documentProvider(widget.documentId));
                          ref.invalidate(peerReviewQueueProvider);
                          ref.invalidate(documentsProvider);
                        },
                      ),
                    if (doc.rating > 0) ...[
                      if (doc.canPeerValidate || doc.userHasPeerValidated)
                        const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            doc.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: feed.ink,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: doc.peerValidationProgress,
                    minHeight: 8,
                    backgroundColor: feed.feedBg,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${doc.peerValidationCount} / ${doc.peerValidationsRequired} notes'
                  '${doc.awaitsAdminReview ? ' · en attente admin' : ''}'
                  '${doc.isApproved ? ' · approuvé' : ''}',
                  style: TextStyle(
                    color: feed.meta,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!doc.canDownload && !doc.isApproved && !_canDownload) ...[
                  const SizedBox(height: 6),
                  Text(
                    remaining == 0
                        ? '10 notes atteintes — téléchargement bientôt disponible.'
                        : 'Encore $remaining note${remaining > 1 ? 's' : ''} '
                            'avant le téléchargement.',
                    style: TextStyle(
                      color: feed.meta,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (doc.isApproved && doc.pointsAwarded > 0)
            FeedPanel(
              child: Row(
                children: [
                  Icon(Icons.verified_rounded, color: feed.linkBlue, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Validé · +${doc.pointsAwarded} pts pour l’auteur',
                      style: TextStyle(
                        color: feed.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Télécharger (verrouillé jusqu’à 10) ──
          FeedPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _canDownload && !_downloading ? _download : null,
                    icon: Icon(
                      _canDownload
                          ? Icons.download_outlined
                          : Icons.lock_outline_rounded,
                      size: 20,
                    ),
                    label: Text(
                      _downloading
                          ? 'Ouverture…'
                          : _canDownload
                              ? 'Télécharger'
                              : 'Télécharger '
                                  '(${doc.peerValidationCount}/'
                                  '${doc.peerValidationsRequired})',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: feed.linkBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: feed.commentBubble,
                      disabledForegroundColor: feed.meta,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                if (!_canDownload) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: feed.meta),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Le fichier reste en aperçu seulement. '
                          'Le téléchargement s’ouvre après '
                          '${doc.peerValidationsRequired} notes de la faculté.',
                          style: TextStyle(
                            color: feed.meta,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({required this.type});

  final DocumentType type;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    return Container(
      height: 220,
      color: feed.feedBg,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DocumentTypeThumbnail(type: type, size: 56),
          const SizedBox(height: 12),
          Text(
            'Fichier non disponible en aperçu',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: feed.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'L’auteur n’a pas joint de PDF consultable.',
            style: TextStyle(color: feed.meta, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
