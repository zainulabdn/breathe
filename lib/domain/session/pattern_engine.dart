import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'breath_pattern.dart';

@immutable
class SessionFrame {
  const SessionFrame({
    required this.cycleIndex,
    required this.phaseIndex,
    required this.phase,
    required this.phaseProgress,
    required this.phaseSeconds,
    required this.elapsedSeconds,
    required this.amplitude,
    required this.isComplete,
  });

  final int cycleIndex;
  final int phaseIndex;
  final PhaseType phase;

  /// 0–1 through the current phase.
  final double phaseProgress;

  final double phaseSeconds;
  final double elapsedSeconds;

  /// 0 = lungs empty, 1 = lungs full. Drives the orb's scale.
  final double amplitude;

  final bool isComplete;

  /// Seconds left in this phase, rounded up — the countdown the user reads.
  int get phaseSecondsRemaining =>
      math.max(1, (phaseSeconds * (1 - phaseProgress)).ceil());
}

/// Turns elapsed time into a breathing phase.
///
/// Deliberately a pure function of elapsed seconds, with no internal state and
/// no per-phase timers. Chaining a controller per phase and advancing on
/// completion callbacks accumulates a frame of error per transition, which over
/// a 5-minute session drifts far enough to be audible against the haptics.
/// Anything derived from elapsed time can also be sampled *in the past*, which
/// is how the orb gets its trailing layers for free.
class PatternEngine {
  PatternEngine({required this.pattern, required this.cycles})
      : _phases = pattern.activePhases,
        assert(cycles > 0, 'a session needs at least one cycle');

  final BreathPattern pattern;
  final int cycles;
  final List<PhaseSpec> _phases;

  double get cycleSeconds => pattern.cycleSeconds;
  double get totalSeconds => pattern.totalSeconds(cycles);

  SessionFrame frameAt(double elapsedSeconds) {
    final total = totalSeconds;
    final clamped = elapsedSeconds.clamp(0.0, total);
    final complete = elapsedSeconds >= total;

    if (_phases.isEmpty || cycleSeconds <= 0) {
      return SessionFrame(
        cycleIndex: 0,
        phaseIndex: 0,
        phase: PhaseType.inhale,
        phaseProgress: 0,
        phaseSeconds: 0,
        elapsedSeconds: clamped,
        amplitude: 0,
        isComplete: true,
      );
    }

    // On the exact end boundary, report the final phase fully done rather than
    // wrapping to cycle N+1.
    final cycleIndex = complete
        ? cycles - 1
        : (clamped / cycleSeconds).floor().clamp(0, cycles - 1);
    var withinCycle = clamped - cycleIndex * cycleSeconds;

    var phaseIndex = 0;
    var spec = _phases.first;
    for (var i = 0; i < _phases.length; i++) {
      spec = _phases[i];
      phaseIndex = i;
      if (withinCycle < spec.seconds || i == _phases.length - 1) break;
      withinCycle -= spec.seconds;
    }

    final progress =
        spec.seconds <= 0 ? 1.0 : (withinCycle / spec.seconds).clamp(0.0, 1.0);

    return SessionFrame(
      cycleIndex: cycleIndex,
      phaseIndex: phaseIndex,
      phase: spec.type,
      phaseProgress: progress,
      phaseSeconds: spec.seconds,
      elapsedSeconds: clamped,
      amplitude: _amplitude(spec.type, progress),
      isComplete: complete,
    );
  }

  /// `easeInOutSine`, not linear. A linear ramp reads as mechanical and pulls
  /// the user's breath into a shape lungs do not actually make — the whole
  /// point of the orb is that it is followable.
  static double _amplitude(PhaseType phase, double progress) {
    switch (phase) {
      case PhaseType.inhale:
        return _sineEase(progress);
      case PhaseType.exhale:
        return 1 - _sineEase(progress);
      case PhaseType.holdIn:
        return 1;
      case PhaseType.holdOut:
        return 0;
    }
  }

  static double _sineEase(double t) => 0.5 - 0.5 * math.cos(t * math.pi);
}
