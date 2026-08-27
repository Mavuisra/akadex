import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_constants.dart';
import '../theme/akadex_theme.dart';
import '../theme/timeline_tokens.dart';

/// Marge intérieure pour titres / textes quand le feed est plein largeur.
const EdgeInsets kFeedInset = EdgeInsets.symmetric(horizontal: 16);

/// Carte pressable avec scale soft + bordure légère.
class SoftCard extends StatefulWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.delay = Duration.zero,
    this.accentBorder = false,
    /// Style Facebook : bord à bord, coins droits, séparateur bas.
    this.fullBleed = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Duration delay;
  final bool accentBorder;
  final bool fullBleed;

  @override
  State<SoftCard> createState() => _SoftCardState();
}

class _SoftCardState extends State<SoftCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1, end: 0.975).animate(
      CurvedAnimation(parent: _press, curve: Curves.easeOutCubic),
    );
    if (widget.delay == Duration.zero) {
      _visible = true;
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) setState(() => _visible = true);
      });
    }
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _down(TapDownDetails _) {
    if (widget.onTap == null) return;
    _press.forward();
  }

  void _up([_]) => _press.reverse();

  void _tap() {
    if (widget.onTap == null) return;
    HapticFeedback.selectionClick();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible || widget.delay == Duration.zero ? 1 : 0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _visible || widget.delay == Duration.zero
            ? Offset.zero
            : const Offset(0, 0.05),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        child: ScaleTransition(
          scale: _scale,
          child: GestureDetector(
            onTapDown: _down,
            onTapUp: _up,
            onTapCancel: _up,
            onTap: widget.onTap == null ? null : _tap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: widget.fullBleed
                    ? TimelineTokens.of(context).cardBg
                    : TimelineTokens.of(context).commentBubble,
                borderRadius: widget.fullBleed
                    ? BorderRadius.zero
                    : BorderRadius.circular(18),
                border: widget.fullBleed
                    ? Border(
                        bottom: BorderSide(
                          color: widget.accentBorder
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.22)
                              : TimelineTokens.of(context).divider,
                        ),
                      )
                    : Border.all(
                        color: widget.accentBorder
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.22)
                            : TimelineTokens.of(context)
                                .divider
                                .withValues(alpha: 0.85),
                      ),
                boxShadow: widget.fullBleed
                    ? null
                    : [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Padding(padding: widget.padding, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.hint = 'Rechercher…',
    this.onTap,
    this.readOnly = false,
    this.controller,
    this.onChanged,
  });

  final String hint;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? Colors.white : AkadexColors.ink;
    final soft = isDark ? const Color(0xFF8A8A8A) : AkadexColors.inkSoft;
    final bg = isDark ? const Color(0xFF242424) : Colors.white;

    final field = CupertinoSearchTextField(
      controller: controller,
      placeholder: hint,
      onChanged: onChanged,
      style: TextStyle(fontSize: 15, color: ink),
      placeholderStyle: TextStyle(
        fontSize: 15,
        color: soft,
      ),
      backgroundColor: bg,
      borderRadius: BorderRadius.circular(14),
      prefixIcon: Icon(
        CupertinoIcons.search,
        color: primary,
        size: 18,
      ),
    );

    final wrapped = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: field,
    );

    if (readOnly && onTap != null) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        child: AbsorbPointer(child: wrapped),
      );
    }
    return wrapped;
  }
}

class FilterChipBar extends StatelessWidget {
  const FilterChipBar({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  final List<String> items;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          final isSelected = item == selected;
          final feed = TimelineTokens.of(context);
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelected(item);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? AkadexColors.brandGradient : null,
                color: isSelected ? null : feed.feedBg,
                borderRadius: BorderRadius.circular(22),
                border: TimelineTokens.tabBorder,
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AkadexColors.primary.withValues(alpha: 0.28)
                        : Colors.black.withValues(alpha: 0.03),
                    blurRadius: isSelected ? 12 : 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                item,
                style: TextStyle(
                  color: isSelected ? Colors.white : feed.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);

    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: feed.linkBlue,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: feed.ink,
            ),
          ),
        ),
        if (action != null)
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onAction,
            child: Text(
              action!,
              style: TextStyle(
                color: feed.linkBlue,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }
}

class DocTypeTag extends StatelessWidget {
  const DocTypeTag(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: feed.feedBg,
        borderRadius: BorderRadius.circular(TimelineTokens.chipRadius),
        border: TimelineTokens.tabBorder,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: feed.linkBlue,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class BottomSafePadding extends StatelessWidget {
  const BottomSafePadding({super.key, this.height = 100});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(height: height);
}

class AkadexLogo extends StatelessWidget {
  const AkadexLogo({
    super.key,
    this.size = 72,
    this.borderRadius,
  });

  final double size;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? size * 0.22;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AkadexColors.primary.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          AppConstants.logoAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class AkadexPresentation extends StatelessWidget {
  const AkadexPresentation({
    super.key,
    this.height,
  });

  final double? height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppConstants.presentationAsset,
      height: height,
      width: double.infinity,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class AkadexBrandHeader extends StatelessWidget {
  const AkadexBrandHeader({
    super.key,
    this.logoSize = 36,
    this.fontSize = 28,
    this.color = AkadexColors.ink,
    this.centered = false,
  });

  final double logoSize;
  final double fontSize;
  final Color color;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AkadexLogo(size: logoSize),
        SizedBox(width: logoSize * 0.28),
        Flexible(
          child: Text(
            AppConstants.appName,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
    return centered ? Center(child: row) : row;
  }
}

/// Tuile d’accès rapide animée.
class QuickAccessTile extends StatelessWidget {
  const QuickAccessTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AkadexColors.primarySoft,
                  AkadexColors.accentSoft.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AkadexColors.primary, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AkadexColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
