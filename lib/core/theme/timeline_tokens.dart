import 'package:flutter/material.dart';

/// Couleurs du feed Accueil / Ma Fac (light + dark).
@immutable
class AkadexFeedColors extends ThemeExtension<AkadexFeedColors> {
  const AkadexFeedColors({
    required this.cardBg,
    required this.feedBg,
    required this.divider,
    required this.meta,
    required this.action,
    required this.likeActive,
    required this.commentBubble,
    required this.linkBlue,
    required this.ink,
    required this.softTint,
  });

  final Color cardBg;
  final Color feedBg;
  final Color divider;
  final Color meta;
  final Color action;
  final Color likeActive;
  final Color commentBubble;
  final Color linkBlue;
  final Color ink;
  final Color softTint;

  /// Look Facebook d’origine (thème clair).
  static const light = AkadexFeedColors(
    cardBg: Colors.white,
    feedBg: Color(0xFFF0F2F5),
    divider: Color(0xFFCED0D4),
    meta: Color(0xFF65676B),
    action: Color(0xFF65676B),
    likeActive: Color(0xFF1877F2),
    commentBubble: Color(0xFFF0F2F5),
    linkBlue: Color(0xFF1A47B8),
    ink: Color(0xFF050505),
    softTint: Color(0xFFE8EEF8),
  );

  static const dark = AkadexFeedColors(
    cardBg: Color(0xFF1A1A1A),
    feedBg: Color(0xFF0E0E0E),
    divider: Color(0xFF2C2C2C),
    meta: Color(0xFF8A8A8A),
    action: Color(0xFF8A8A8A),
    likeActive: Color(0xFF4A83D4),
    commentBubble: Color(0xFF242424),
    linkBlue: Color(0xFF4A83D4),
    ink: Color(0xFFFFFFFF),
    softTint: Color(0xFF242424),
  );

  @override
  AkadexFeedColors copyWith({
    Color? cardBg,
    Color? feedBg,
    Color? divider,
    Color? meta,
    Color? action,
    Color? likeActive,
    Color? commentBubble,
    Color? linkBlue,
    Color? ink,
    Color? softTint,
  }) {
    return AkadexFeedColors(
      cardBg: cardBg ?? this.cardBg,
      feedBg: feedBg ?? this.feedBg,
      divider: divider ?? this.divider,
      meta: meta ?? this.meta,
      action: action ?? this.action,
      likeActive: likeActive ?? this.likeActive,
      commentBubble: commentBubble ?? this.commentBubble,
      linkBlue: linkBlue ?? this.linkBlue,
      ink: ink ?? this.ink,
      softTint: softTint ?? this.softTint,
    );
  }

  @override
  AkadexFeedColors lerp(ThemeExtension<AkadexFeedColors>? other, double t) {
    if (other is! AkadexFeedColors) return this;
    return AkadexFeedColors(
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      feedBg: Color.lerp(feedBg, other.feedBg, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      meta: Color.lerp(meta, other.meta, t)!,
      action: Color.lerp(action, other.action, t)!,
      likeActive: Color.lerp(likeActive, other.likeActive, t)!,
      commentBubble: Color.lerp(commentBubble, other.commentBubble, t)!,
      linkBlue: Color.lerp(linkBlue, other.linkBlue, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      softTint: Color.lerp(softTint, other.softTint, t)!,
    );
  }
}

/// Tokens UI : Facebook (feed / interactions) + LinkedIn (docs / méta).
///
/// Préférer [of] pour le thème actif. Les `static const` = look clair d’origine
/// (fallback / usages const).
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
  static const double cardRadius = 10;
  static const double chipRadius = 16;
  static const double commentRadius = 18;

  /// Tabs / chips : aucune bordure visible (light + dark, sélectionné ou non).
  static const BorderSide tabBorderSide = BorderSide(
    color: Colors.transparent,
    width: 0,
  );
  static const Border tabBorder = Border.fromBorderSide(tabBorderSide);

  static AkadexFeedColors of(BuildContext context) {
    final ext = Theme.of(context).extension<AkadexFeedColors>();
    if (ext != null) return ext;
    return Theme.of(context).brightness == Brightness.dark
        ? AkadexFeedColors.dark
        : AkadexFeedColors.light;
  }

  // Look clair d’origine (const / fallback).
  static const Color cardBg = Colors.white;
  static const Color feedBg = Color(0xFFF0F2F5);
  static const Color divider = Color(0xFFCED0D4);
  static const Color meta = Color(0xFF65676B);
  static const Color action = Color(0xFF65676B);
  static const Color likeActive = Color(0xFF1877F2);
  static const Color commentBubble = Color(0xFFF0F2F5);
  static const Color linkBlue = Color(0xFF1A47B8);
  static const Color ink = Color(0xFF050505);
  static const Color softTint = Color(0xFFE8EEF8);

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
