import 'package:flutter/material.dart';

import 'akadex_theme.dart';

/// Tokens visuels partagés Connexion / Inscription (layout type entrée).
abstract final class AuthEntryStyle {
  static Color background(bool isDark) =>
      isDark ? const Color(0xFF1C1E21) : AkadexColors.background;

  static Color fieldFill(bool isDark) =>
      isDark ? const Color(0xFF25272A) : Colors.white;

  static Color fieldBorder(bool isDark) =>
      isDark ? const Color(0xFF3A3B3C) : AkadexColors.border;

  static Color title(bool isDark) =>
      isDark ? AkadexColors.inkOnDark : AkadexColors.ink;

  static Color muted(bool isDark) =>
      isDark ? const Color(0xFFB0B3B8) : AkadexColors.inkMuted;

  static Color primary(bool isDark) =>
      isDark ? AkadexColors.primaryOnDark : AkadexColors.primary;

  static InputDecoration fieldDecoration({
    required String hint,
    required bool isDark,
    Widget? suffixIcon,
    IconData? prefixIcon,
  }) {
    final border = fieldBorder(isDark);
    final hintColor = muted(isDark);
    final focus = primary(isDark);
    OutlineInputBorder outline([Color? c, double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c ?? border, width: w),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: hintColor, fontSize: 16),
      filled: true,
      fillColor: fieldFill(isDark),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: hintColor, size: 22),
      suffixIcon: suffixIcon,
      border: outline(),
      enabledBorder: outline(),
      disabledBorder: outline(border.withValues(alpha: 0.6)),
      focusedBorder: outline(focus, 1.5),
    );
  }

  static ButtonStyle primaryButton(bool isDark) {
    final p = primary(isDark);
    return FilledButton.styleFrom(
      backgroundColor: p,
      foregroundColor: Colors.white,
      disabledBackgroundColor: p.withValues(alpha: 0.45),
      elevation: 0,
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
  }

  static ButtonStyle outlineButton(bool isDark) {
    final p = primary(isDark);
    return OutlinedButton.styleFrom(
      foregroundColor: p,
      side: BorderSide(color: p, width: 1.4),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    );
  }
}
