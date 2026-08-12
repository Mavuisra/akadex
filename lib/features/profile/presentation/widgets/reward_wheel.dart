import 'dart:math' as math;

import 'package:flutter/material.dart';

class RewardWheelSegment {
  const RewardWheelSegment({
    required this.id,
    required this.label,
    required this.color,
  });

  final String id;
  final String label;
  final Color color;
}

class RewardWheel extends StatefulWidget {
  const RewardWheel({
    super.key,
    required this.segments,
    required this.spinning,
    required this.targetSegmentId,
    required this.onSpinComplete,
    this.hubColor = const Color(0xFF1A47B8),
    this.pointerColor = const Color(0xFFE09B2D),
  });

  final List<RewardWheelSegment> segments;
  final bool spinning;
  final String? targetSegmentId;
  final VoidCallback? onSpinComplete;
  final Color hubColor;
  final Color pointerColor;

  @override
  State<RewardWheel> createState() => _RewardWheelState();
}

class _RewardWheelState extends State<RewardWheel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<double>? _spinAnimation;
  double _rotation = 0;
  String? _lastTarget;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onSpinComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(covariant RewardWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetSegmentId != null &&
        widget.targetSegmentId != _lastTarget) {
      _lastTarget = widget.targetSegmentId;
      _animateToSegment(widget.targetSegmentId!);
    }
    if (!widget.spinning) {
      _lastTarget = null;
    }
  }

  void _animateToSegment(String segmentId) {
    final segments = widget.segments;
    if (segments.isEmpty) return;

    final index = segments.indexWhere((s) => s.id == segmentId);
    final targetIndex = index >= 0 ? index : 0;
    final slice = 2 * math.pi / segments.length;
    final targetAngle = (3 * math.pi / 2) - (targetIndex * slice + slice / 2);
    final fullTurns = 5 * 2 * math.pi;
    final endRotation = fullTurns + targetAngle;

    _controller.stop();
    _controller.duration = const Duration(milliseconds: 4200);
    _spinAnimation = Tween<double>(
      begin: _rotation,
      end: endRotation,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final segments = widget.segments;
    if (segments.isEmpty) {
      return const SizedBox(
        width: 260,
        height: 260,
        child: Center(child: Text('Aucun lot disponible')),
      );
    }

    if (_controller.isCompleted && _spinAnimation != null) {
      _rotation = _spinAnimation!.value % (2 * math.pi);
    }

    return SizedBox(
      width: 280,
      height: 310,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 0,
            child: CustomPaint(
              painter: _WheelPointerPainter(color: widget.pointerColor),
              size: const Size(28, 24),
            ),
          ),
          Positioned(
            top: 18,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final angle = _spinAnimation?.value ?? _rotation;
                return Transform.rotate(
                  angle: angle,
                  child: child,
                );
              },
              child: CustomPaint(
                painter: _WheelPainter(segments: segments),
                size: const Size(260, 260),
              ),
            ),
          ),
          Positioned(
            top: 18 + 130 - 28,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.hubColor,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.segments});

  final List<RewardWheelSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final slice = 2 * math.pi / segments.length;

    for (var i = 0; i < segments.length; i++) {
      final start = i * slice;
      final paint = Paint()
        ..color = segments[i].color
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        slice,
        true,
        paint,
      );

      final border = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        slice,
        true,
        border,
      );

      final labelAngle = start + slice / 2;
      final labelRadius = radius * 0.62;
      final labelOffset = Offset(
        center.dx + labelRadius * math.cos(labelAngle),
        center.dy + labelRadius * math.sin(labelAngle),
      );

      canvas.save();
      canvas.translate(labelOffset.dx, labelOffset.dy);
      canvas.rotate(labelAngle + math.pi / 2);

      final text = segments[i].label;
      final display = text.length > 14 ? '${text.substring(0, 12)}…' : text;
      final tp = TextPainter(
        text: TextSpan(
          text: display,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: radius * 0.55);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    final ring = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, ring);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}

class _WheelPointerPainter extends CustomPainter {
  _WheelPointerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = color,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

List<RewardWheelSegment> wheelSegmentsFromPrizes(
  List<Map<String, dynamic>> prizes,
) {
  const palette = [
    Color(0xFF1A47B8),
    Color(0xFFE09B2D),
    Color(0xFF1FA971),
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
    Color(0xFFE5484D),
    Color(0xFF2563EB),
    Color(0xFFDB2777),
  ];

  return [
    for (var i = 0; i < prizes.length; i++)
      RewardWheelSegment(
        id: prizes[i]['id']?.toString() ?? '$i',
        label: prizes[i]['name']?.toString() ?? 'Lot',
        color: palette[i % palette.length],
      ),
  ];
}

IconData prizeCategoryIcon(String? category) {
  switch (category) {
    case 'cash':
      return Icons.payments_rounded;
    case 'ebook':
      return Icons.menu_book_rounded;
    case 'book':
      return Icons.auto_stories_rounded;
    case 'premium':
      return Icons.workspace_premium_rounded;
    case 'teacher':
      return Icons.school_rounded;
    case 'discount':
      return Icons.local_offer_rounded;
    default:
      return Icons.card_giftcard_rounded;
  }
}
