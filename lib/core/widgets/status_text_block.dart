import 'package:flutter/material.dart';

import '../theme/status_backgrounds.dart';
import '../theme/timeline_tokens.dart';

/// Bloc texte style Facebook (fond coloré + texte blanc centré).
class StatusTextBlock extends StatelessWidget {
  const StatusTextBlock({
    super.key,
    required this.text,
    required this.backgroundColor,
    this.minHeight = 280,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
  });

  final String text;
  final Color backgroundColor;
  final double minHeight;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final len = text.trim().length;
    final fontSize = len <= 40
        ? 36.0
        : len <= 80
            ? 30.0
            : 24.0;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      color: backgroundColor,
      padding: padding,
      alignment: Alignment.center,
      child: Text(
        text.trim(),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
    );
  }
}

/// Affiche un post texte : fond coloré si éligible, sinon description seule.
class PostBodyText extends StatelessWidget {
  const PostBodyText({
    super.key,
    required this.content,
    this.backgroundColor = '',
    this.tags = const [],
    this.hasMedia = false,
    this.padded = true,
  });

  final String content;
  final String backgroundColor;
  final List<String> tags;
  final bool hasMedia;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final text = content.trim();
    if (text.isEmpty) return const SizedBox.shrink();

    final bg = StatusBackgrounds.resolveDisplayColor(
      content: text,
      hasMedia: hasMedia,
      backgroundColor: backgroundColor,
      tags: tags,
    );

    if (bg != null) {
      return StatusTextBlock(text: text, backgroundColor: bg);
    }

    final child = Text(
      text,
      style: TextStyle(
        fontSize: 15,
        height: 1.4,
        color: TimelineTokens.of(context).ink,
      ),
    );

    if (!padded) return child;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: child,
    );
  }
}
