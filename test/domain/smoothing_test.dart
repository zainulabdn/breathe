import 'package:breathe/domain/breath/smoothing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnvelopeFollower', () {
    test('attacks far faster than it releases', () {
      final rise = EnvelopeFollower();
      final fall = EnvelopeFollower()..reset(1);

      // 30ms of a step input, up vs down.
      for (var i = 0; i < 3; i++) {
        rise.update(1, 0.01);
        fall.update(0, 0.01);
      }

      expect(rise.value, greaterThan(0.8),
          reason: 'the onset of a blow must register immediately');
      expect(fall.value, greaterThan(0.8),
          reason: 'the tail must decay slowly or the signal chatters');
    });

    test('converges to a held input', () {
      final follower = EnvelopeFollower();
      for (var i = 0; i < 200; i++) {
        follower.update(0.6, 0.01);
      }
      expect(follower.value, closeTo(0.6, 1e-3));
    });

    test('is frame-rate independent', () {
      final fast = EnvelopeFollower();
      final slow = EnvelopeFollower();

      for (var i = 0; i < 100; i++) {
        fast.update(1, 0.001);
      }
      for (var i = 0; i < 10; i++) {
        slow.update(1, 0.01);
      }

      // Same elapsed time by two different step sizes -> same answer.
      expect(fast.value, closeTo(slow.value, 1e-6));
    });

    test('ignores non-positive time steps', () {
      final follower = EnvelopeFollower()..update(1, 0.1);
      final before = follower.value;
      expect(follower.update(0, 0), before);
      expect(follower.update(0, -1), before);
    });
  });

  group('CriticallyDampedSpring', () {
    test('never overshoots its target', () {
      final spring = CriticallyDampedSpring();
      var maximum = 0.0;
      for (var i = 0; i < 300; i++) {
        maximum = spring.update(1, 1 / 60).clamp(maximum, double.infinity);
      }
      expect(maximum, lessThanOrEqualTo(1.0 + 1e-9),
          reason: 'a readout that swings past what you blew looks broken');
    });

    test('approaches monotonically from rest', () {
      final spring = CriticallyDampedSpring();
      var previous = -1.0;
      for (var i = 0; i < 120; i++) {
        final value = spring.update(1, 1 / 60);
        expect(value, greaterThanOrEqualTo(previous - 1e-12));
        previous = value;
      }
    });

    test('settles close to the target within a reasonable time', () {
      final spring = CriticallyDampedSpring();
      for (var i = 0; i < 60; i++) {
        spring.update(1, 1 / 60);
      }
      expect(spring.value, closeTo(1, 0.01),
          reason: 'one second should be more than enough at omega 14');
    });

    test('stays stable across a long dropped-frame gap', () {
      final spring = CriticallyDampedSpring();
      spring.update(1, 0.5); // a catastrophic hitch
      expect(spring.value.isFinite, isTrue);
      expect(spring.value, inInclusiveRange(0, 1));

      // A naive Euler integrator diverges here; the closed form does not.
      spring.update(0, 2.0);
      expect(spring.value.isFinite, isTrue);
      expect(spring.value, inInclusiveRange(-0.01, 1));
    });

    test('tracks a moving target without lagging a full second', () {
      final spring = CriticallyDampedSpring();
      for (var i = 0; i < 120; i++) {
        spring.update(0.5, 1 / 60);
      }
      expect(spring.value, closeTo(0.5, 1e-3));
    });
  });
}
