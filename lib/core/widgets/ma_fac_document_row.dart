import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/document_type.dart';
import '../../domain/models/models.dart';
import '../theme/timeline_tokens.dart';
import 'document_rate_button.dart';

/// Ligne document Ma Fac : aperçu + bouton Noter à droite.
class MaFacDocumentRow extends ConsumerWidget {
  const MaFacDocumentRow({
    super.key,
    required this.doc,
    required this.onOpen,
    this.onValidated,
    this.showDivider = false,
  });

  final AcademicDocument doc;
  final VoidCallback onOpen;
  final ValueChanged<AcademicDocument>? onValidated;
  final bool showDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = TimelineTokens.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onOpen,
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DocumentTypeThumbnail(type: doc.type),
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
                                  fontSize: 15,
                                  height: 1.25,
                                  color: feed.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _DocumentRowMeta(doc: doc),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _RowAction(
                doc: doc,
                onValidated: onValidated,
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: feed.divider),
      ],
    );
  }
}

class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.doc,
    this.onValidated,
  });

  final AcademicDocument doc;
  final ValueChanged<AcademicDocument>? onValidated;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);

    if (doc.canPeerValidate || doc.userHasPeerValidated) {
      return DocumentRateButton(
        doc: doc,
        compact: true,
        onRated: onValidated,
      );
    }

    if (!doc.isApproved && doc.awaitsPeerReview) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: feed.feedBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${doc.peerValidationCount}/${doc.peerValidationsRequired}',
          style: TextStyle(
            color: feed.meta,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );
    }

    return Icon(Icons.chevron_right_rounded, color: feed.meta, size: 22);
  }
}

class _DocumentRowMeta extends StatelessWidget {
  const _DocumentRowMeta({required this.doc});

  final AcademicDocument doc;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    final parts = <String>[doc.type.label];

    if (!doc.isApproved &&
        (doc.awaitsPeerReview || doc.awaitsAdminReview)) {
      parts.add(
        '${doc.peerValidationCount}/${doc.peerValidationsRequired} notes',
      );
    } else if (doc.downloads > 0) {
      parts.add('${doc.downloads} téléch.');
    }

    return Text(
      parts.join(' · '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: feed.meta,
        fontSize: 13,
        height: 1.3,
      ),
    );
  }
}

/// Mini aperçu document (style page PDF, pas une icône générique).
class DocumentTypeThumbnail extends StatelessWidget {
  const DocumentTypeThumbnail({
    super.key,
    required this.type,
    this.size = 48,
  });

  final DocumentType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    final style = _thumbStyle(type);
    final short = _shortLabel(type);

    return SizedBox(
      width: size,
      height: size * 1.15,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: feed.cardBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: feed.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 5,
                color: style.accent,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 2,
                        width: size * 0.55,
                        decoration: BoxDecoration(
                          color: feed.divider,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        height: 2,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: feed.divider.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const Spacer(),
                      Center(
                        child: Text(
                          short,
                          style: TextStyle(
                            fontSize: size * 0.22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                            color: style.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _shortLabel(DocumentType type) => switch (type) {
        DocumentType.examen => 'EX',
        DocumentType.interrogation => 'INT',
        DocumentType.tp => 'TP',
        DocumentType.corrige => 'COR',
        DocumentType.tfc => 'TFC',
        DocumentType.memoire => 'MEM',
        DocumentType.projetTutore => 'PT',
        DocumentType.projet => 'PRJ',
        DocumentType.rapport => 'RAP',
        DocumentType.resume => 'RES',
        DocumentType.supportCours => 'COUR',
        DocumentType.ficheRevision => 'FIC',
        DocumentType.these => 'TH',
        DocumentType.livre => 'LIV',
        _ => 'DOC',
      };

  static _ThumbStyle _thumbStyle(DocumentType type) => switch (type) {
        DocumentType.examen ||
        DocumentType.interrogation =>
          const _ThumbStyle(Color(0xFFDC2626)),
        DocumentType.tp => const _ThumbStyle(Color(0xFF2563EB)),
        DocumentType.corrige => const _ThumbStyle(Color(0xFF16A34A)),
        DocumentType.tfc ||
        DocumentType.memoire ||
        DocumentType.these =>
          const _ThumbStyle(Color(0xFF7C3AED)),
        DocumentType.projet ||
        DocumentType.projetTutore ||
        DocumentType.rapport =>
          const _ThumbStyle(Color(0xFFEA580C)),
        DocumentType.resume ||
        DocumentType.ficheRevision ||
        DocumentType.supportCours =>
          const _ThumbStyle(Color(0xFF0891B2)),
        _ => const _ThumbStyle(Color(0xFF64748B)),
      };
}

class _ThumbStyle {
  const _ThumbStyle(this.accent);
  final Color accent;
}
