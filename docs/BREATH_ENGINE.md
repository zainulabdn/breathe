# Breath Engine

Two independent engines share this doc:

- **§1–§6 — the measurement engine:** turns microphone audio into a live flow
  signal and a litre estimate. Drives the Expiratory Volume screen.
- **§7 — the pattern engine:** drives guided breathing sessions. No mic required.

---

## 1. What this actually measures (read this first)

A phone microphone is not a spirometer. What we have is the **acoustic signature of
turbulent airflow across the mic port**. Sound pressure rises monotonically with
flow rate, so the signal is genuinely correlated with how hard you're exhaling —
but the constant of proportionality depends on mouth-to-phone distance, mic model,
lip aperture, ambient noise, and case coverage. None of those are known.

So the honest framing, which the UI must carry:

- The number is a **relative estimate**, meaningful for tracking *your own* trend
  over time on *the same phone with the same technique*.
- It is **not** FVC, FEV1, or PEF, and must never be labelled as such in the UI
  even though those are the terms the underlying maths borrows from.
- Absolute accuracy vs. a real spirometer will be poor. Trend sensitivity — "am I
  better or worse than last week" — is where the value is, and is achievable.

Design consequence: **lead with the trend, not the absolute number.** The result
screen should show the delta and the sparkline more prominently than the litres.
And every result carries a `confidence` score that visibly degrades in a noisy
room rather than silently returning garbage.

## 2. Capture

```
record.startStream(RecordConfig(
  encoder: AudioEncoder.pcm16bits,
  sampleRate: 16000,     // plenty; breath energy is broadband and low
  numChannels: 1,
  androidConfig: AndroidRecordConfig(
    audioSource: AudioSource.unprocessed,   // critical — see below
  ),
  iosConfig: IosRecordConfig(manageAudioSession: true),
))
```

**Disable every enhancement you can.** AGC, noise suppression and echo cancellation
are all designed to flatten exactly the signal we want to measure — AGC in
particular will actively normalise away the loudness differences that carry the
information. On Android request `AudioSource.unprocessed` (falls back to `mic`,
and if it falls back, drop the confidence score). On iOS use
`AVAudioSessionModeMeasurement`, which bypasses the processing chain.

Frames: 512 samples (32 ms) at 16 kHz → ~31 frames/sec. That is the update rate of
the whole reactive UI.

## 3. Per-frame features

For each frame compute:

1. **RMS** → `dbfs = 20 * log10(rms)`. The primary loudness signal.
2. **Zero-crossing rate.** Breath noise is broadband with a high ZCR; voiced
   speech is low. Cheap first-pass discriminator.
3. **Spectral flatness** (geometric mean / arithmetic mean of the magnitude
   spectrum, via a 512-point FFT). Breath ≈ 0.3–0.8 (noise-like). Speech and music
   ≈ < 0.15 (harmonic peaks). **This is the reliable "is this actually a breath"
   test** — it's what stops the app from happily measuring you talking, humming, or
   the TV.
4. **Low-band ratio** — energy below 1 kHz over total. Breath skews low.

A frame counts as breath if `dbfs > floor + 12` **and** `flatness > 0.28` **and**
`lowBandRatio > 0.45`. Tune the thresholds against your own recordings; keep them
in one const block so they're adjustable without hunting.

## 4. Smoothing

Raw RMS is far too jittery to drive an animation directly. Two stages:

1. **Envelope follower** — asymmetric one-pole: fast attack (τ ≈ 15 ms) so the
   start of a blow is instant, slow release (τ ≈ 180 ms) so it doesn't flicker.
2. **Critically-damped spring** on the UI-facing value (ω ≈ 14 rad/s). This is what
   the dot cloud, the slider and the readout actually read, and it's why the
   animation looks liquid instead of noisy.

Never let a raw audio frame reach a widget. `MicSource` emits raw frames;
`BreathAnalyzer` emits smoothed `BreathFrame { flow, db, isBreath, quality }`.

## 5. From loudness to litres

Model flow as proportional to a power of the acoustic amplitude:

```
flow(t) ∝ (rms(t) - noiseFloor) ^ α       α ≈ 0.5 (start here, fit later)
volume  = k * Σ flow(t) * Δt              over the exhale window
```

`k` is the per-user calibration constant, and getting it is the whole game.

**Calibration flow (onboarding, ~60 s):**

1. Measure the ambient floor for 3 s in silence.
2. Compute the user's **predicted vital capacity** from age, height and sex using
   a published reference equation (GLI-2012 or Knudson — pick one, cite it in the
   code comment, and note that these are population averages).
3. Ask for one maximal exhale, coached: deep breath in, then blow out steadily and
   completely, phone held a fixed distance away — **build a visual distance guide
   into the UI**, because inconsistent distance is the single biggest source of
   drift between sessions.
4. Solve `k = predictedVC / Σ flow·Δt` for that blow.
5. Store `k` and `calibratedAt` on the profile. Offer recalibration in settings and
   prompt for it if the phone changes.

This anchors the user's *own baseline* to a plausible value. It does not make the
device accurate in absolute terms, and the code comment at `volume_estimator.dart`
should say exactly that so nobody later mistakes it for a real measurement.

**Confidence score** — start at 1.0 and multiply down for: high ambient floor,
short exhale (< 2 s), low mean flatness, clipping (any sample at ±32767), or
`AudioSource.unprocessed` unavailable. Below 0.5, the result screen shows "Low
confidence — try again somewhere quieter" and the test is excluded from the trend.

## 6. Derived display values

The mock shows "0.24 CO2" and "1.13 O". These cannot be measured by a microphone —
no phone sensor detects gas concentration. Two honest options:

- **Preferred:** relabel them as things you *can* derive — exhale duration,
  peak flow proxy, breath-hold time, or a steadiness score. Same visual layout,
  same two numbers flanking the hint text, no fiction.
- **If you want to keep the mock's labels for the portfolio piece:** render them
  clearly as a *model estimate* — computed from a standard metabolic assumption
  (resting O₂ consumption ≈ 250 ml/min, RER ≈ 0.85, scaled by measured minute
  ventilation) — with a tap target explaining the derivation.

Do not ship numbers labelled "CO2" that are simply animated for effect. That's the
one thing in this design that would cross from stylised into misleading, and it's
the kind of claim that draws App Store health-data scrutiny.

## 7. Pattern engine (guided sessions)

Independent of the mic and fully deterministic — this is the actual "trainer".

```dart
class BreathPattern {
  final List<PhaseSpec> phases;   // e.g. Box: [inhale 4, hold 4, exhale 4, hold 4]
  final int defaultCycles;
}
enum PhaseType { inhale, holdIn, exhale, holdOut }
```

**Built-in presets**

| Name | Pattern (s) | Purpose |
| --- | --- | --- |
| Box | 4-4-4-4 | focus, baseline |
| Relax (4-7-8) | 4-7-8-0 | wind-down, sleep |
| Coherent | 5.5-0-5.5-0 | HRV coherence, the default |
| Energize | 2-0-2-0 ×30, then a hold | alertness |
| Custom | user-defined | settings |

**Driving it:** one `AnimationController` for the whole session with
`duration = totalSeconds`, driven by the vsync ticker. Phase and phase-progress are
computed from `controller.value * totalSeconds` — a pure function of elapsed time.
Do **not** chain per-phase controllers with completion callbacks; the errors
compound and the session drifts audibly over 5 minutes.

Pause/resume via `controller.stop()` / `forward()`. On app background, stop the
ticker and record the timestamp; on resume, offer "continue" or "restart" rather
than silently jumping.

**Safety — non-negotiable.** Fast/hyperventilation-style patterns (Energize, and
anything Wim-Hof-adjacent if you add it) carry a real risk of fainting. Any pattern
with a phase under 3 s or a breath-hold over 30 s must show a one-time interstitial:
never practise while driving, standing, or in water; stop if lightheaded. Gate
long-hold patterns behind an explicit acknowledgement. This is not legal
boilerplate — people do faint doing this.
