import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'breath_shapes.dart';
import 'dot_atlas.dart';

/// Dots fly in from scattered positions and settle into a silhouette.
///
/// Used for the splash logo (docs/ANIMATION_SPEC.md 1.1) and reusable for the
/// Phase 5 arrival, where the readout's dots scatter and reassemble as the lung
/// cloud — same maths, different endpoints.
class AssemblingDots extends StatelessWidget {
  const AssemblingDots({
    required this.progress,
    this.pathBuilder,
    this.spacing = 12,
    this.dotSize = 3.4,
    this.color = AppColors.textPrimary,
    this.scatter = 1.6,
    this.seed = 7,
    this.semanticsLabel,
    super.key,
  });

  /// 0 = fully scattered, 1 = assembled.
  final Animation<double> progress;

  final Path Function(Size)? pathBuilder;
  final double spacing;
  final double dotSize;
  final Color color;

  /// How far dots start from their target, as a multiple of the field radius.
  final double scatter;

  final int seed;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: semanticsLabel != null,
      child: RepaintBoundary(
        child: CustomPaint(
          isComplex: true,
          painter: _AssemblePainter(
            progress: progress,
            pathBuilder: pathBuilder ?? BreathShapes.lungDome,
            spacing: spacing,
            dotSize: dotSize,
            color: color,
            scatter: scatter,
            seed: seed,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _AssemblePainter extends CustomPainter {
  _AssemblePainter({
    required this.progress,
    required this.pathBuilder,
    required this.spacing,
    required this.dotSize,
    required this.color,
    required this.scatter,
    required this.seed,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Path Function(Size) pathBuilder;
  final double spacing;
  final double dotSize;
  final Color color;
  final double scatter;
  final int seed;

  final DotBatch _bloom = DotBatch(soft: true);
  final DotBatch _core = DotBatch();

  List<Offset> _targets = const [];
  List<Offset> _starts = const [];
  List<double> _delays = const [];
  Size _lastSize = Size.zero;

  void _resample(Size size) {
    if (size == _lastSize) return;
    _lastSize = size;

    final path = pathBuilder(size);
    final targets = <Offset>[];
    final inset = spacing / 2;
    for (var y = inset; y < size.height; y += spacing) {
      for (var x = inset; x < size.width; x += spacing) {
        final point = Offset(x, y);
        if (path.contains(point)) targets.add(point);
      }
    }

    final random = math.Random(seed);
    final centre = size.center(Offset.zero);
    final radius = size.longestSide / 2;
    final maxDistance = radius == 0 ? 1.0 : radius;

    _targets = targets;
    _starts = [
      for (final target in targets)
        () {
          // Scatter outward along the target's own bearing, so the assembly
          // reads as a collapse inward rather than as random noise.
          final bearing = math.atan2(
                target.dy - centre.dy,
                target.dx - centre.dx,
              ) +
              (random.nextDouble() - 0.5) * 1.2;
          final distance = radius * scatter * (0.4 + random.nextDouble() * 0.9);
          return Offset(
            target.dx + math.cos(bearing) * distance,
            target.dy + math.sin(bearing) * distance,
          );
        }(),
    ];
    // Dots nearest the centre land first.
    _delays = [
      for (final target in targets)
        ((target - centre).distance / maxDistance).clamp(0.0, 1.0) * 0.33,
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    _resample(size);
    _bloom.reset();
    _core.reset();

    final t = progress.value.clamp(0.0, 1.0);

    for (var i = 0; i < _targets.length; i++) {
      final delay = _delays[i];
      final span = 1 - delay;
      final local =
          span <= 0 ? 1.0 : ((t - delay) / span).clamp(0.0, 1.0);
      if (local <= 0) continue;

      final eased = Curves.easeOutCubic.transform(local);
      final position = Offset.lerp(_starts[i], _targets[i], eased)!;

      _bloom.add(
        x: position.dx,
        y: position.dy,
        diameter: dotSize * 4,
        color: color,
        opacity: eased * 0.38,
      );
      _core.add(
        x: position.dx,
        y: position.dy,
        diameter: dotSize,
        color: color,
        opacity: eased,
      );
    }

    _bloom.paint(canvas);
    _core.paint(canvas);
  }

  @override
  bool shouldRepaint(_AssemblePainter old) =>
      old.spacing != spacing ||
      old.dotSize != dotSize ||
      old.color != color ||
      old.scatter != scatter;
}
