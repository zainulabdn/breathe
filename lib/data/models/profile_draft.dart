import 'package:flutter/foundation.dart';

enum Sex { female, male, preferNotToSay }

/// What onboarding collects.
///
/// Age, height and sex are not vanity fields — they feed the predicted vital
/// capacity that the mic calibration is anchored to (docs/BREATH_ENGINE.md §5).
/// Without them there is no baseline to scale the estimate against, which is
/// why the profile step comes before the microphone step.
@immutable
class ProfileDraft {
  const ProfileDraft({
    this.birthYear,
    this.heightCm,
    this.sex,
    this.cigarettesPerWeek = 0,
  });

  final int? birthYear;
  final int? heightCm;
  final Sex? sex;
  final int cigarettesPerWeek;

  /// Enough to compute a predicted value.
  bool get isUsable => birthYear != null && heightCm != null && sex != null;

  int? ageAt(DateTime now) => birthYear == null ? null : now.year - birthYear!;

  ProfileDraft copyWith({
    int? birthYear,
    int? heightCm,
    Sex? sex,
    int? cigarettesPerWeek,
  }) {
    return ProfileDraft(
      birthYear: birthYear ?? this.birthYear,
      heightCm: heightCm ?? this.heightCm,
      sex: sex ?? this.sex,
      cigarettesPerWeek: cigarettesPerWeek ?? this.cigarettesPerWeek,
    );
  }
}
