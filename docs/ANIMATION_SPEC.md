# Animation Spec

"Fully animated" here means: nothing appears instantly, nothing changes value
without transitioning, and every touch produces motion. This doc is the contract —
each entry names the driver, the timing, and the painting strategy.

## 0. Rules that keep it fast

1. **One controller per painter, not per dot.** A field of 900 dots is one
   `AnimationController` feeding one `CustomPainter` via `AnimatedBuilder`.
   Per-dot variation comes from a seeded phase offset, not from 900 controllers.
2. **Repaint, don't rebuild.** Wrap each animated surface in a `RepaintBoundary`.
   Use `CustomPainter(repaint: controller)` so the widget tree never rebuilds.
3. **Batch draws.** `drawRawAtlas` for anything over ~200 dots. `drawPoints` when
   all dots share a colour and size.
4. **Precompute geometry.** Dot positions, glyph bitmaps and path samples are
   computed once in `didChangeDependencies` / on size change — never in `paint`.
5. **Budget:** every screen holds 120 fps on a mid-range Android. Verify with
   `flutter run --profile` and the raster-thread timeline, not by eye.

## 1. App entry

| # | Animation | Driver | Duration / Curve |
| --- | --- | --- | --- |
| 1.1 | Splash: logo dots fly in from scattered positions to glyph positions | single controller, per-dot delay from seeded noise | 900 ms, `easeOutCubic`, stagger 0–300 ms |
| 1.2 | Splash → Home fade-through | `PageRouteBuilder` | 400 ms, `easeInOut` |

## 2. Activity screen

| # | Animation | Driver | Duration / Curve |
| --- | --- | --- | --- |
| 2.1 | **Entrance stagger** — app bar, carousel, label, dots, then each tile | `flutter_animate` `.fadeIn().slideY(begin: 0.08)` | 500 ms each, 60 ms stagger, `easeOutQuart` |
| 2.2 | **Carousel parallax** — neighbours scale 1.0→0.86, opacity 1.0→0.55, translate for the peek | `PageController.page` (continuous, not discrete) | follows the finger, no duration |
| 2.3 | **Card bloom drift** — the radial highlight on the magenta card slowly orbits | looping controller, 8 s | linear, `Alignment` on a circle of radius 0.15 |
| 2.4 | **Gradient breathe** — gradient stops shift ±0.06 | looping controller, 6 s | `easeInOutSine`, `reverse: true` |
| 2.5 | **Orbit particles** — 3–5 dots travel the arc paths at the card's bottom | looping controller, 5 s | `PathMetric.getTangentForOffset`, each dot at a different `t` offset |
| 2.6 | **Readout morph** — "3.3" → new value: dots that stay lit hold, dots that turn off fade+shrink, dots that turn on scale in from 0.4 | `AnimationController` triggered on value change | 450 ms, off-dots `easeIn` 0–0.4, on-dots `easeOutBack` 0.3–1.0 |
| 2.7 | **Page dots** — active pill widens, inactive shrink | driven by 2.2 | continuous |
| 2.8 | **Tick strip** — the `acidYellow` tick slides to its position and the strip ripples once | `TweenSequence` | 700 ms, `easeOutExpo` |
| 2.9 | **Toggle** — knob travels with overshoot; card glow (`trainingGlow` shadow) ramps 0→1 | `SpringSimulation(stiffness: 500, damping: 22)` | ~380 ms settle |
| 2.10 | **Arc gauge** — dotted arc fills dot-by-dot to the value | staggered per-dot reveal | 800 ms total, 12 ms per dot |
| 2.11 | **Card tap** | `scale 1.0 → 0.97 → 1.0` + light haptic | 120 ms down `easeOut`, 220 ms up `elasticOut` |
| 2.12 | **Eye icon** — toggles the readout between value and `- . -` with a blink (lids close over the dots) | controller | 300 ms |

## 3. Activity → Test transition (the hero moment)

| # | Animation | Detail |
| --- | --- | --- |
| 3.1 | Tapping the Lung test card expands it to full screen | `Hero` on the card with a `createRectTween` using `MaterialRectCenterArcTween` so it arcs rather than travels linearly. 520 ms, `fastOutSlowIn`. |
| 3.2 | During the flight, the card's border radius eases 40 → 0 and the gradient desaturates to black | `Hero.flightShuttleBuilder` interpolating a `DecorationTween` |
| 3.3 | On arrival, the readout dots scatter outward and reassemble as the lung dot-cloud | 600 ms, dots travel along their own bezier, `easeInOutCubic`, 0–200 ms stagger by distance from centre |
| 3.4 | Bottom sheet slides up | 450 ms, `easeOutQuint`, 40 ms after arrival |

## 4. Expiratory Volume (test) screen — the reactive core

The mic drives these in real time. Every value crossing the UI is passed through a
critically-damped smoother first (see BREATH_ENGINE §4) so the animation is never
jittery even though the audio frames are.

| # | Animation | Driver | Behaviour |
| --- | --- | --- | --- |
| 4.1 | **Lung dot-cloud fill** | smoothed `fillLevel` 0–1 | Dots below the fill line are lit at full opacity, above are at `dotOff`. The boundary is not a straight line — it's a sine wave scrolling horizontally (2 s loop, amplitude 6 px) so the "liquid" moves. |
| 4.2 | **Cloud idle shimmer** | looping 3 s controller | Each dot's opacity oscillates ±0.12 with a phase = `hash(index)`. Runs whether or not the user is blowing — the screen is never static. |
| 4.3 | **Exhale response** | mic RMS | Dots detach from the cloud's lower edge and fall as `ParticleStream`. Spawn rate ∝ flow. Gravity 380 px/s², 1.2 s lifetime, fade over the last 400 ms. Cap at 120 live particles. |
| 4.4 | **Readout counting** | smoothed litres | Dot-matrix morph (2.6) fires on every 0.1 L step, so the number visibly climbs during the blow. |
| 4.5 | **Breath slider** | smoothed flow | Knob is a half-filled circle that *rotates* at a rate ∝ flow (so it spins faster the harder you blow) and translates along the track ∝ progress. The `acidYellow` trail is a path that lengthens behind it with a 2-frame lag. Target ring at the end pulses when reached. |
| 4.6 | **CO2 / O readouts** | smoothed derived values | 250 ms `TweenAnimationBuilder` on each change |
| 4.7 | **Hint text** | state machine | Cross-fades between "Take a deep breath" → "Empty your lungs" → "Keep going" → "Hold". 300 ms fade + 6 px slide. |
| 4.8 | **Ambient calibration** | 3 s controller | A ring sweeps around the dot cloud while the noise floor is measured; the cloud dots light up one ring at a time. |
| 4.9 | **Completion** | one-shot | Cloud collapses inward to the readout, readout scales up 1.0→1.15→1.0, `acidYellow` flash at 0.15 opacity over the whole screen, success haptic, then the result sheet rises. 900 ms total. |
| 4.10 | **Reset button** | one-shot | 360° rotation, 500 ms `easeInOutBack`, cloud drains top-to-bottom. |

## 5. Session player

| # | Animation | Detail |
| --- | --- | --- |
| 5.1 | **Breathing orb** | Scale 0.55 → 1.0 on inhale, hold at 1.0, 1.0 → 0.55 on exhale, hold. **Curve is `easeInOutSine`, not linear** — a linear scale reads as mechanical and actively fights the physiology you're coaching. Duration = the phase duration from the pattern. |
| 5.2 | **Orb layers** | 3 concentric radial gradients at 1.0×, 1.12×, 1.26× scale with 120 ms and 240 ms lag, giving a soft trailing bloom. |
| 5.3 | **Ring progress** | Dotted ring around the orb; dots light up over the phase duration. Colour shifts magenta (inhale) → violet (hold) → indigo (exhale). |
| 5.4 | **Phase label** | Cross-fade + 8 px rise on each phase change, 280 ms. |
| 5.5 | **Haptics** | `HapticFeedback.mediumImpact` on inhale start, `lightImpact` on exhale start, `selectionClick` per second during holds. |
| 5.6 | **Cycle counter** | Dot-matrix morph per completed cycle. |
| 5.7 | **Session end** | Orb dissolves into particles that drift upward and fade, 1.4 s, then the summary card rises. |

## 6. History, settings, global

| # | Animation | Detail |
| --- | --- | --- |
| 6.1 | Sparkline draws left-to-right | `PathMetric.extractPath` animated 0→1, 900 ms `easeOutCubic` |
| 6.2 | Heatmap cells | staggered scale-in, 8 ms per cell, row-major |
| 6.3 | Route transitions | Shared-axis horizontal for sibling routes (300 ms), fade-through for tab changes (220 ms) |
| 6.4 | List items | `.fadeIn().slideX(begin: 0.05)`, 40 ms stagger, capped at the first 12 items |
| 6.5 | Pull-to-refresh | Dot ring that assembles as you pull |
| 6.6 | Every button | scale 0.96 on press + selection haptic. Zero exceptions. |
| 6.7 | Loading | Never a `CircularProgressIndicator` — a dot ring chasing itself, 1.2 s loop |

## 7. Reduced motion

When `MediaQuery.of(context).disableAnimations` is true:
- All looping ambient animations (2.3, 2.4, 2.5, 4.2) stop at their rest frame.
- Morphs and transitions become instant value swaps.
- Particle streams (4.3, 5.7) are disabled entirely.
- Functional feedback stays: the readout still updates, the fill level still moves,
  just without interpolation.

Implement this once as a `MotionScale` inherited widget that multiplies every
duration by `0.0` or `1.0`, rather than checking the flag in 40 places.
