import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/motion/motion.dart';
import '../core/theme/app_colors.dart';
import 'breath_shapes.dart';
import 'dot_atlas.dart';

/// A grid of dots clipped to an arbitrary silhouette, filled from the bottom
/// like a liquid. Drives the lung cloud on the Expiratory Volume screen.
///
/// Deliberately dumb: it renders exactly the [fillLevel] it is handed and does
/// no smoothing of its own. Smoothing belongs in the breath analyzer
/// (docs/BREATH_ENGINE.md §4) — doing it in both places stacks two lags and
/// makes the cloud feel like it is trailing the user's breath.
class DotField extends StatefulWidget {
  const DotField({
    required this.fillLevel,
    this.pathBuilder,
    this.spacing = 11,
    this.dotSize = 3.2,
    this.litColor = AppColors.textPrimary,
    this.unlitColor = AppColors.dotOff,
    this.glow = 0.5,
    this.shimmer = 0.12,
    this.waveAmplitude = 6,
    this.waveLength = 0.55,
    this.wobble = 7,
    this.bubbles = 14,
    this.semanticsLabel,
    super.key,
  });

  /// 0 = empty, 1 = full.
  final double fillLevel;

  /// Silhouette to mask the grid to; defaults to [BreathShapes.lungDome].
  final Path Function(Size)? pathBuilder;

  final double spacing;
  final double dotSize;
  final Color litColor;
  final Color unlitColor;
  final double glow;

  /// Per-dot opacity oscillation, 0–1. Keeps the field alive when idle.
  final double shimmer;

  /// Vertical travel of the fill boundary, in logical pixels.
  final double waveAmplitude;

  /// Wavelength of the fill boundary as a fraction of field width.
  final double waveLength;

  /// Peak radial displacement, in logical pixels, of the organic wobble that
  /// keeps the silhouette from looking like a stencil. Set 0 for a rigid shape.
  final double wobble;

  /// Bubbles rising through the filled region. Purely decorative, and the main
  /// reason the field reads as something living rather than a gauge.
  final int bubbles;

  final String? semanticsLabel;

  @override
  State<DotField> createState() => _DotFieldState();
}

class _DotFieldState extends State<DotField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  List<Offset> _dots = const [];
  Size _lastSize = Size.zero;
  double _lastSpacing = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion stops the shimmer and the travelling wave; the fill level
    // itself still tracks the breath.
    if (MotionScale.ambientAllowed(context)) {
      if (!_ambient.isAnimating) _ambient.repeat();
    } else {
      _ambient.stop();
      _ambient.value = 0;
    }
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  /// Samples the silhouette into a dot grid. `Path.contains` is too slow to run
  /// per frame, so this runs only when the size or spacing changes.
  void _resample(Size size) {
    if (size == _lastSize && widget.spacing == _lastSpacing) return;
    _lastSize = size;
    _lastSpacing = widget.spacing;

    final path = (widget.pathBuilder ?? BreathShapes.lungDome)(size);
    final dots = <Offset>[];
    final inset = widget.spacing / 2;
    for (var y = inset; y < size.height; y += widget.spacing) {
      for (var x = inset; x < size.width; x += widget.spacing) {
        final point = Offset(x, y);
        if (path.contains(point)) dots.add(point);
      }
    }
    _dots = dots;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel,
      excludeSemantics: widget.semanticsLabel != null,
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            _resample(size);
            return CustomPaint(
              size: size,
              isComplex: true,
              painter: _FieldPainter(
                ambient: _ambient,
                dots: _dots,
                fieldSize: size,
                fillLevel: widget.fillLevel,
                dotSize: widget.dotSize,
                litColor: widget.litColor,
                unlitColor: widget.unlitColor,
                glow: widget.glow,
                shimmer: widget.shimmer,
                waveAmplitude: widget.waveAmplitude,
                waveLength: widget.waveLength,
                wobble: widget.wobble,
                bubbles: widget.bubbles,
                band: widget.spacing * 1.6,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FieldPainter extends CustomPainter {
  _FieldPainter({
    required this.ambient,
    required this.dots,
    required this.fieldSize,
    required this.fillLevel,
    required this.dotSize,
    required this.litColor,
    required this.unlitColor,
    required this.glow,
    required this.shimmer,
    required this.waveAmplitude,
    required this.waveLength,
    required this.wobble,
    required this.bubbles,
    required this.band,
  }) : super(repaint: ambient);

  final Animation<double> ambient;
  final List<Offset> dots;
  final Size fieldSize;
  final double fillLevel;
  final double dotSize;
  final Color litColor;
  final Color unlitColor;
  final double glow;
  final double shimmer;
  final double waveAmplitude;
  final double waveLength;
  final double wobble;
  final int bubbles;
  final double band;

  final DotBatch _bloom = DotBatch(soft: true);
  final DotBatch _core = DotBatch();

  /// Deterministic per-dot phase so the shimmer looks random but never
  /// re-rolls between frames.
  static double _phase(int i) => ((i * 2654435761) % 1000) / 1000.0;

  @override
  void paint(Canvas canvas, Size size) {
    _bloom.reset();
    _core.reset();

    final t = ambient.value;
    final fill = fillLevel.clamp(0.0, 1.0);
    final restY = size.height - fill * size.height;
    final k = waveLength <= 0 ? 0.0 : 2 * math.pi / (size.width * waveLength);

    final centre = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;

    for (var i = 0; i < dots.length; i++) {
      final dot = dots[i];

      // Organic wobble: each dot is pushed along its own radius by a sum of
      // sines in angle and time. Displacing the dots rather than re-cutting the
      // silhouette keeps `Path.contains` out of the per-frame path — the grid
      // membership is fixed, only where each dot draws moves.
      var x = dot.dx;
      var y = dot.dy;
      if (wobble > 0) {
        final dx = dot.dx - centre.dx;
        final dy = dot.dy - centre.dy;
        final radius = math.sqrt(dx * dx + dy * dy);
        if (radius > 0.001) {
          final angle = math.atan2(dy, dx);
          final push = math.sin(angle * 3 + t * 2 * math.pi * 0.7) * 0.55 +
              math.sin(angle * 5 - t * 2 * math.pi * 0.5) * 0.30 +
              math.sin(angle * 7 + t * 2 * math.pi * 0.9) * 0.15;
          // Scales with distance from centre so the rim breathes and the
          // middle stays put — a uniform push would just translate the shape.
          final amount = wobble * push * (radius / maxRadius).clamp(0.0, 1.4);
          x += dx / radius * amount;
          y += dy / radius * amount;
        }
      }

      final boundaryY = restY +
          math.sin(x * k + t * 2 * math.pi) * waveAmplitude * _edgeFade(fill);

      // Soft band across the surface instead of a hard on/off row.
      final v = ((y - boundaryY) / band).clamp(0.0, 1.0);

      var opacity = v;
      if (shimmer > 0) {
        opacity *= 1 + shimmer * math.sin((t + _phase(i)) * 2 * math.pi);
      }
      opacity = opacity.clamp(0.0, 1.0);

      // Unlit cells stay faintly visible so the silhouette is always readable.
      _core.add(x: x, y: y, diameter: dotSize, color: unlitColor);

      if (opacity > 0.01) {
        if (glow > 0) {
          _bloom.add(
            x: x,
            y: y,
            diameter: dotSize * 4.0,
            color: litColor,
            opacity: opacity * glow * 0.34,
          );
        }
        _core.add(
          x: x,
          y: y,
          diameter: dotSize,
          color: litColor,
          opacity: opacity,
        );
      }
    }

    if (bubbles > 0 && fill > 0.05) {
      _paintBubbles(size, t, fill, restY);
    }

    _bloom.paint(canvas);
    _core.paint(canvas);
  }

  /// Bubbles rising through the filled region, popping at the surface.
  ///
  /// Fully procedural — position is a function of time and index, so there is
  /// no particle list to allocate, update or cap.
  void _paintBubbles(Size size, double t, double fill, double restY) {
    final floor = size.height;
    for (var i = 0; i < bubbles; i++) {
      final seed = _phase(i * 7 + 3);
      final speed = 0.35 + seed * 0.5;
      // Each bubble runs its own loop, offset so they never rise in step.
      final progress = ((t * speed + seed) % 1.0);

      final y = floor - (floor - restY) * progress;
      if (y < restY) continue;

      final x = size.width * (0.16 + seed * 0.68) +
          math.sin(progress * math.pi * 4 + seed * 6) * 7;

      // Fades out as it nears the surface, so bubbles pop rather than clip.
      final nearSurface = ((y - restY) / 26).clamp(0.0, 1.0);
      final opacity = nearSurface * (0.25 + seed * 0.35);
      final diameter = 2.0 + seed * 3.4;

      _bloom.add(
        x: x,
        y: y,
        diameter: diameter * 3.2,
        color: litColor,
        opacity: opacity * 0.4,
      );
      _core.add(
        x: x,
        y: y,
        diameter: diameter,
        color: litColor,
        opacity: opacity,
      );
    }
  }

  /// Flattens the wave as the field approaches empty or full, so the surface
  /// does not visibly slosh outside the silhouette.
  double _edgeFade(double fill) {
    const edge = 0.08;
    if (fill < edge) return fill / edge;
    if (fill > 1 - edge) return (1 - fill) / edge;
    return 1;
  }

  @override
  bool shouldRepaint(_FieldPainter old) =>
      old.fillLevel != fillLevel ||
      old.dots != dots ||
      old.dotSize != dotSize ||
      old.litColor != litColor ||
      old.unlitColor != unlitColor ||
      old.glow != glow ||
      old.shimmer != shimmer;
}
