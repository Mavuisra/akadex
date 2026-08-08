import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'timeline_tokens.dart';

export 'akadex_scroll.dart';

/// Design system Akadex — campus numérique, bleu marque + or vif.
abstract final class AkadexColors {
  static const Color primary = Color(0xFF1A47B8);
  static const Color primaryDark = Color(0xFF0F2F7A);
  static const Color primaryLight = Color(0xFF4A7CF0);
  static const Color primarySoft = Color(0xFFE8EEFB);
  static const Color primaryMist = Color(0xFFF3F6FF);

  /// Accent lisible sur fond sombre (liens, chips, tab active).
  static const Color primaryOnDark = Color(0xFF4A83D4);

  /// Accent or (énergie / campus)
  static const Color accent = Color(0xFFE09B2D);
  static const Color accentSoft = Color(0xFFFFF4E0);

  static const Color background = Color(0xFFF0F3FA);
  static const Color backgroundDeep = Color(0xFFE4EAF6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFDCE3F0);

  static const Color backgroundDark = Color(0xFF0E0E0E);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color borderDark = Color(0xFF2C2C2C);
  static const Color inkOnDark = Color(0xFFFFFFFF);
  static const Color metaOnDark = Color(0xFF8A8A8A);

  static const Color ink = Color(0xFF121826);
  static const Color inkMuted = Color(0xFF5B6478);
  static const Color inkSoft = Color(0xFF8B93A7);

  static const Color success = Color(0xFF1FA971);
  static const Color warning = Color(0xFFE09B2D);
  static const Color danger = Color(0xFFE5484D);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF143A96), Color(0xFF1A47B8), Color(0xFF3B6BE0)],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient heroGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A47B8), Color(0xFF2563C7), Color(0xFF4A7CF0)],
  );

  static const LinearGradient softWash = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7F9FF), Color(0xFFEEF2FB), Color(0xFFE8EDF8)],
  );

  static const LinearGradient softWashDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF121212), Color(0xFF0E0E0E), Color(0xFF0A0A0A)],
  );
}

abstract final class AkadexTheme {
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
      splashFactory: InkRipple.splashFactory,
      extensions: const <ThemeExtension<dynamic>>[AkadexFeedColors.light],
      colorScheme: ColorScheme.fromSeed(
        seedColor: AkadexColors.primary,
        primary: AkadexColors.primary,
        secondary: AkadexColors.accent,
        surface: AkadexColors.surface,
        brightness: Brightness.light,
      ),
      textTheme: text.copyWith(
        headlineLarge: text.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: AkadexColors.ink,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          fontSize: 20,
        ),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        bodyMedium: text.bodyMedium?.copyWith(
          color: AkadexColors.inkMuted,
          height: 1.4,
        ),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AkadexColors.background.withValues(alpha: 0.86),
        foregroundColor: AkadexColors.ink,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: text.titleLarge?.copyWith(
          color: AkadexColors.ink,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AkadexColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AkadexColors.primary,
          foregroundColor: Colors.white,
          // Ne pas utiliser Size.fromHeight (largeur infinie) :
          // ça casse les FilledButton dans un Row → écran blanc.
          minimumSize: const Size(64, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 52),
          side: const BorderSide(color: Colors.white, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AkadexColors.surface,
        selectedColor: AkadexColors.primary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        side: const BorderSide(color: AkadexColors.border),
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: AkadexColors.primary,
        barBackgroundColor: Color(0xF0F7F9FF),
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
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AkadexColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: const DividerThemeData(
        color: AkadexColors.border,
        thickness: 0.5,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AkadexColors.surface,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: _fontFamily,
    );
    final text = base.textTheme.apply(
      bodyColor: AkadexColors.inkOnDark,
      displayColor: AkadexColors.inkOnDark,
      fontFamily: _fontFamily,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AkadexColors.backgroundDark,
      splashFactory: InkRipple.splashFactory,
      extensions: const <ThemeExtension<dynamic>>[AkadexFeedColors.dark],
      colorScheme: ColorScheme.fromSeed(
        seedColor: AkadexColors.primaryOnDark,
        primary: AkadexColors.primaryOnDark,
        secondary: AkadexColors.accent,
        surface: AkadexColors.surfaceDark,
        brightness: Brightness.dark,
      ),
      textTheme: text.copyWith(
        headlineLarge: text.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: AkadexColors.inkOnDark,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          fontSize: 20,
        ),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        bodyMedium: text.bodyMedium?.copyWith(
          color: AkadexColors.metaOnDark,
          height: 1.4,
        ),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AkadexColors.backgroundDark.withValues(alpha: 0.92),
        foregroundColor: AkadexColors.inkOnDark,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: text.titleLarge?.copyWith(
          color: AkadexColors.inkOnDark,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AkadexColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AkadexColors.primaryOnDark,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AkadexColors.inkOnDark,
          minimumSize: const Size(64, 52),
          side: const BorderSide(color: AkadexColors.borderDark, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AkadexColors.surfaceDark,
        selectedColor: AkadexColors.primaryOnDark,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AkadexColors.inkOnDark,
        ),
        secondaryLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        side: const BorderSide(color: AkadexColors.borderDark),
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: AkadexColors.primaryOnDark,
        barBackgroundColor: Color(0xF01A1A1A),
        scaffoldBackgroundColor: AkadexColors.backgroundDark,
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
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AkadexColors.primaryOnDark,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: const DividerThemeData(
        color: AkadexColors.borderDark,
        thickness: 0.5,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AkadexColors.surfaceDark,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AkadexColors.surfaceDark,
      ),
    );
  }
}
