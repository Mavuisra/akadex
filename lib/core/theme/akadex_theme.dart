import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

export 'akadex_scroll.dart';

/// Design system Akadex — rendu proche d’iOS (HIG).
abstract final class AkadexColors {
  static const Color primary = Color(0xFF1A47B8);
  static const Color primaryDark = Color(0xFF143A96);
  static const Color primaryLight = Color(0xFF3B6BE0);
  static const Color primarySoft = Color(0xFFE8EEFB);

  static const Color background = Color(0xFFF2F2F7); // iOS systemGroupedBackground
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E5EA);

  static const Color ink = Color(0xFF1C1C1E);
  static const Color inkMuted = Color(0xFF8E8E93);
  static const Color inkSoft = Color(0xFFAEAEB2);

  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color danger = Color(0xFFFF3B30);
}

abstract final class AkadexTheme {
  /// Police Roboto embarquée (offline — pas de fonts.gstatic.com).
  static const String _fontFamily = 'Roboto';

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: _fontFamily,
    );
    final text = base.textTheme.apply(
      bodyColor: AkadexColors.ink,
      displayColor: AkadexColors.ink,
      fontFamily: _fontFamily,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AkadexColors.background,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AkadexColors.primary,
        primary: AkadexColors.primary,
        surface: AkadexColors.surface,
        brightness: Brightness.light,
      ),
      textTheme: text.copyWith(
        headlineLarge: text.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        bodyMedium: text.bodyMedium?.copyWith(
          color: AkadexColors.inkMuted,
          height: 1.35,
        ),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AkadexColors.background.withValues(alpha: 0.92),
        foregroundColor: AkadexColors.ink,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: text.titleLarge?.copyWith(
          color: AkadexColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AkadexColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AkadexColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: Colors.white, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: AkadexColors.primary,
        barBackgroundColor: Color(0xF0F9F9F9),
        scaffoldBackgroundColor: AkadexColors.background,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AkadexColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      dividerTheme: const DividerThemeData(
        color: AkadexColors.border,
        thickness: 0.5,
      ),
    );
  }
}
