import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../dots/dot_atlas.dart';

/// The dotted arc gauge on the "Breath Volume" tile.
///
/// Dots reveal one at a time along the arc rather than the arc sweeping as a
/// stroke — same primitive as every other dot surface, so the tile reads as
/// part of the system instead of as a chart dropped in.
class DottedArcPainter extends CustomPainter {
  DottedArcPainter({
    required this.animation,
    required this.value,
    required this.litColor,
    this.dotCount = 30,
    this.startAngle = math.pi * 0.92,
    this.sweepAngle = math.pi * 1.16,
  }) : super(repaint: animation);

  /// 0–1 reveal progress.
  final Animation<double> animation;

  /// 0–1 gauge value.
  final double value;

  final Color litColor;
  final int dotCount;
  final double startAngle;
  final double sweepAngle;

  final DotBatch _bloom = DotBatch(soft: true);
  final DotBatch _core = DotBatch();

  @override
  void paint(Canvas canvas, Size size) {
    _bloom.reset();
    _core.reset();

    final t = animation.value.clamp(0.0, 1.0);
    final center = Offset(size.width / 2, size.height * 0.94);
    final rx = size.width * 0.46;
    final ry = size.height * 0.72;
    final filled = value.clamp(0.0, 1.0) * dotCount;

    for (var i = 0; i < dotCount; i++) {
      // Staggered reveal: each dot has its own slice of the timeline.
      final reveal = ((t * dotCount) - i).clamp(0.0, 1.0);
      if (reveal <= 0) continue;

      final f = dotCount > 1 ? i / (dotCount - 1) : 0.0;
      final angle = startAngle + sweepAngle * f;
      final x = center.dx + rx * math.cos(angle);
      final y = center.dy + ry * math.sin(angle);

      final isLit = i < filled;
      final diameter = (isLit ? 2.4 : 1.9) * reveal;
      final opacity = (isLit ? 0.85 : 0.26) * reveal;

      if (isLit) {
        _bloom.add(
          x: x,
          y: y,
          diameter: diameter * 3,
          color: litColor,
          opacity: opacity * 0.18,
        );
      }
      _core.add(
        x: x,
        y: y,
        diameter: diameter,
        color: isLit ? litColor : Colors.white,
        opacity: opacity,
      );
    }

    _bloom.paint(canvas);
    _core.paint(canvas);
  }

  @override
  bool shouldRepaint(DottedArcPainter old) =>
      old.value != value || old.litColor != litColor;
}
