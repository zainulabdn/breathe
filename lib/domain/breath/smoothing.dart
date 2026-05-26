import 'dart:math' as math;

/// Asymmetric one-pole envelope follower.
///
/// Fast attack so the start of a blow registers immediately; slow release so
/// the signal does not flicker between audio frames. This asymmetry is the
/// whole point — a symmetric filter either lags the onset or chatters on the
/// tail, and there is no single time constant that avoids both.
///
/// See docs/BREATH_ENGINE.md §4.
class EnvelopeFollower {
  EnvelopeFollower({
    this.attackSeconds = 0.015,
    this.releaseSeconds = 0.18,
  });

  final double attackSeconds;
  final double releaseSeconds;

  double _value = 0;
  double get value => _value;

  double update(double input, double dt) {
    if (dt <= 0) return _value;
    final tau = input > _value ? attackSeconds : releaseSeconds;
    // Exact one-pole step, so behaviour does not change with frame rate.
    final alpha = 1 - math.exp(-dt / math.max(tau, 1e-6));
    _value += (input - _value) * alpha;
    return _value;
  }

  void reset([double value = 0]) => _value = value;
}

/// Critically damped spring — the value the UI actually reads.
///
/// Solved analytically rather than integrated step-by-step, so it is stable at
/// any frame interval, including the long one after a dropped frame. Critically
/// damped means it never overshoots: a readout that oscillates past the value
/// you blew looks broken, however pretty the motion is.
class CriticallyDampedSpring {
  CriticallyDampedSpring({this.omega = 14, double initial = 0})
      : _value = initial;

  /// Angular frequency. Higher tracks more tightly and feels less smooth.
  final double omega;

  double _value;
  double _velocity = 0;

  double get value => _value;
  double get velocity => _velocity;

  double update(double target, double dt) {
    if (dt <= 0) return _value;
    // x(t) = target + (A + B t) e^(-w t), critically damped closed form.
    final a = _value - target;
    final b = _velocity + omega * a;
    final decay = math.exp(-omega * dt);
    _value = target + (a + b * dt) * decay;
    _velocity = (b - omega * (a + b * dt)) * decay;
    return _value;
  }

  void reset([double value = 0]) {
    _value = value;
    _velocity = 0;
  }
}
