import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../dots/dot_atlas.dart';

/// Dotted ring that fills over the current phase, then resets for the next.
///
/// Gives the phase a visible end-point, which matters most during holds — the
/// orb is motionless then, and without the ring the user has no idea how much
/// longer to wait.
class PhaseRing extends StatelessWidget {
  const PhaseRing({
    required this.progress,
    required this.color,
    this.dotCount = 60,
    super.key,
  });

  final double progress;
  final Color color;
  final int dotCount;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
          color: color,
          dotCount: dotCount,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.dotCount,
  });

  final double progress;
  final Color color;
  final int dotCount;

  final DotBatch _bloom = DotBatch(soft: true);
  final DotBatch _core = DotBatch();

  @override
  void paint(Canvas canvas, Size size) {
    _bloom.reset();
    _core.reset();

    final centre = size.center(Offset.zero);
    final radius = size.shortestSide / 2 * 0.94;
    final filled = progress.clamp(0.0, 1.0) * dotCount;

    for (var i = 0; i < dotCount; i++) {
      // Starts at 12 o'clock and runs clockwise.
      final angle = -math.pi / 2 + (i / dotCount) * 2 * math.pi;
      final x = centre.dx + radius * math.cos(angle);
      final y = centre.dy + radius * math.sin(angle);

      final lit = i < filled;
      // The dot straddling the boundary fades in, so the ring advances
      // smoothly instead of stepping.
      final edge = (filled - i).clamp(0.0, 1.0);

      if (lit) {
        _bloom.add(
          x: x,
          y: y,
          diameter: 12,
          color: color,
          opacity: 0.30 * edge,
        );
      }
      _core.add(
        x: x,
        y: y,
        diameter: lit ? 3.4 : 2.4,
        color: lit ? color : Colors.white,
        opacity: lit ? (0.4 + 0.6 * edge) : 0.16,
      );
    }

    _bloom.paint(canvas);
    _core.paint(canvas);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
