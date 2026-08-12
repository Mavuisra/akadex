import 'package:flutter/material.dart';

import '../theme/timeline_tokens.dart';
import 'moderation_chip.dart';

/// Sous-titre document : type, téléchargements, validations fac.
class DocumentFeedMeta extends StatelessWidget {
  const DocumentFeedMeta({
    super.key,
    required this.typeLabel,
    required this.downloads,
    required this.moderationStatus,
    required this.isApproved,
    required this.peerValidationCount,
    required this.peerValidationsRequired,
  });

  final String typeLabel;
  final int downloads;
  final String moderationStatus;
  final bool isApproved;
  final int peerValidationCount;
  final int peerValidationsRequired;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    final parts = <String>[typeLabel];

    if (!isApproved &&
        (moderationStatus == 'pending_peers' ||
            moderationStatus == 'pending' ||
            moderationStatus == 'pending_admin')) {
      parts.add(
        '$peerValidationCount/$peerValidationsRequired notes',
      );
    } else if (downloads > 0) {
      parts.add('$downloads téléch.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isApproved &&
            moderationStatus != 'rejected' &&
            moderationStatus != 'approved')
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: ModerationChip(status: moderationStatus),
          ),
        Text(
          parts.join(' · '),
          style: TextStyle(color: feed.meta, fontSize: 12),
        ),
      ],
    );
  }
}
