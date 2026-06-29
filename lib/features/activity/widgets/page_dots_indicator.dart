import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Page dots where the active dot stretches into a pill.
///
/// Painted from the carousel's fractional page so the stretch happens *during*
/// the swipe, not after it commits.
class PageDotsIndicator extends StatelessWidget {
  const PageDotsIndicator({
    required this.page,
    required this.count,
    this.dotSize = 4,
    this.activeWidth = 12,
    this.gap = 6,
    super.key,
  });

  final double page;
  final int count;
  final double dotSize;
  final double activeWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Metric ${page.round() + 1} of $count',
      child: SizedBox(
        height: dotSize,
        width: count * dotSize + (count - 1) * gap + (activeWidth - dotSize),
        child: CustomPaint(
          painter: _DotsPainter(
            page: page,
            count: count,
            dotSize: dotSize,
            activeWidth: activeWidth,
            gap: gap,
          ),
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter({
    required this.page,
    required this.count,
    required this.dotSize,
    required this.activeWidth,
    required this.gap,
  });

  final double page;
  final int count;
  final double dotSize;
  final double activeWidth;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    var x = 0.0;

    for (var i = 0; i < count; i++) {
      // 1 when this dot is active, falling to 0 as the page moves away.
      final t = math.max(0.0, 1.0 - (page - i).abs()).clamp(0.0, 1.0);
      final width = dotSize + (activeWidth - dotSize) * t;

      paint.color = Color.lerp(
        AppColors.textTertiary,
        AppColors.textPrimary,
        t,
      )!;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, (size.height - dotSize) / 2, width, dotSize),
          Radius.circular(dotSize / 2),
        ),
        paint,
      );
      x += width + gap;
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) =>
      old.page != page || old.count != count;
}
