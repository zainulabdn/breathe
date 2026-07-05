import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The dotted scale along the bottom of the "Daily Smoke" tile, with one
/// highlighted tick marking the current value.
///
/// The highlight slides in on `easeOutExpo` and pushes a short ripple through
/// its neighbours, so the tile has a beat of motion on entrance rather than
/// appearing fully formed.
class TickStripPainter extends CustomPainter {
  TickStripPainter({
    required this.animation,
    required this.value,
    this.tickCount = 34,
  }) : super(repaint: animation);

  /// 0–1 entrance progress.
  final Animation<double> animation;

  /// 0–1 position of the highlighted tick.
  final double value;

  final int tickCount;

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOutExpo.transform(animation.value.clamp(0.0, 1.0));
    final activeIndex = (value * (tickCount - 1)).round();
    // The highlight travels from the left edge to its resting index.
    final travelled = activeIndex * t;

    final spacing = tickCount > 1 ? size.width / (tickCount - 1) : 0.0;
    final paint = Paint()..strokeCap = StrokeCap.round;

    for (var i = 0; i < tickCount; i++) {
      final x = i * spacing;
      final distance = (i - travelled).abs();
      final isActive = distance < 0.5;

      // Ripple: neighbours lift briefly as the highlight passes.
      final ripple = math.max(0.0, 1.0 - distance / 3.5) * (1 - t);

      final height = isActive
          ? size.height
          : (size.height * 0.34) + size.height * 0.35 * ripple;

      paint
        ..color = isActive
            ? AppColors.acidYellow
            : AppColors.textPrimary.withValues(alpha: 0.28 + 0.4 * ripple)
        ..strokeWidth = isActive ? 2.4 : 1.6;

      canvas.drawLine(
        Offset(x, size.height / 2 - height / 2),
        Offset(x, size.height / 2 + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(TickStripPainter old) =>
      old.value != value || old.tickCount != tickCount;
}
