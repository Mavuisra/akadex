import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/timeline_tokens.dart';

/// En-tête + fond identiques au fil Accueil pour les sous-pages.
class FeedSubpageScaffold extends StatelessWidget {
  const FeedSubpageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
  });

  final String title;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);

    return Scaffold(
      backgroundColor: feed.feedBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: TimelineTokens.headerHeight,
              decoration: BoxDecoration(
                color: feed.cardBg,
                border: Border(
                  bottom: BorderSide(color: feed.divider, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Retour',
                    onPressed: () => context.pop(),
                    icon: Icon(Icons.arrow_back_rounded, color: feed.ink),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: feed.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  ...actions,
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// Titre de section (style fil Accueil).
class FeedSectionLabel extends StatelessWidget {
  const FeedSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    final pad = TimelineTokens.feedHorizontal(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(pad.left + 4, 16, pad.right, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: feed.ink,
        ),
      ),
    );
  }
}

/// Carte plein largeur sans ombre — comme une publication du fil.
class FeedPanel extends StatelessWidget {
  const FeedPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.marginBottom = 8,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final double marginBottom;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    final pad = TimelineTokens.feedHorizontal(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(pad.left, 0, pad.right, marginBottom),
      child: Material(
        color: feed.cardBg,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: feed.divider, width: 0.5),
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Bouton principal plat (bleu fil).
class FeedPrimaryButton extends StatelessWidget {
  const FeedPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    final active = enabled && !loading && onPressed != null;

    return Material(
      color: active ? feed.linkBlue : feed.commentBubble,
      borderRadius: BorderRadius.circular(TimelineTokens.searchRadius),
      child: InkWell(
        onTap: active ? onPressed : null,
        borderRadius: BorderRadius.circular(TimelineTokens.searchRadius),
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: active ? Colors.white : feed.meta,
                  ),
                )
              else if (icon != null) ...[
                Icon(icon, size: 20, color: active ? Colors.white : feed.meta),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : feed.meta,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip plat (badges, catégories).
class FeedTagChip extends StatelessWidget {
  const FeedTagChip({
    super.key,
    required this.label,
    this.icon,
  });

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: feed.feedBg,
        borderRadius: BorderRadius.circular(TimelineTokens.chipRadius),
        border: TimelineTokens.tabBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: feed.linkBlue),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: feed.linkBlue,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne vide (état sans contenu).
class FeedEmptyState extends StatelessWidget {
  const FeedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: feed.meta),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: feed.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: feed.meta, height: 1.4, fontSize: 14),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FeedPrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
