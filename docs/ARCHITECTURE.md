# Architecture

Deliberately the same shape as Orix: Riverpod for state, Hive behind repositories,
feature-first folders. Keeping the two projects structurally identical means
anything you learn in one transfers.

## 1. Folder layout

```
lib/
  main.dart
  app.dart                        # MaterialApp.router, theme, MotionScale
  core/
    theme/       app_colors.dart  app_text.dart  app_theme.dart  motion.dart
    router/      app_router.dart  transitions.dart
    utils/       smoothing.dart   seeded_noise.dart  formatters.dart
    widgets/     circle_icon_button.dart  pill_button.dart  dot_ring_loader.dart
  dots/                           # the dot-matrix primitive — used everywhere
    dot_glyph_font.dart           # 7x9 bitmasks for 0-9 . : -
    dot_matrix_text.dart
    dot_field.dart                # path-masked dot cloud
    painters/    glyph_painter.dart  field_painter.dart  atlas_batch.dart
  data/
    models/      user_profile.dart  lung_test.dart  session_record.dart  pattern.dart
    sources/     hive_boxes.dart  mic_source.dart
    repositories/ profile_repository.dart  test_repository.dart  session_repository.dart
  domain/
    breath/      breath_analyzer.dart  volume_estimator.dart  calibration.dart
    session/     pattern_engine.dart  predicted_values.dart
  features/
    splash/      onboarding/      activity/
    lung_test/   session/         history/       settings/
```

Each feature folder is `view/`, `widgets/`, `controller.dart` (its Riverpod
notifier), and `state.dart` (its freezed state class).

## 2. State management

**Riverpod 3.x** (pub resolved `riverpod 3.4.3` / `flutter_riverpod` at scaffold
time on 2026-09-05 — the plan originally assumed 2.x). Three tiers:

- **Repository providers** — `Provider`, wrap Hive boxes, the only thing that
  touches storage. Swappable for a backend later without any UI change.
- **Feature controllers** — `AsyncNotifier` / `Notifier` per screen. Own the
  screen's state class, call repositories, never touch `BuildContext`.
- **Streaming providers** — the mic pipeline is a `StreamProvider<BreathFrame>`.
  Widgets that animate off it must `ref.listen`, not `ref.watch`, and push the
  value into an `AnimationController` / `ValueNotifier`. **Watching a 50 Hz stream
  in a widget rebuilds the tree 50 times a second and will tank the frame budget.**
  This is the single most important performance rule in the app.

## 3. Data models (Hive, via `hive_ce`)

```dart
@HiveType(typeId: 0)
class UserProfile {
  String? name;
  int? birthYear;      // for predicted-value equations
  int? heightCm;
  Sex? sex;
  int cigarettesPerWeek;
  int dailyGoalMinutes;
  double? calibrationK; // mic → litres scale factor, per user (BREATH_ENGINE §5)
  DateTime? calibratedAt;
}

@HiveType(typeId: 1)
class LungTest {
  String id;
  DateTime takenAt;
  TestKind kind;        // vitalCapacity | expiratoryVolume | peakFlow
  double liters;
  double confidence;    // 0–1, from SNR and waveform quality
  double ambientDb;     // noise floor at test time
  double? percentPredicted;
}

@HiveType(typeId: 2)
class SessionRecord {
  String id;
  String patternId;
  DateTime startedAt;
  int durationSec;
  int completedCycles;
  double adherence;     // 0–1, how well pacing was followed (if mic was on)
}

@HiveType(typeId: 3)
class BreathPattern {
  String id;
  String name;          // Box, 4-7-8, Coherent, Energize
  List<PhaseSpec> phases; // (PhaseType, seconds)
  int defaultCycles;
  bool isCustom;
}
```

Boxes: `profile`, `tests`, `sessions`, `patterns`, `prefs`. Built-in patterns are
seeded on first launch and marked `isCustom: false` so they survive a reset.

## 4. Navigation

`go_router`. Routes: `/` (splash) `/onboarding` `/home` `/test` `/test/result/:id`
`/session/:patternId` `/history` `/settings`. Custom `pageBuilder`s for the
transitions in ANIMATION_SPEC §6.3; the Hero for the card→test flight works
across `go_router` pages without extra work.

## 5. Packages

| Package | Why |
| --- | --- |
| `flutter_riverpod` (3.x) + `riverpod_annotation` / `riverpod_generator` | state |
| `go_router` | routing |
| `hive_ce`, `hive_ce_flutter` | storage (community fork; classic `hive` is stale) |
| `freezed`, `json_serializable`, `build_runner` | models |
| `record` (v5+) | **PCM stream** from the mic — needs `startStream`, not just file recording |
| `permission_handler` | mic permission with a proper rationale flow |
| `flutter_animate` | the declarative micro-animations only (entrances, fades) |
| `wakelock_plus` | keep the screen on during tests and sessions |
| `flutter_local_notifications` + `timezone` | daily reminder |
| `audioplayers` or `flutter_soloud` | session cues — prefer `soloud` if latency matters |
| `share_plus`, `csv` | export history |

Pin exact versions in `pubspec.yaml` at scaffold time and check each against
pub.dev then — versions in this doc would be stale guesses.

**No chart library.** `fl_chart` would look foreign next to the dot idiom; the
history visuals are the same `DotField` primitive.

## 6. Platform config

**iOS** — `NSMicrophoneUsageDescription` in `Info.plist` with an honest string:
"Breathe listens to your exhale to estimate lung capacity. Audio is processed on
your device and never recorded or uploaded." Set the audio session category to
`playAndRecord` with `defaultToSpeaker` so cues are audible while the mic is live.

**Android** — `RECORD_AUDIO` permission, `minSdk 23` (`record` requirement),
`compileSdk 35`, JDK 17 (already your machine default for Flutter work).
Request the permission at the *Prepare* step of the test flow, never at launch.

**Both** — audio must be processed frame-by-frame in memory and discarded. Nothing
is written to disk. Say so in the privacy policy and mean it.

## 7. Testing

- **Golden tests** for every painter at 3 sizes — this is how you keep the dot
  geometry from silently drifting. Goldens for `DotMatrixText` covering all 13
  glyphs are the highest-value tests in the project.
- **Unit tests** for `VolumeEstimator`, `Calibration`, `PatternEngine`, and the
  smoothers, with recorded WAV fixtures for the analyzer so mic behaviour is
  reproducible without a device.
- **Widget tests** for controller state machines (test flow, session flow).
- Skip integration tests until the UI stops moving.
