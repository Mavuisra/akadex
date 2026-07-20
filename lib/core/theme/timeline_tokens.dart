import 'package:flutter/material.dart';

import 'akadex_theme.dart';

/// Tokens UI : Facebook (feed / interactions) + LinkedIn (docs / méta).
abstract final class TimelineTokens {
  // Typo
  static const double nameSize = 15;
  static const double metaSize = 12.5;
  static const double titleSize = 16;
  static const double bodySize = 15;
  static const double actionLabelSize = 13;
  static const double commentSize = 14;
  static const double lineHeightBody = 1.4;

  // Espacements FB-like
  static const double cardPadH = 12;
  static const double cardPadV = 12;
  static const double sectionGap = 8;
  static const double avatar = 40;
  static const double commentAvatar = 32;
  static const double iconAction = 20;
  static const double actionHeight = 40;
  static const double headerHeight = 56;
  static const double filterHeight = 44;
  static const double searchRadius = 20;
  /// Facebook mobile : cartes presque sans coins ; LinkedIn soft : 8.
  static const double cardRadius = 0;
  static const double chipRadius = 16;
  static const double commentRadius = 18;

  static const Color cardBg = Colors.white;
  static const Color feedBg = Color(0xFFF0F2F5);
  static const Color divider = Color(0xFFCED0D4);
  static const Color meta = Color(0xFF65676B);
  static const Color action = Color(0xFF65676B);
  static const Color likeActive = Color(0xFF1877F2);
  static const Color commentBubble = Color(0xFFF0F2F5);
  static const Color linkBlue = AkadexColors.primary;

  static EdgeInsets feedHorizontal(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 900) {
      final side = (w - 680) / 2;
      return EdgeInsets.symmetric(horizontal: side.clamp(24, 200));
    }
    if (w >= 600) return const EdgeInsets.symmetric(horizontal: 48);
    return EdgeInsets.zero;
  }
}
