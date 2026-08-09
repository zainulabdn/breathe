import 'package:breathe/domain/session/breath_pattern.dart';
import 'package:breathe/domain/session/pattern_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BreathPattern', () {
    test('cycleSeconds ignores zero-length phases', () {
      expect(BreathPattern.box.cycleSeconds, 16);
      expect(BreathPattern.coherent.cycleSeconds, 11);
      expect(BreathPattern.relax478.cycleSeconds, 19);
    });

    test('flags patterns that need the safety notice', () {
      expect(BreathPattern.energize.needsSafetyNotice, isTrue,
          reason: '2s breaths are rapid enough to risk light-headedness');
      expect(BreathPattern.coherent.needsSafetyNotice, isFalse);
      expect(BreathPattern.box.needsSafetyNotice, isFalse);
      expect(BreathPattern.relax478.needsSafetyNotice, isFalse);
    });

    test('a zero-length hold is not treated as a long hold', () {
      expect(BreathPattern.coherent.hasLongHold, isFalse);
    });

    test('summary reads as the familiar count string', () {
      expect(BreathPattern.box.summary, '4-4-4-4');
      expect(BreathPattern.relax478.summary, '4-7-8-0');
      expect(BreathPattern.coherent.summary, '5.5-0-5.5-0');
    });
  });

  group('PatternEngine — box 4-4-4-4', () {
    final engine = PatternEngine(pattern: BreathPattern.box, cycles: 3);

    test('starts on the inhale', () {
      final frame = engine.frameAt(0);
      expect(frame.phase, PhaseType.inhale);
      expect(frame.phaseProgress, 0);
      expect(frame.amplitude, 0);
      expect(frame.cycleIndex, 0);
    });

    test('walks the four phases in order', () {
      expect(engine.frameAt(2).phase, PhaseType.inhale);
      expect(engine.frameAt(5).phase, PhaseType.holdIn);
      expect(engine.frameAt(9).phase, PhaseType.exhale);
      expect(engine.frameAt(13).phase, PhaseType.holdOut);
    });

    test('phase boundaries land on the next phase, not the previous', () {
      expect(engine.frameAt(4).phase, PhaseType.holdIn);
      expect(engine.frameAt(8).phase, PhaseType.exhale);
      expect(engine.frameAt(12).phase, PhaseType.holdOut);
    });

    test('advances cycles without drift', () {
      expect(engine.frameAt(16).cycleIndex, 1);
      expect(engine.frameAt(16).phase, PhaseType.inhale);
      expect(engine.frameAt(32).cycleIndex, 2);
      expect(engine.frameAt(32).phase, PhaseType.inhale);
    });

    test('amplitude rises through inhale and falls through exhale', () {
      expect(engine.frameAt(0).amplitude, closeTo(0, 1e-9));
      expect(engine.frameAt(2).amplitude, closeTo(0.5, 1e-9));
      expect(engine.frameAt(4).amplitude, 1);
      expect(engine.frameAt(6).amplitude, 1, reason: 'holds stay full');
      expect(engine.frameAt(10).amplitude, closeTo(0.5, 1e-9));
      expect(engine.frameAt(14).amplitude, 0, reason: 'holds stay empty');
    });

    test('amplitude is monotonic across the inhale', () {
      var previous = -1.0;
      for (var t = 0.0; t <= 4.0; t += 0.1) {
        final value = engine.frameAt(t).amplitude;
        expect(value, greaterThanOrEqualTo(previous));
        previous = value;
      }
    });

    test('completes exactly at the total duration', () {
      expect(engine.totalSeconds, 48);
      expect(engine.frameAt(47.9).isComplete, isFalse);
      expect(engine.frameAt(48).isComplete, isTrue);
      expect(engine.frameAt(48).cycleIndex, 2,
          reason: 'the end boundary must not wrap to a cycle that never ran');
      expect(engine.frameAt(999).isComplete, isTrue);
    });

    test('countdown counts down whole seconds', () {
      expect(engine.frameAt(0).phaseSecondsRemaining, 4);
      expect(engine.frameAt(3.5).phaseSecondsRemaining, 1);
    });
  });

  group('PatternEngine — patterns with zero-length holds', () {
    final engine = PatternEngine(pattern: BreathPattern.coherent, cycles: 2);

    test('skips the empty holds entirely', () {
      expect(engine.frameAt(0).phase, PhaseType.inhale);
      expect(engine.frameAt(5.4).phase, PhaseType.inhale);
      expect(engine.frameAt(5.5).phase, PhaseType.exhale,
          reason: 'a 0-second holdIn must not consume a frame');
      expect(engine.frameAt(11).cycleIndex, 1);
      expect(engine.frameAt(11).phase, PhaseType.inhale);
    });

    test('never reports a zero-length phase', () {
      for (var t = 0.0; t < engine.totalSeconds; t += 0.05) {
        expect(engine.frameAt(t).phaseSeconds, greaterThan(0));
      }
    });
  });

  group('PatternEngine — long-run accuracy', () {
    test('a 5 minute session lands on the right cycle at the end', () {
      final engine = PatternEngine(pattern: BreathPattern.coherent, cycles: 27);
      expect(engine.totalSeconds, closeTo(297, 1e-9));

      // The point of a pure time -> phase mapping: sampling far into the
      // session is exact, with no error accumulated from earlier transitions.
      final last = engine.frameAt(296.9);
      expect(last.cycleIndex, 26);
      expect(last.phase, PhaseType.exhale);
      expect(engine.frameAt(297).isComplete, isTrue);
    });

    test('sampling backwards in time is valid (the orb lag depends on it)', () {
      final engine = PatternEngine(pattern: BreathPattern.box, cycles: 5);
      expect(engine.frameAt(-0.24).phase, PhaseType.inhale);
      expect(engine.frameAt(-0.24).amplitude, 0);
    });
  });
}
