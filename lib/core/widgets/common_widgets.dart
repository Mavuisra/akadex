import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/akadex_theme.dart';

/// Carte pressable avec scale soft (feedback iOS).
class SoftCard extends StatefulWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.delay = Duration.zero,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Duration delay;

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
    _scale = Tween<double>(begin: 1, end: 0.97).animate(
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

  void _up([_]) {
    _press.reverse();
  }

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
            : const Offset(0, 0.06),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
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
    final field = CupertinoSearchTextField(
      controller: controller,
      placeholder: hint,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 15, color: AkadexColors.ink),
      placeholderStyle: GoogleFonts.inter(
        fontSize: 15,
        color: AkadexColors.inkSoft,
      ),
      backgroundColor: const Color(0xFFEEF0F4),
      borderRadius: BorderRadius.circular(12),
      prefixIcon: const Icon(
        CupertinoIcons.search,
        color: AkadexColors.inkSoft,
        size: 18,
      ),
    );

    if (readOnly && onTap != null) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        child: AbsorbPointer(child: field),
      );
    }
    return field;
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
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          final isSelected = item == selected;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelected(item);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? AkadexColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AkadexColors.primary : AkadexColors.border,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AkadexColors.primary.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                item,
                style: TextStyle(
                  color: isSelected ? Colors.white : AkadexColors.ink,
                  fontWeight: FontWeight.w600,
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
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null)
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onAction,
            child: Text(
              action!,
              style: const TextStyle(
                color: AkadexColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AkadexColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AkadexColors.primary,
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
