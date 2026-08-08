import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/akadex_theme.dart';

/// Fond vivant partagé : wash doux + orbes animés (bleu marque).
class PageAtmosphere extends StatefulWidget {
  const PageAtmosphere({
    super.key,
    required this.child,
    this.intensity = 1,
  });

  final Widget child;
  final double intensity;

  @override
  State<PageAtmosphere> createState() => _PageAtmosphereState();
}

class _PageAtmosphereState extends State<PageAtmosphere>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = _pulse.value;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final orbPrimary = isDark
            ? AkadexColors.primaryOnDark
            : AkadexColors.primary;
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: isDark
                    ? AkadexColors.softWashDark
                    : AkadexColors.softWash,
              ),
            ),
            Positioned(
              top: -80 + 20 * math.sin(t * math.pi),
              right: -60,
              child: _Orb(
                size: 220 * widget.intensity,
                color: (isDark
                        ? AkadexColors.primaryOnDark
                        : AkadexColors.primaryLight)
                    .withValues(alpha: isDark ? 0.08 : 0.14),
              ),
            ),
            Positioned(
              top: 180,
              left: -90,
              child: _Orb(
                size: 180 * widget.intensity,
                color: AkadexColors.accent
                    .withValues(alpha: (isDark ? 0.04 : 0.08) + 0.04 * t),
              ),
            ),
            Positioned(
              bottom: 40,
              right: -40,
              child: _Orb(
                size: 160 * widget.intensity,
                color: orbPrimary.withValues(alpha: isDark ? 0.05 : 0.07),
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// Entrée en fondu + léger slide pour les blocs de page.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 0.04,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _opacity = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offset),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Bannière héros animée (accueil / hubs).
class LivingHeroBanner extends StatefulWidget {
  const LivingHeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.onCta,
    this.trailing,
    this.fullBleed = false,
  });

  final String title;
  final String subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final Widget? trailing;
  final bool fullBleed;

  @override
  State<LivingHeroBanner> createState() => _LivingHeroBannerState();
}

class _LivingHeroBannerState extends State<LivingHeroBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine;

  @override
  void initState() {
    super.initState();
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shine,
      builder: (context, child) {
        final shift = _shine.value;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.2 + shift * 2.4, -1),
              end: Alignment(1.2 - shift * 2.4, 1),
              colors: const [
                Color(0xFF0F2F7A),
                Color(0xFF1A47B8),
                Color(0xFF3B6BE0),
                Color(0xFF1A47B8),
              ],
            ),
            borderRadius: widget.fullBleed
                ? BorderRadius.zero
                : BorderRadius.circular(22),
            boxShadow: widget.fullBleed
                ? null
                : [
                    BoxShadow(
                      color: AkadexColors.primary.withValues(alpha: 0.28),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
          ),
          child: child,
        );
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.ctaLabel != null && widget.onCta != null) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).brightness ==
                              Brightness.dark
                          ? Colors.white.withValues(alpha: 0.16)
                          : Colors.white,
                      foregroundColor: Theme.of(context).brightness ==
                              Brightness.dark
                          ? Colors.white
                          : AkadexColors.primary,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: Theme.of(context).brightness == Brightness.dark
                            ? BorderSide(
                                color: Colors.white.withValues(alpha: 0.45),
                              )
                            : BorderSide.none,
                      ),
                    ),
                    onPressed: widget.onCta,
                    child: Text(
                      widget.ctaLabel!,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: 10),
            widget.trailing!,
          ],
        ],
      ),
    );
  }
}
