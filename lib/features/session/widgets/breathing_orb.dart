import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/motion/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/session/breath_pattern.dart';

/// The orb. Three concentric layers whose scales come from the breath
/// amplitude sampled at three points in time — now, 120ms ago and 240ms ago —
/// so the outer layers trail the core.
///
/// The lag is free because `PatternEngine` is a pure function of elapsed time:
/// the trailing layers are literally the same maths evaluated in the past,
/// rather than a second animation chasing the first.
///
/// It is drawn as a slowly deforming blob, not a circle, and squashes with the
/// *rate* of the breath. A perfect circle scaling up and down reads as a
/// progress indicator; something that deforms reads as alive, which is the
/// difference between watching a timer and being led by it.
class BreathingOrb extends StatefulWidget {
  const BreathingOrb({
    required this.amplitudes,
    required this.phase,
    this.velocity = 0,
    super.key,
  });

  /// [now, 120ms ago, 240ms ago], each 0–1.
  final List<double> amplitudes;

  final PhaseType phase;

  /// Rate of change of amplitude, roughly -1..1. Positive stretches the orb
  /// vertically (drawing breath in), negative squashes it (pushing it out).
  final double velocity;

  static Color colorFor(PhaseType phase) => switch (phase) {
        PhaseType.inhale => AppColors.magenta,
        PhaseType.holdIn => AppColors.orchid,
        PhaseType.exhale => AppColors.indigoPeek,
        PhaseType.holdOut => AppColors.violet,
      };

  @override
  State<BreathingOrb> createState() => _BreathingOrbState();
}

class _BreathingOrbState extends State<BreathingOrb>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _time = ValueNotifier(0);
  late final Ticker _ticker = createTicker(_onTick);

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MotionScale.ambientAllowed(context)) {
      if (!_ticker.isActive) _ticker.start();
    } else if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) =>
      _time.value = elapsed.inMicroseconds / 1e6;

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _OrbPainter(
          time: _time,
          amplitudes: widget.amplitudes,
          color: BreathingOrb.colorFor(widget.phase),
          velocity: widget.velocity.clamp(-1.0, 1.0),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.time,
    required this.amplitudes,
    required this.color,
    required this.velocity,
  }) : super(repaint: time);

  final ValueNotifier<double> time;
  final List<double> amplitudes;
  final Color color;
  final double velocity;

  /// Outer layers are larger, dimmer, and wobble a little more freely.
  static const _layerScale = [1.0, 1.14, 1.30];
  static const _layerAlpha = [0.95, 0.34, 0.16];
  static const _layerWobble = [0.030, 0.045, 0.060];

  static const int _steps = 72;

  double wobbleOf(int layer) => _layerWobble[layer];

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final base = size.shortestSide / 2 * 0.60;
    final t = time.value;

    // Squash and stretch: volume-preserving, so the orb never looks like it
    // simply got bigger in one axis.
    final stretch = 1 + velocity * 0.16;
    final squash = 1 / stretch;

    for (var i = _layerScale.length - 1; i >= 0; i--) {
      final amplitude = amplitudes[i.clamp(0, amplitudes.length - 1)];
      // Never fully collapses — an orb that vanishes on the exhale gives the
      // user nothing to follow back up.
      final radius = base * (0.55 + 0.45 * amplitude) * _layerScale[i];
      if (radius <= 0) continue;

      final path = _blobPath(
        centre: centre,
        radius: radius,
        time: t - i * 0.12,
        wobble: _layerWobble[i],
        stretch: stretch,
        squash: squash,
      );

      // The gradient must reach zero alpha exactly at the blob's own maximum
      // radius. Any larger and the path clips the gradient mid-fade, which
      // draws a hard rim and makes the three layers read as concentric rings
      // instead of one soft body.
      final rect = Rect.fromCircle(
        center: centre,
        radius: radius * (1 + wobbleOf(i)) * math.max(stretch, squash),
      );
      canvas.drawPath(
        path,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: _layerAlpha[i]),
              color.withValues(alpha: _layerAlpha[i] * 0.5),
              color.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(rect),
      );
    }
  }

  /// A closed blob whose radius is a sum of sines in angle and time. Three
  /// terms is enough to look organic and never obviously periodic.
  Path _blobPath({
    required Offset centre,
    required double radius,
    required double time,
    required double wobble,
    required double stretch,
    required double squash,
  }) {
    final path = Path();
    for (var i = 0; i <= _steps; i++) {
      final angle = i / _steps * 2 * math.pi;
      final deform = math.sin(angle * 3 + time * 1.3) * 0.5 +
          math.sin(angle * 5 - time * 0.9) * 0.3 +
          math.sin(angle * 2 + time * 0.6) * 0.2;
      final r = radius * (1 + wobble * deform);

      final point = Offset(
        centre.dx + r * math.cos(angle) * squash,
        centre.dy + r * math.sin(angle) * stretch,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.color != color ||
      old.velocity != velocity ||
      old.amplitudes[0] != amplitudes[0] ||
      old.amplitudes[1] != amplitudes[1] ||
      old.amplitudes[2] != amplitudes[2];
}
