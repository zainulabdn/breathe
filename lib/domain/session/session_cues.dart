import 'package:flutter/services.dart';

import 'breath_pattern.dart';
import 'pattern_engine.dart';

/// Non-visual pacing: haptics now, audio later.
///
/// The point of cueing at all is that a guided session should be followable
/// with the screen face-down or your eyes shut — if you have to watch the orb,
/// the app is asking for the attention it is supposed to be settling.
///
/// TODO(phase-7): add audio cues. Deliberately not stubbed with a package yet —
/// it needs actual sound design (a soft tone per transition, not a beep), and
/// wiring an audio engine before there are assets to play just adds a
/// dependency and a silent code path.
class SessionCues {
  PhaseType? _lastPhase;
  int _lastHoldSecond = -1;

  void reset() {
    _lastPhase = null;
    _lastHoldSecond = -1;
  }

  /// Call every frame; fires only on the transitions that matter.
  void update(SessionFrame frame, {bool enabled = true}) {
    if (!enabled) return;

    if (frame.phase != _lastPhase) {
      _lastPhase = frame.phase;
      _lastHoldSecond = -1;
      switch (frame.phase) {
        case PhaseType.inhale:
          HapticFeedback.mediumImpact();
        case PhaseType.exhale:
          HapticFeedback.lightImpact();
        case PhaseType.holdIn:
        case PhaseType.holdOut:
          HapticFeedback.selectionClick();
      }
      return;
    }

    // During a hold the orb is still, so a per-second tick is the only signal
    // that the session is still running.
    if (frame.phase.isHold) {
      final second = (frame.phaseProgress * frame.phaseSeconds).floor();
      if (second != _lastHoldSecond && second > 0) {
        _lastHoldSecond = second;
        HapticFeedback.selectionClick();
      }
    }
  }

  void complete({bool enabled = true}) {
    if (enabled) HapticFeedback.heavyImpact();
  }
}
