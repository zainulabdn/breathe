import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../dots/dot_atlas.dart';

/// The living surface of a carousel card: a drifting bloom, breathing gradient
/// stops, and dots orbiting the arcs at the card's base.
///
/// All three run off one controller. A 120-second period is chosen so that 8s,
/// 6s and 5s sub-cycles all divide it evenly — otherwise every sub-animation
/// visibly jumps when the parent controller wraps.
class CardBackgroundPainter extends CustomPainter {
  CardBackgroundPainter({
    required this.animation,
    required this.gradient,
    required this.radius,
    required this.bloomColor,
    this.orbitDotCount = 5,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final LinearGradient gradient;
  final double radius;
  final Color bloomColor;
  final int orbitDotCount;

  static const double periodSeconds = 120;
  // The bloom drift and the orbit both divide the 120s period evenly, so
  // nothing jumps when the parent controller wraps.
  static const double _bloomCycles = periodSeconds / 8;
  static const double _orbitCycles = periodSeconds / 5;

  final DotBatch _dots = DotBatch();

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    canvas.save();
    canvas.clipRRect(rrect);

    _paintGradient(canvas, rect, (t * _bloomCycles) % 1);
    _paintOrbits(canvas, size, (t * _orbitCycles) % 1);
    _paintVignette(canvas, rect);

    canvas.restore();
    _paintRim(canvas, rrect);
  }

  /// Hairline rim light along the top edge, fading out by the card's waist.
  ///
  /// The one detail that most separates a flat gradient rectangle from
  /// something that looks like a physical object: a lit top edge implies a
  /// light source above, which the drop shadow already claims exists.
  void _paintRim(Canvas canvas, RRect rrect) {
    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.34),
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.35, 0.7],
        ).createShader(rrect.outerRect),
    );
  }

  /// The card is a *radial* bloom, not a corner-to-corner ramp.
  ///
  /// A linear gradient puts full saturation in one corner and reads flat and
  /// poster-like. The mock is lit from a point high in the card and falls away
  /// to near-black at every edge, which is what gives it depth. The bloom's
  /// centre drifts, so the whole surface breathes without any colour changing.
  void _paintGradient(Canvas canvas, Rect rect, double phase) {
    final colors = gradient.colors;
    final bloom = colors.first;
    final mid = colors.length > 2 ? colors[1] : colors.last;
    final edge = colors.last;
    final deep = Color.lerp(edge, Colors.black, 0.72)!;

    canvas.drawRect(rect, Paint()..color = deep);

    final angle = phase * 2 * math.pi;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(
            math.cos(angle) * 0.16,
            -0.34 + math.sin(angle) * 0.12,
          ),
          radius: 1.06,
          colors: [bloom, mid, edge, deep],
          stops: const [0.0, 0.32, 0.64, 1.0],
        ).createShader(rect),
    );
  }

  /// Corner vignette. Without it the rounded corners stay noticeably lighter
  /// than the edges between them and the card reads as a flat swatch.
  void _paintVignette(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.92,
          colors: [
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: 0.34),
          ],
          stops: const [0.55, 1.0],
        ).createShader(rect),
    );
  }

  void _paintOrbits(Canvas canvas, Size size, double phase) {
    _dots.reset();

    // Three concentric ellipses centred below the card, so only their upper
    // arcs cross the card's lower third — the faint "orbit" lines in the mock.
    final cx = size.width / 2;
    // Centre sits below the card so only the flat top of each ellipse shows —
    // a horizon, not a ring. The radii must exceed the centre offset, or the
    // whole arc falls past the card's bottom edge and gets clipped away, which
    // is exactly what happened when these were first tuned "subtler".
    final cy = size.height * 1.34;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = Colors.white.withValues(alpha: 0.13);

    const startAngle = math.pi * 1.12;
    const sweep = math.pi * 0.76;

    for (var ring = 0; ring < 3; ring++) {
      final rx = size.width * (0.62 + ring * 0.20);
      // Crowns land at 0.76h / 0.67h / 0.58h — below the readout, where the
      // mock puts them. Must stay above 0.34h (cy - 1.0h) or the arc falls off
      // the bottom of the card entirely.
      final ry = size.height * (0.58 + ring * 0.09);
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: rx * 2,
          height: ry * 2,
        ),
        startAngle,
        sweep,
        false,
        arcPaint,
      );

      // Dots ride the arc, offset per ring so they never line up in a column.
      final perRing = ring == 1 ? orbitDotCount ~/ 2 + 1 : orbitDotCount ~/ 2;
      for (var i = 0; i < perRing; i++) {
        final travel = (phase + i / perRing + ring * 0.17) % 1;
        final angle = startAngle + sweep * travel;
        final x = cx + rx * math.cos(angle);
        final y = cy + ry * math.sin(angle);

        // Fade in and out at the arc's ends so dots do not pop.
        final edge = math.sin(travel * math.pi);
        _dots.add(
          x: x,
          y: y,
          diameter: 3.0,
          color: Colors.white,
          opacity: (edge * 0.95).clamp(0.0, 1.0),
        );
      }
    }

    _dots.paint(canvas);
  }

  @override
  bool shouldRepaint(CardBackgroundPainter old) =>
      old.gradient != gradient ||
      old.radius != radius ||
      old.bloomColor != bloomColor;
}
