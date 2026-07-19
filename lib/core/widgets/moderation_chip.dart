import 'package:flutter/material.dart';

import '../../data/mappers/mappers.dart';
import '../theme/akadex_theme.dart';

/// Pastille de statut de modération (pending / approved / rejected).
class ModerationChip extends StatelessWidget {
  const ModerationChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'pending' => (const Color(0xFFFFF4E0), const Color(0xFF8A5A00)),
      'rejected' => (const Color(0xFFFDECEC), AkadexColors.danger),
      'approved' => (const Color(0xFFE6F7EF), AkadexColors.success),
      _ => (AkadexColors.primarySoft, AkadexColors.primary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        moderationStatusLabel(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
