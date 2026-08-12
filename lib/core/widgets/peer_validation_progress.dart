import 'package:flutter/material.dart';

import '../theme/timeline_tokens.dart';

/// Barre de progression des validations fac (0–10).
class PeerValidationProgress extends StatelessWidget {
  const PeerValidationProgress({
    super.key,
    required this.count,
    required this.required,
    this.compact = false,
  });

  final int count;
  final int required;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    final progress = required <= 0 ? 0.0 : (count / required).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.verified_user_outlined, size: 18, color: feed.linkBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Notes fac : $count / $required',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: feed.ink,
                  fontSize: compact ? 13 : 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: compact ? 5 : 6,
            backgroundColor: feed.feedBg,
            color: feed.linkBlue,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 6),
          Text(
            count >= required
                ? 'En attente de validation admin Akadex'
                : 'Encore ${required - count} note(s) de ta fac avant validation',
            style: TextStyle(color: feed.meta, fontSize: 12, height: 1.35),
          ),
        ],
      ],
    );
  }
}
