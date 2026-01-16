# Design Spec

Values below are sampled from the mockup image. Treat them as a starting point —
if you get the original design file, re-sample and update this doc first, then the
theme file. The theme is the single source of truth in code; no raw hex in widgets.

## 1. Palette

```dart
// core/theme/app_colors.dart
class AppColors {
  // Surfaces
  static const bg          = Color(0xFF050505); // page background, near-pure black
  static const surface     = Color(0xFF121212); // "Daily Smook" card
  static const surfaceHigh = Color(0xFF1C1C1E); // circular icon buttons

  // Lung test card (magenta → violet, diagonal)
  static const magenta     = Color(0xFFFF3DB4);
  static const orchid      = Color(0xFFC845F0);
  static const violet      = Color(0xFF7B2FF7);

  // Neighbour cards peeking in the carousel
  static const indigoPeek  = Color(0xFF6B4EFF);
  static const peachPeek   = Color(0xFFFFB27A);

  // Tiles
  static const trainingBlue = Color(0xFF1E2A78); // "Training" toggle card
  static const trainingGlow = Color(0xFF3D5AFE);
  static const volumeRed    = Color(0xFFE5342A); // "Breath Volume" card
  static const volumeAmber  = Color(0xFFFF7A45);

  // Accents
  static const acidYellow  = Color(0xFFD4FF3D); // slider trail, chart highlight tick
  static const sheetNavy   = Color(0xFF232B6B); // bottom sheet on the test screen

  // Text
  static const textPrimary   = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xB3FFFFFF); // 70%
  static const textTertiary  = Color(0x66FFFFFF); // 40%
  static const dotOff        = Color(0x1AFFFFFF); // 10% — unlit dot-matrix cell
}
```

**Gradient recipes**

- *Lung test card:* `LinearGradient(begin: topLeft, end: bottomRight, colors: [magenta, orchid, violet], stops: [0.0, 0.45, 1.0])` plus a radial highlight at ~(0.3, 0.25) in `magenta.withOpacity(0.55)` to reproduce the bloom. The card also casts a coloured shadow: `BoxShadow(color: magenta.withOpacity(0.35), blurRadius: 48, spreadRadius: -8, offset: Offset(0, 12))`.
- *Breath Volume tile:* `LinearGradient(begin: bottomLeft, end: topRight, colors: [volumeRed, volumeAmber])`.
- *Bottom sheet:* `LinearGradient(begin: topCenter, end: bottomCenter, colors: [sheetNavy, sheetNavy.withOpacity(0.85)])` over a `BackdropFilter` blur of 24.

## 2. Typography

Bundle **Inter** (or Satoshi if you want closer SF-Display character). Do not use
`google_fonts` at runtime — bundle the `.ttf` so first paint has no network hop.

| Token | Size / Weight / Tracking | Used for |
| --- | --- | --- |
| `titleBar` | 20 / w600 / -0.2 | "Activity", "Expiratory Volume" |
| `cardLabel` | 13 / w500 / 0 | "Lung test", "Daily Smook", "Training" |
| `unitLabel` | 12 / w400 / 0.4 | "Liter", "CO2", "O" |
| `sectionLabel` | 14 / w500 / 0 | "Lung Capacity" |
| `tileNumber` | 34 / w600 / -0.5 | "234", "5.5" |
| `hint` | 13 / w400 / 0 | "Empty your lungs" |
| `button` | 15 / w600 / 0 | "Finish Test" |

The big readouts (**3.3**, **0.0**) are **not** text — they are painted glyphs.
See §4.

## 3. Spacing, radii, layout grid

- Base unit **4**. Page horizontal padding **20**.
- Radii: hero card **40**, tiles **28**, bottom sheet **32** (top corners only),
  pill button **24**, circular buttons **22** (44×44 tap target).
- Vertical rhythm on the Activity screen, top to bottom:
  `safeTop → 8 → appBar(44) → 24 → carousel(≈ 0.46×H) → 20 → "Lung Capacity" → 12 → pageDots → 24 → tile grid → safeBottom`.
- Tile grid: left column is one tall tile, right column is two stacked tiles.
  Column gap **12**, row gap **12**, left column flex 1, right column flex 1.

## 4. The dot-matrix system (the signature element)

Everything numeric and every "texture" in this design is a field of small circles.
Build one primitive and reuse it everywhere.

**`DotGlyphFont`** — a 7×9 bitmap per character for `0-9 . : -`. Each glyph is a
`List<bool>` of 63 cells. Store as compact `int` bitmasks.

**`DotMatrixText`** widget parameters:
- `value` (String), `cellSize` (dot diameter, 3–8 px), `cellGap`, `litColor`,
  `unlitColor` (`AppColors.dotOff`, drawn so the grid is faintly visible even
  when off — this is what gives the mock its texture), `glow` (double).

**Painting:** one `Canvas.drawPoints(PointMode.points, ...)` call per colour bucket
with a `Paint()..strokeCap = round..strokeWidth = cellSize`. For per-dot opacity or
scale (needed during morphs) switch to `drawRawAtlas` with a single 1×1 white
circle texture — one draw call for thousands of dots. Never one `drawCircle` per
dot in a loop for the large fields.

**Where it's used**
1. Hero readout "3.3" — `cellSize: 6`, glow on.
2. Test readout "0.0" — `cellSize: 7`, glow on.
3. The lung/dome cloud on the test screen — a masked dot field (see below).
4. The little dot cluster icons above "Empty your lungs" and in the carousel card.
5. The tick strip under "234" and the arc gauge under "5.5".

## 5. Component inventory

Each of these is a separate widget + painter, built and golden-tested in isolation.

| Component | Notes |
| --- | --- |
| `CircleIconButton` | 44×44, `surfaceHigh` fill, icon 18, press-scale to 0.92 |
| `HeroCarousel` | `PageView` with `viewportFraction: 0.72`, neighbours scaled to 0.86 and translated so ~24 px peeks each side |
| `LungTestCard` | Gradient + bloom + orbit particles + `DotMatrixText` + eye toggle |
| `PageDotsIndicator` | 5 dots, active one widens to a 12×4 pill |
| `StatTileTall` | "Daily Smook": label, big number + unit superscript, `TickStripPainter` at the bottom with one `acidYellow` tick |
| `ToggleTile` | "Training": custom spring toggle, card glow ramps with the on-state |
| `GaugeTile` | "Breath Volume": `DottedArcGaugePainter` + scattered dots |
| `LungDotField` | Test screen: dot grid clipped to a lung/dome `Path`, per-dot brightness from the fill level |
| `ParticleStream` | Falling dot rows under the readout during exhale |
| `TestSheet` | Blurred navy sheet: CO2 / hint / O2 readouts + `BreathSlider` |
| `BreathSlider` | Half-moon knob, `acidYellow` trail, target ring at the end |
| `PillButton` | "Finish Test" |
| `BreathingOrb` | Session player: layered radial gradient that scales with the phase |

## 6. Screen inventory (full app)

1. **Splash** — dot-matrix logo assembles from scattered dots.
2. **Onboarding** — 3 pages (value prop, profile: age/height/sex/smoking, mic
   permission priming with an honest "this is an estimate" line).
3. **Activity (Home)** — the first mock screen.
4. **Test flow** — Prepare → Ambient calibration (3 s) → Live test (second mock
   screen) → Result with delta vs. last test and predicted value.
5. **Session player** — pattern picker, then the breathing orb with phase text,
   ring progress, cycle counter, audio + haptic cues.
6. **History** — streak, sparkline of lung tests, session minutes calendar heatmap
   (all painted in the same dot idiom rather than a chart library).
7. **Settings** — units, haptics, sound, daily reminder, recalibrate, export, reset.

## 7. Accessibility

The design is aesthetically low-contrast in places; do not ship it that way blindly.

- Every dot-matrix readout gets a `Semantics(label: "3.3 liters")` — screen readers
  cannot read painted dots.
- `unitLabel` at 40% white on black is ~4.1:1 — acceptable for the 12 px secondary
  labels only because they are duplicated in semantics; bump to `textSecondary`
  wherever the label is the sole carrier of meaning.
- Honour `MediaQuery.disableAnimations` — the whole app must fall back to instant
  state changes (see ANIMATION_SPEC §7).
- Minimum tap target 44×44 including the small circular buttons.
