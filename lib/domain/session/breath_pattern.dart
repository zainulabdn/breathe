import 'package:flutter/foundation.dart';

enum PhaseType { inhale, holdIn, exhale, holdOut }

extension PhaseTypeLabel on PhaseType {
  String get label => switch (this) {
        PhaseType.inhale => 'Breathe in',
        PhaseType.holdIn => 'Hold',
        PhaseType.exhale => 'Breathe out',
        PhaseType.holdOut => 'Hold',
      };

  /// Where the orb sits during this phase: inhale rises, exhale falls, holds
  /// stay put at whichever end they follow.
  bool get isRising => this == PhaseType.inhale;
  bool get isFalling => this == PhaseType.exhale;
  bool get isHold => this == PhaseType.holdIn || this == PhaseType.holdOut;
}

@immutable
class PhaseSpec {
  const PhaseSpec(this.type, this.seconds);

  final PhaseType type;
  final double seconds;
}

@immutable
class BreathPattern {
  const BreathPattern({
    required this.id,
    required this.name,
    required this.description,
    required this.phases,
    required this.defaultCycles,
  });

  final String id;
  final String name;
  final String description;
  final List<PhaseSpec> phases;
  final int defaultCycles;

  /// Zero-length phases are kept in [phases] so a pattern reads as its familiar
  /// four numbers (4-7-8-0), but they are skipped when running.
  List<PhaseSpec> get activePhases =>
      phases.where((p) => p.seconds > 0).toList(growable: false);

  double get cycleSeconds =>
      activePhases.fold(0.0, (sum, p) => sum + p.seconds);

  double totalSeconds(int cycles) => cycleSeconds * cycles;

  /// Short, rapid breaths risk hypocapnia and fainting.
  bool get hasRapidBreathing => activePhases.any(
        (p) => !p.type.isHold && p.seconds < 3,
      );

  /// Long breath-holds carry the same risk by a different route.
  bool get hasLongHold => activePhases.any(
        (p) => p.type.isHold && p.seconds > 30,
      );

  /// Gates the safety interstitial. See docs/BREATH_ENGINE.md §7 — this is not
  /// legal boilerplate, people genuinely do faint doing these.
  bool get needsSafetyNotice => hasRapidBreathing || hasLongHold;

  String get summary => phases
      .map((p) => p.seconds == p.seconds.roundToDouble()
          ? p.seconds.round().toString()
          : p.seconds.toStringAsFixed(1))
      .join('-');

  static const coherent = BreathPattern(
    id: 'coherent',
    name: 'Coherent',
    description: 'Even, unhurried breathing. The best place to start.',
    phases: [
      PhaseSpec(PhaseType.inhale, 5.5),
      PhaseSpec(PhaseType.holdIn, 0),
      PhaseSpec(PhaseType.exhale, 5.5),
      PhaseSpec(PhaseType.holdOut, 0),
    ],
    defaultCycles: 27, // ~5 minutes
  );

  static const box = BreathPattern(
    id: 'box',
    name: 'Box',
    description: 'Equal counts on all four sides. Steadying, good for focus.',
    phases: [
      PhaseSpec(PhaseType.inhale, 4),
      PhaseSpec(PhaseType.holdIn, 4),
      PhaseSpec(PhaseType.exhale, 4),
      PhaseSpec(PhaseType.holdOut, 4),
    ],
    defaultCycles: 19, // ~5 minutes
  );

  static const relax478 = BreathPattern(
    id: 'relax_478',
    name: 'Relax 4-7-8',
    description: 'A long exhale to wind down. Useful before sleep.',
    phases: [
      PhaseSpec(PhaseType.inhale, 4),
      PhaseSpec(PhaseType.holdIn, 7),
      PhaseSpec(PhaseType.exhale, 8),
      PhaseSpec(PhaseType.holdOut, 0),
    ],
    defaultCycles: 8,
  );

  static const energize = BreathPattern(
    id: 'energize',
    name: 'Energize',
    description: 'Quick, active breaths. Sit down before you start.',
    phases: [
      PhaseSpec(PhaseType.inhale, 2),
      PhaseSpec(PhaseType.holdIn, 0),
      PhaseSpec(PhaseType.exhale, 2),
      PhaseSpec(PhaseType.holdOut, 0),
    ],
    defaultCycles: 30,
  );

  static const List<BreathPattern> presets = [
    coherent,
    box,
    relax478,
    energize,
  ];
}
