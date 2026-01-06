# Breathe — Breathing Trainer

A guided-breathing and lung-capacity trainer built to match the dark, dot-matrix
mockup: magenta/indigo gradient cards, LED-style numerals, and particle-field
lung visualisations — with every surface animated.

**Stack:** Flutter (iOS + Android) · Riverpod · Hive · CustomPainter/shader-driven UI
**Breath input:** microphone amplitude envelope, calibrated per user
**Status:** planning complete, not yet scaffolded

## Documents

| Doc | What's in it |
| --- | --- |
| [docs/PLAN.md](docs/PLAN.md) | Master build plan — 8 phases across 12–20 days, with exit criteria per phase |
| [docs/DESIGN_SPEC.md](docs/DESIGN_SPEC.md) | Colour, type, spacing and per-component specs read off the mock |
| [docs/ANIMATION_SPEC.md](docs/ANIMATION_SPEC.md) | Every animation: driver, duration, curve, and how it's painted |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Folder layout, state management, data models, package list |
| [docs/BREATH_ENGINE.md](docs/BREATH_ENGINE.md) | Mic DSP, calibration, volume estimation, and the session pattern engine |

## Important framing

The lung measurements here are a **relative wellness estimate derived from
microphone acoustics** — not spirometry. This is not a medical device, it is not
calibrated against a pneumotachograph, and it must never be presented as a
diagnosis. See "Claims and store compliance" in [docs/PLAN.md](docs/PLAN.md).
