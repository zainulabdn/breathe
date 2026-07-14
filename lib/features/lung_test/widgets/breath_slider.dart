import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/theme/app_colors.dart';
import '../../../dots/dot_atlas.dart';

/// The knob-and-trail readout in the bottom sheet.
///
/// The knob does two independent things: it *travels* with accumulated volume,
/// and it *spins* at a rate set by instantaneous flow. Splitting them means the
/// control still responds the moment you blow harder, even though the position
/// it is reporting is smoothed and slow. A single spinning-and-sliding element
/// carries both without needing two widgets.
class BreathSlider extends StatefulWidget {
  const BreathSlider({
    required this.progress,
    required this.flow,
    required this.peakProgress,
    this.targetProgress = 0.82,
    super.key,
  });

  /// 0–1 accumulated volume.
  final double progress;

  /// 0–1 instantaneous flow; sets the knob's spin rate.
  final double flow;

  /// Furthest point reached, marked by the trail's end dot.
  final double peakProgress;

  /// Where the goal ring sits.
  final double targetProgress;

  @override
  State<BreathSlider> createState() => _BreathSliderState();
}

class _BreathSliderState extends State<BreathSlider>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _angle = ValueNotifier(0);
  late final Ticker _ticker = createTicker(_onTick);
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _angle.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _last = elapsed;
    // Idles slowly so the control never looks dead, then accelerates hard.
    _angle.value += (0.35 + widget.flow * 9) * dt;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Breath progress ${(widget.progress * 100).round()} percent',
      child: RepaintBoundary(
        child: SizedBox(
          height: 56,
          child: CustomPaint(
            painter: _SliderPainter(
              angle: _angle,
              progress: widget.progress.clamp(0.0, 1.0),
              peakProgress: widget.peakProgress.clamp(0.0, 1.0),
              targetProgress: widget.targetProgress,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _SliderPainter extends CustomPainter {
  _SliderPainter({
    required this.angle,
    required this.progress,
    required this.peakProgress,
    required this.targetProgress,
  }) : super(repaint: angle);

  final ValueNotifier<double> angle;
  final double progress;
  final double peakProgress;
  final double targetProgress;

  final DotBatch _dots = DotBatch();

  static const double _knobRadius = 15;

  @override
  void paint(Canvas canvas, Size size) {
    _dots.reset();

    final y = size.height / 2;
    final left = _knobRadius + 4;
    final right = size.width - _knobRadius - 4;
    final span = right - left;

    final knobX = left + span * progress;
    final peakX = left + span * math.max(peakProgress, progress);
    final targetX = left + span * targetProgress;

    _paintDottedTrack(left, right, y, peakX);
    _paintTrail(canvas, knobX, peakX, y);
    _paintTargetRing(targetX, y);
    _paintKnob(canvas, knobX, y);

    _dots.paint(canvas);
  }

  /// The dotted rail the knob rides along, running the full width. In the mock
  /// this is what makes the control read as a track with somewhere to go,
  /// rather than a knob floating on a line.
  void _paintDottedTrack(double left, double right, double y, double peakX) {
    const spacing = 7.0;
    for (var x = left; x <= right; x += spacing) {
      // Dots already passed are dimmer — the rail ahead is what matters.
      final ahead = x > peakX;
      _dots.add(
        x: x,
        y: y,
        diameter: 1.9,
        color: Colors.white,
        opacity: ahead ? 0.30 : 0.13,
      );
    }
  }

  void _paintTrail(Canvas canvas, double knobX, double peakX, double y) {
    if (peakX <= knobX + 1) return;
    canvas.drawLine(
      Offset(knobX, y),
      Offset(peakX, y),
      Paint()
        ..color = AppColors.acidYellow
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    _dots.add(x: peakX, y: y, diameter: 5, color: AppColors.acidYellow);
  }

  /// Dotted, like the mock — a solid ring reads as a filled control rather
  /// than as a goal you have not reached yet.
  void _paintTargetRing(double x, double y) {
    final reached = peakProgress >= targetProgress;
    const count = 22;
    for (var i = 0; i < count; i++) {
      final a = (i / count) * 2 * math.pi;
      _dots.add(
        x: x + 13 * math.cos(a),
        y: y + 13 * math.sin(a),
        diameter: reached ? 2.2 : 1.7,
        color: reached ? AppColors.acidYellow : Colors.white,
        opacity: reached ? 0.95 : 0.30,
      );
    }
  }

  void _paintKnob(Canvas canvas, double x, double y) {
    final centre = Offset(x, y);
    final theta = angle.value;

    // Dotted ring around the knob.
    const ringDots = 18;
    for (var i = 0; i < ringDots; i++) {
      final a = theta * 0.35 + (i / ringDots) * 2 * math.pi;
      _dots.add(
        x: centre.dx + (_knobRadius + 5) * math.cos(a),
        y: centre.dy + (_knobRadius + 5) * math.sin(a),
        diameter: 1.8,
        color: Colors.white,
        opacity: 0.45,
      );
    }

    canvas.drawCircle(
      centre,
      _knobRadius,
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );

    // The lit half, rotating — this is what visibly spins up as flow rises.
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: _knobRadius),
      theta,
      math.pi,
      true,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_SliderPainter old) =>
      old.progress != progress ||
      old.peakProgress != peakProgress ||
      old.targetProgress != targetProgress;
}
