import 'package:flutter/material.dart';

import '../theme/akadex_theme.dart';

/// Chip compact « Suivre / Suivi » (style LinkedIn / Instagram).
class FollowChip extends StatelessWidget {
  const FollowChip({
    super.key,
    required this.following,
    required this.onPressed,
    this.compact = false,
  });

  final bool following;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final h = compact ? 28.0 : 32.0;
    final padH = compact ? 12.0 : 14.0;
    final fontSize = compact ? 12.0 : 13.0;

    if (following) {
      return SizedBox(
        height: h,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AkadexColors.inkMuted,
            side: const BorderSide(color: AkadexColors.border),
            padding: EdgeInsets.symmetric(horizontal: padH),
            minimumSize: Size(0, h),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(h / 2),
            ),
          ),
          child: Text(
            'Suivi',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: h,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AkadexColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: padH),
          minimumSize: Size(0, h),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(h / 2),
          ),
        ),
        child: Text(
          'Suivre',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
