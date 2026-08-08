import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/api/api_client.dart';

const _kThemeModeKey = 'akadex_theme_mode';

/// Préférence de thème persistée (clair / sombre).
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static ThemeMode _read(SharedPreferences prefs) {
    switch (prefs.getString(_kThemeModeKey)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        // Après introduction du dark : défaut sombre ; le clair reste l’ancien look.
        return ThemeMode.dark;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == ThemeMode.system) {
      mode = ThemeMode.dark;
    }
    state = mode;
    await _prefs.setString(
      _kThemeModeKey,
      mode == ThemeMode.light ? 'light' : 'dark',
    );
  }

  Future<void> toggle() => setMode(
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      );
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(sharedPreferencesProvider));
});
