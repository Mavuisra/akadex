import 'package:flutter/material.dart';

/// Fonds style Facebook pour publications texte court.
abstract final class StatusBackgrounds {
  /// Au-delà, on affiche le texte normal (sans fond coloré).
  static const int maxChars = 160;

  static const String defaultHex = '#1877F2';

  static const List<String> hexColors = [
    '#1877F2',
    '#F02849',
    '#7B61FF',
    '#31A24C',
    '#FA7E1E',
    '#00A4BD',
    '#E4405F',
    '#0A66C2',
    '#8B5E3C',
    '#1C1E21',
  ];

  static List<Color> get colors =>
      hexColors.map((h) => parse(h)!).toList(growable: false);

  static Color? parse(String? hex) {
    if (hex == null || hex.trim().isEmpty) return null;
    var s = hex.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length != 6) return null;
    final v = int.tryParse(s, radix: 16);
    if (v == null) return null;
    return Color(0xFF000000 | v);
  }

  static bool isShortEnough(String text) {
    final t = text.trim();
    if (t.isEmpty) return false;
    if (t.length > maxChars) return false;
    if (t.split('\n').length > 4) return false;
    return true;
  }

  /// Tag de secours si l’API n’a pas encore `background_color`.
  static String tagFor(String hex) => 'bg:$hex';

  static String? hexFromTags(List<String> tags) {
    for (final t in tags) {
      final s = t.trim();
      if (s.toLowerCase().startsWith('bg:')) {
        final hex = s.substring(3).trim();
        if (parse(hex) != null) {
          return hex.startsWith('#') ? hex.toUpperCase() : '#${hex.toUpperCase()}';
        }
      }
    }
    return null;
  }

  /// Couleur à afficher : champ API, tag `bg:…`, ou bleu par défaut.
  static Color? resolveDisplayColor({
    required String content,
    required bool hasMedia,
    String backgroundColor = '',
    List<String> tags = const [],
  }) {
    if (hasMedia) return null;
    if (!isShortEnough(content)) return null;
    return parse(backgroundColor) ??
        parse(hexFromTags(tags)) ??
        parse(defaultHex);
  }

  static bool canUseStatusStyle({
    required String content,
    required bool hasMedia,
    String backgroundColor = '',
    List<String> tags = const [],
  }) {
    return resolveDisplayColor(
          content: content,
          hasMedia: hasMedia,
          backgroundColor: backgroundColor,
          tags: tags,
        ) !=
        null;
  }
}
