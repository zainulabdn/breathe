# Build Plan — Breathe

8 phases, 12–20 days at a solo pace. Each phase has a hard exit criterion; don't
start the next one until the current one is met.

## Brief vs. mock — how the scope was reconciled

The two inputs to this project disagree, and it's worth being explicit about it:

- **The brief** says "improve breathing with guided exercises and calming
  sessions" — the *training* half.
- **The two mock screens** show an Activity dashboard and an Expiratory Volume
  test — the *measurement* half. Neither shows a guided exercise. The only hint
  the training half exists is the small "Training" toggle on the dashboard.

The designer mocked the two visually interesting screens, not the whole product.
So the app builds both halves, and **the ordering follows the brief, not the
mock**: the session player (Phase 3) comes before the mic engine and the test
screen, because guided breathing is what someone opens daily and the lung test is
the weekly progress check on it. A usable trainer exists by ~day 9.

Consequence to accept: there is **no mock reference for the session screens**.
They are designed here in the mock's visual language — black ground, magenta →
violet, the dot idiom, the breathing orb from ANIMATION_SPEC §5 — but they are
our design, not the designer's.

---

## Phase 0 — Foundation ✅ done (2026-09-05)

- `flutter create` (Flutter 3.44.5 / Dart 3.12.2), org `com.faizan`, iOS + Android.
- Structure from ARCHITECTURE §1; `AppColors`, `AppText`, `AppTheme`, `MotionScale`.
- `go_router` skeleton, `ProviderScope`, portrait lock, light status bar.
- Deps: `flutter_riverpod` (resolved **3.4.3**, not 2.x — docs updated), `go_router`.

**Exit met:** black themed shell builds and runs on the iOS simulator.

---

## Phase 1 — The dot-matrix engine ✅ done (2026-09-05)

The highest-risk, highest-reuse piece, built standalone before touching a screen.

- `DotAtlas` — one white circle texture + reusable `DotBatch` buffers, submitted
  as a single `drawRawAtlas` call. Buffers are reset per frame, never reallocated.
- `DotGlyphFont` — 9-row bitmaps for `0-9 . : -` plus blank, authored as strings.
- `DotMatrixText` — centred layout, the hold/exit/enter morph diff, bloom pass,
  `Semantics` label, reduced-motion aware.
- `DotField` — grid masked to a silhouette, liquid fill with a travelling sine
  boundary, per-dot shimmer on a seeded phase.
- `BreathShapes.lungDome` — the normalised dome silhouette.
- `DotLabView` — live harness with a slider for every parameter.
- **14 tests green**, including goldens for the glyph sheet, the readout on the
  card gradient, and the lung field at empty/half/full.

**Exit met:** readout morphs between values and the lung cloud fills smoothly,
verified in goldens and running on the simulator.

**Carried forward:** real frame timings still owed — simulators only run debug,
so the 120fps budget must be profiled on a physical device (Phase 2).

---

## Phase 2 — Activity screen ✅ done (2026-09-05)

Built: `CircleIconButton`, `Pressable` (scale + haptic on every tappable),
`HeroCarousel` with continuous parallax, `LungTestCard` (animated gradient stops,
drifting bloom, orbiting dots, eye toggle), `PageDotsIndicator`, `StatTileTall` +
`TickStripPainter`, `ToggleTile` on a real `SpringSimulation`, `GaugeTile` +
`DottedArcPainter`, `StaggeredEntrance`.

**Splash and onboarding landed here too** (pulled forward from Phase 6 by
request): `AssemblingDots`, `SplashView`, a 3-page `OnboardingView` (value prop →
profile sliders → microphone priming with the honest wellness-estimate notice),
and `OnboardingRepository` on `shared_preferences`.

Two fixes found by looking at it on device rather than by testing:
- `BlendMode.plus` on the card bloom made its contents reject inherited opacity,
  so the carousel's fade forced a saveLayer and tripped an Impeller validation
  break every frame. Now plain source-over.
- The bloom pass was a scaled *hard* circle, which at real dot spacings resolved
  as a flat disc with a visible rim — a dark halo around every dot on black.
  `DotAtlas` now carries a second, soft radial-gradient sprite for bloom passes.

**Still owed:** hardware profiling. Simulators only run debug, so the 120fps
budget remains unverified and moves to Phase 3.

---

## Phase 2 original scope (for reference)

The full first mock screen, static data.

- `CircleIconButton`, app bar.
- `HeroCarousel` with continuous parallax (ANIMATION_SPEC 2.2) + `PageDotsIndicator`.
- `LungTestCard`: gradient + drifting bloom + breathing stops + orbit particles +
  the Phase 1 readout + eye toggle.
- `StatTileTall` with `TickStripPainter`, `ToggleTile` with the spring toggle,
  `GaugeTile` with the dotted arc.
- Entrance stagger, tap feedback, haptics on everything.
- **Profile on a physical device** and settle the Phase 1 perf question.

**Exit:** indistinguishable from the mock at a glance, everything on it moves, and
the raster thread holds its budget on real hardware.

---

## Phase 3 — Session player ✅ done (2026-09-05)

`PatternEngine` is a pure `elapsed → SessionFrame` function off one controller,
covered by 16 tests (phase order, boundary handling, zero-length holds, cycle
advance, 5-minute accuracy). Four presets, `BreathingOrb` with three
time-lagged layers, `PhaseRing`, haptic `SessionCues`, wakelock, pause/resume,
background-pauses-the-session, `SafetySheet` gating Energize, `SessionRepository`
with streak calculation, and the end-of-session dissolve reusing
`AssemblingDots` in reverse.

Entry point is provisional — the ≡ button on Activity opens the picker. Phase 6
gives the daily action real navigation.

**Not done: audio cues.** Haptics only. Wiring an audio engine before there are
sounds to play would add a dependency and a silent code path; it needs actual
sound design and moves to Phase 7.

---

## Phase 3 original scope (for reference)

Moved ahead of the measurement work: this is what the brief describes, it has zero
dependency on the mic, and it is the reason to open the app daily.

- `PatternEngine` off a **single** controller (BREATH_ENGINE §7) — phase computed
  from elapsed time, never chained per-phase controllers, which drift audibly
  over a 5-minute session.
- `BreathingOrb`: three lagged radial-gradient layers, `easeInOutSine` scaling.
- Dotted progress ring around the orb, colour shifting per phase; phase-label
  crossfades; cycle counter on `DotMatrixText`.
- Audio cues + haptics, `wakelock_plus`, pause/resume, background handling.
- Pattern picker (Box, 4-7-8, Coherent, Energize), custom editor.
- **Safety interstitial** for fast/long-hold patterns — non-negotiable.

**Exit:** a 5-minute coherent-breathing session runs with no drift, survives
backgrounding, and saves a `SessionRecord`.

---

## Phase 4 — Breath engine (Days 10–12)

No UI. Built against WAV fixtures first, then a live device.

- `MicSource` — permission flow, `record` PCM stream, unprocessed audio source,
  graceful degradation when unavailable.
- `BreathAnalyzer` — RMS, ZCR, FFT spectral flatness, low-band ratio, the
  breath/not-breath decision (BREATH_ENGINE §3).
- Asymmetric envelope follower + critically-damped spring.
- `VolumeEstimator`, `Calibration`, predicted-value equations, confidence scoring.
- Fixture tests: real exhales, speech, silence, noisy room. **The speech fixture
  must not register as a breath** — that is the key test.
- Debug route plotting flow, dB, flatness and the breath flag live.

**Exit:** blowing produces a clean monotonic flow curve, talking produces nothing,
and three back-to-back blows agree within ~10%.

---

## Phase 5 — Expiratory Volume screen (Days 13–15)

Wires Phase 4 into Phase 1's primitives.

- Hero flight from the carousel card, including the scatter-and-reassemble
  arrival (ANIMATION_SPEC 3.1–3.4).
- `LungDotField` reacting to live flow; `ParticleStream` on exhale.
- `TestSheet`: blurred navy sheet, `BreathSlider` with the spinning half-moon knob
  and acid-yellow trail, flanking readouts, hint state machine.
- Ambient calibration sweep, Finish/Reset, completion sequence.
- Result screen: delta vs. last test, % predicted, confidence, saved to Hive.

**Exit:** a full test runs from card tap to saved record, reacting to real breath.

---

## Phase 6 — Shell: onboarding, history, settings (Days 15–17)

- Splash with the assembling logo.
- Onboarding: value prop → profile → mic priming → calibration blow.
- History: streak, dot-idiom sparkline, session heatmap, export.
- Settings: units, haptics, sound, reminder, recalibrate, clear data.
- Wire real data through the repositories; delete every mock constant.

**Exit:** a fresh install goes from first launch to a saved test and a completed
session without touching a placeholder.

---

## Phase 7 — Polish and release prep (Days 18–20)

- Profile every screen in `--profile` **on hardware**. Usual culprits: an
  unbatched dot loop, a `ref.watch` on the mic stream, a missing `RepaintBoundary`.
- Reduced-motion pass (ANIMATION_SPEC §7) and a full screen-reader pass.
- Empty / error / permission-denied / no-data states, animated like the happy path.
- Bundle Inter, app icon, splash, store screenshots.
- Privacy policy: audio processed on-device, never stored, never transmitted.
- Release builds installed on a physical device of each platform.

---

## Claims and store compliance

Decide before writing marketing copy, not after a rejection:

- Describe the app as **breathing training and wellness tracking**. Never
  "spirometer", "lung function test", "FVC/FEV1", "diagnose", or "monitor a
  condition" — those move it toward regulated-device territory.
- First-run disclaimer: not a medical device, not for diagnosis.
- Keep the safety interstitial for fast-breathing patterns (BREATH_ENGINE §7).
- "Estimate your breathing strength and track your trend" ships; "measure your
  lung capacity" invites a review question you'd rather not answer.

## Risks

| Risk | Mitigation |
| --- | --- |
| Mic estimate too noisy to be useful | Phase 4 is gated on the stability test before Phase 5 depends on it. Fallback is timer-guided estimation behind the same UI. Because the session player now lands in Phase 3, a mic failure no longer threatens the core product. |
| Dot fields drop frames on low-end Android | `drawRawAtlas` batching is in from day one. Physical-device profiling moved into Phase 2 rather than left to the end. |
| Hero flight (3.1–3.3) is finicky | Nice-to-have; a plain fade-through is the escape hatch. |
| Session screens have no mock reference | Derived from the established design language and reviewed against the mock's two screens before Phase 3 exits. |

## Next

Phase 2 — the Activity screen.
