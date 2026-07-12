import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../../domain/breath/breath_source.dart';
import '../../../domain/breath/smoothing.dart';

enum TestStage { ready, measuring, finished }

enum TestHint { ready, blow, keepGoing, easeOff, done }

extension TestHintLabel on TestHint {
  String get label => switch (this) {
        TestHint.ready => 'Take a deep breath',
        TestHint.blow => 'Empty your lungs',
        TestHint.keepGoing => 'Keep going',
        TestHint.easeOff => 'Almost there',
        TestHint.done => 'Well done',
      };
}

@immutable
class BreathReading {
  const BreathReading({
    this.flow = 0,
    this.liters = 0,
    this.peakFlow = 0,
    this.exhaleSeconds = 0,
    this.stage = TestStage.ready,
    this.hint = TestHint.ready,
    this.confidence = 1,
  });

  /// Smoothed 0–1 flow. Drives the lung fill, the particles and the slider.
  final double flow;

  final double liters;
  final double peakFlow;
  final double exhaleSeconds;
  final TestStage stage;
  final TestHint hint;
  final double confidence;

  /// 0–1 against a nominal 6 L ceiling, for the lung field's fill level.
  double get fillFraction => (liters / 6.0).clamp(0.0, 1.0);

  String get litersLabel => liters.toStringAsFixed(1);
}

/// Owns the smoothing chain and the accumulated volume.
///
/// Publishes through a [ValueNotifier] rather than a Riverpod stream on
/// purpose: this updates at frame rate, and `ref.watch` on a 60Hz source would
/// rebuild the whole subtree every frame (docs/ARCHITECTURE.md §2). Only the
/// painters listen.
class BreathTestController {
  BreathTestController({
    required TickerProvider vsync,
    required this.source,
    this.calibrationK = 1.4,
  }) {
    _ticker = vsync.createTicker(_onTick);
  }

  final BreathSource source;

  /// Litres per unit of flow per second. In Phase 4 this comes from the user's
  /// calibration blow (docs/BREATH_ENGINE.md §5) instead of being a constant.
  final double calibrationK;

  final ValueNotifier<BreathReading> reading =
      ValueNotifier(const BreathReading());

  late final Ticker _ticker;
  final _envelope = EnvelopeFollower();
  final _spring = CriticallyDampedSpring();

  Duration _lastTick = Duration.zero;
  double _liters = 0;
  double _peak = 0;
  double _exhaleSeconds = 0;
  TestStage _stage = TestStage.ready;

  Future<void> start() async {
    await source.start();
    _lastTick = Duration.zero;
    _stage = TestStage.measuring;
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    // Real elapsed time, clamped so a hitch cannot integrate a huge volume in
    // one frame.
    final dt = _lastTick == Duration.zero
        ? 1 / 60
        : ((elapsed - _lastTick).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _lastTick = elapsed;

    final envelope = _envelope.update(source.rawFlow, dt);
    final flow = _spring.update(envelope, dt).clamp(0.0, 1.0);

    if (flow > 0.04 && source.isBreath) {
      _liters += flow * calibrationK * dt;
      _exhaleSeconds += dt;
      if (flow > _peak) _peak = flow;
    }

    reading.value = BreathReading(
      flow: flow,
      liters: _liters,
      peakFlow: _peak,
      exhaleSeconds: _exhaleSeconds,
      stage: _stage,
      hint: _hintFor(flow),
      confidence: source.confidence,
    );
  }

  TestHint _hintFor(double flow) {
    if (_stage == TestStage.finished) return TestHint.done;
    if (flow <= 0.04) return _liters > 0.1 ? TestHint.keepGoing : TestHint.ready;
    if (_exhaleSeconds > 4.5) return TestHint.easeOff;
    if (_exhaleSeconds > 2.0) return TestHint.keepGoing;
    return TestHint.blow;
  }

  Future<void> finish() async {
    _stage = TestStage.finished;
    _ticker.stop();
    await source.stop();
    reading.value = BreathReading(
      flow: 0,
      liters: _liters,
      peakFlow: _peak,
      exhaleSeconds: _exhaleSeconds,
      stage: TestStage.finished,
      hint: TestHint.done,
      confidence: source.confidence,
    );
  }

  Future<void> reset() async {
    _liters = 0;
    _peak = 0;
    _exhaleSeconds = 0;
    _stage = TestStage.measuring;
    _envelope.reset();
    _spring.reset();
    _lastTick = Duration.zero;
    reading.value = const BreathReading(stage: TestStage.measuring);
    if (!_ticker.isActive) _ticker.start();
    await source.start();
  }

  void dispose() {
    _ticker.dispose();
    source.dispose();
    reading.dispose();
  }
}
