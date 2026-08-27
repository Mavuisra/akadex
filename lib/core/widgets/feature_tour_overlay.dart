import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../onboarding/student_feature_tour.dart';
import '../theme/akadex_theme.dart';

/// Overlay coach-mark : trou sur la cible + bulle d’aide.
class FeatureTourOverlay extends StatefulWidget {
  const FeatureTourOverlay({
    super.key,
    required this.steps,
    required this.targetRectFor,
    required this.onStepChanged,
    required this.onFinished,
  });

  final List<FeatureTourStep> steps;
  final Rect? Function(int tabIndex) targetRectFor;
  final ValueChanged<int> onStepChanged;
  final VoidCallback onFinished;

  @override
  State<FeatureTourOverlay> createState() => _FeatureTourOverlayState();
}

class _FeatureTourOverlayState extends State<FeatureTourOverlay>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _fade;

  FeatureTourStep get _step => widget.steps[_index];

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStepChanged(_step.tabIndex);
    });
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    HapticFeedback.selectionClick();
    if (_index >= widget.steps.length - 1) {
      widget.onFinished();
      return;
    }
    await _fade.reverse();
    if (!mounted) return;
    setState(() => _index++);
    widget.onStepChanged(_step.tabIndex);
    await _fade.forward();
  }

  void _skip() {
    HapticFeedback.lightImpact();
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final hole = widget.targetRectFor(_step.tabIndex);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary =
        isDark ? AkadexColors.primaryOnDark : AkadexColors.primary;

    return Material(
      type: MaterialType.transparency,
      child: FadeTransition(
        opacity: _fade,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _SpotlightPainter(
                  hole: hole,
                  scrim: Colors.black.withValues(alpha: 0.62),
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _goNext,
                ),
              ),
            ),
            if (hole != null)
              Positioned(
                left: hole.left.clamp(12.0, media.size.width - 12),
                width: hole.width.clamp(48.0, media.size.width / 2),
                top: hole.top,
                height: hole.height,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: primary, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.45),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            _TooltipCard(
              step: _step,
              stepIndex: _index,
              stepCount: widget.steps.length,
              hole: hole,
              primary: primary,
              isDark: isDark,
              onNext: _goNext,
              onSkip: _skip,
            ),
          ],
        ),
      ),
    );
  }
}

class _TooltipCard extends StatelessWidget {
  const _TooltipCard({
    required this.step,
    required this.stepIndex,
    required this.stepCount,
    required this.hole,
    required this.primary,
    required this.isDark,
    required this.onNext,
    required this.onSkip,
  });

  final FeatureTourStep step;
  final int stepIndex;
  final int stepCount;
  final Rect? hole;
  final Color primary;
  final bool isDark;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final cardWidth = (media.size.width - 40).clamp(260.0, 340.0);
    final isLast = stepIndex >= stepCount - 1;

    double left = 20;
    double bottom = media.padding.bottom + 88;
    if (hole != null) {
      left = (hole!.center.dx - cardWidth / 2)
          .clamp(16.0, media.size.width - cardWidth - 16);
      bottom = media.size.height - hole!.top + 14;
    }

    return Positioned(
      left: left,
      width: cardWidth,
      bottom: bottom,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? AkadexColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AkadexColors.borderDark : AkadexColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.14),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AkadexColors.inkOnDark : AkadexColors.ink,
                      ),
                    ),
                  ),
                  Text(
                    '${stepIndex + 1}/$stepCount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AkadexColors.metaOnDark
                          : AkadexColors.inkSoft,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                step.body,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: isDark
                      ? AkadexColors.metaOnDark
                      : AkadexColors.inkMuted,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  TextButton(
                    onPressed: onSkip,
                    child: Text(
                      'Passer',
                      style: TextStyle(
                        color: isDark
                            ? AkadexColors.metaOnDark
                            : AkadexColors.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: onNext,
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(isLast ? 'Compris' : 'Suivant'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({required this.hole, required this.scrim});

  final Rect? hole;
  final Color scrim;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()..addRect(Offset.zero & size);
    if (hole != null) {
      overlay.addRRect(
        RRect.fromRectAndRadius(hole!.inflate(6), const Radius.circular(14)),
      );
      overlay.fillType = PathFillType.evenOdd;
    }
    canvas.drawPath(overlay, Paint()..color = scrim);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole || oldDelegate.scrim != scrim;
}
