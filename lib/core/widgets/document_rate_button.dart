import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_client.dart';
import '../../data/repositories/repositories.dart';
import '../../domain/models/models.dart';
import '../theme/timeline_tokens.dart';

/// Noter un document (1–5 ★). 10 notes fac → validation admin.
class DocumentRateButton extends ConsumerStatefulWidget {
  const DocumentRateButton({
    super.key,
    required this.doc,
    this.compact = false,
    this.onRated,
  });

  final AcademicDocument doc;
  final bool compact;
  final ValueChanged<AcademicDocument>? onRated;

  @override
  ConsumerState<DocumentRateButton> createState() => _DocumentRateButtonState();
}

class _DocumentRateButtonState extends ConsumerState<DocumentRateButton> {
  bool _busy = false;
  AcademicDocument? _latest;

  AcademicDocument get _doc => _latest ?? widget.doc;

  @override
  void didUpdateWidget(covariant DocumentRateButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.doc.id != widget.doc.id ||
        oldWidget.doc.peerValidationCount != widget.doc.peerValidationCount ||
        oldWidget.doc.canPeerValidate != widget.doc.canPeerValidate ||
        oldWidget.doc.userHasPeerValidated != widget.doc.userHasPeerValidated ||
        oldWidget.doc.userRating != widget.doc.userRating) {
      _latest = null;
    }
  }

  Future<void> _submit(int score) async {
    if (_busy || !_doc.canPeerValidate) return;
    setState(() => _busy = true);
    try {
      final updated = await ref
          .read(academicRepositoryProvider)
          .rateDocument(_doc.id, score: score);
      if (!mounted) return;
      setState(() => _latest = updated);
      ref.invalidate(documentProvider(_doc.id));
      ref.invalidate(peerReviewQueueProvider);
      ref.invalidate(documentsProvider);
      ref.invalidate(notificationsProvider);
      widget.onRated?.call(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Note enregistrée ($score/5) · '
            '${updated.peerValidationCount}/${updated.peerValidationsRequired} notes',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickAndRate() async {
    if (_busy || !_doc.canPeerValidate) return;
    final score = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _RateSheet(
        title: _doc.title,
        initial: 4,
      ),
    );
    if (score != null) await _submit(score);
  }

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    final doc = _doc;

    if (doc.userHasPeerValidated && doc.userRating > 0) {
      return _RatedBadge(score: doc.userRating, compact: widget.compact);
    }

    if (!doc.canPeerValidate) {
      if (doc.awaitsPeerReview || doc.awaitsAdminReview) {
        return _CountBadge(
          count: doc.peerValidationCount,
          required: doc.peerValidationsRequired,
          avg: doc.rating,
        );
      }
      return const SizedBox.shrink();
    }

    if (widget.compact) {
      return SizedBox(
        height: 34,
        child: FilledButton.icon(
          onPressed: _busy ? null : _pickAndRate,
          icon: _busy
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                )
              : const Icon(Icons.star_rounded, size: 16),
          label: Text(_busy ? '…' : 'Noter'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minimumSize: const Size(72, 34),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ta note',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: feed.ink,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                onPressed: _busy ? null : () => _submit(i),
                icon: Icon(
                  Icons.star_rounded,
                  color: const Color(0xFFF59E0B),
                  size: 32,
                ),
              ),
            const Spacer(),
            if (_busy)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        Text(
          '${doc.peerValidationCount}/${doc.peerValidationsRequired} notes fac · '
          'moy. ${doc.rating.toStringAsFixed(1)}/5',
          style: TextStyle(color: feed.meta, fontSize: 12),
        ),
      ],
    );
  }
}

class _RateSheet extends StatefulWidget {
  const _RateSheet({required this.title, required this.initial});

  final String title;
  final int initial;

  @override
  State<_RateSheet> createState() => _RateSheetState();
}

class _RateSheetState extends State<_RateSheet> {
  late int _score;

  @override
  void initState() {
    super.initState();
    _score = widget.initial.clamp(1, 5);
  }

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Noter ce document',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: feed.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(color: feed.meta, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => setState(() => _score = i),
                  icon: Icon(
                    i <= _score ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 36,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, _score),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Envoyer $_score/5',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatedBadge extends StatelessWidget {
  const _RatedBadge({required this.score, required this.compact});

  final int score;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: compact ? 14 : 16,
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 4),
          Text(
            '$score/5',
            style: TextStyle(
              color: const Color(0xFFB45309),
              fontWeight: FontWeight.w800,
              fontSize: compact ? 12 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.count,
    required this.required,
    required this.avg,
  });

  final int count;
  final int required;
  final double avg;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count/$required',
          style: TextStyle(
            color: feed.meta,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        if (avg > 0)
          Text(
            '${avg.toStringAsFixed(1)} ★',
            style: TextStyle(color: feed.meta, fontSize: 11),
          ),
      ],
    );
  }
}

/// Alias rétrocompatibilité.
typedef PeerValidateButton = DocumentRateButton;
