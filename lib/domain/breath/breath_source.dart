/// Where the flow signal comes from.
///
/// The Expiratory Volume screen depends on this interface and nothing else —
/// it needs one number, "how hard is air moving right now", between 0 and 1.
/// That keeps the screen's 14 animations independent of the microphone DSP, so
/// the two can be built and debugged separately, and so a mic that turns out
/// too noisy to trust (docs/PLAN.md, Risks) does not invalidate the screen.
abstract class BreathSource {
  /// Instantaneous, unsmoothed flow, 0–1. Smoothing belongs to the controller
  /// so every source gets the same treatment.
  double get rawFlow;

  /// True when the signal looks like breath rather than noise or speech. The
  /// simulated source is always true; the mic source will run the spectral
  /// flatness test from docs/BREATH_ENGINE.md §3.
  bool get isBreath;

  /// 0–1. Degraded by ambient noise, clipping, or a too-short exhale.
  double get confidence;

  Future<void> start();
  Future<void> stop();
  void dispose();
}

/// Touch-driven stand-in for the microphone: press and hold to blow.
///
/// Not a toy — it is how the screen gets developed and demoed without a
/// physical device, and it stays useful afterwards as the fallback for
/// permission-denied and for widget tests, which cannot blow into anything.
class SimulatedBreathSource implements BreathSource {
  double _pressure = 0;
  bool _running = false;

  /// Called by the UI while the user holds down.
  void setPressure(double value) {
    _pressure = value.clamp(0.0, 1.0);
  }

  @override
  double get rawFlow => _running ? _pressure : 0;

  @override
  bool get isBreath => _pressure > 0.02;

  @override
  double get confidence => 1;

  @override
  Future<void> start() async => _running = true;

  @override
  Future<void> stop() async {
    _running = false;
    _pressure = 0;
  }

  @override
  void dispose() {}
}
