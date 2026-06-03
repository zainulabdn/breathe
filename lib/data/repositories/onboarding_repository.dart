import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile_draft.dart';

/// Onboarding completion and the profile it collects.
///
/// Backed by `shared_preferences` rather than Hive: this is a completion flag
/// and four scalars read once at launch, not a queryable record set. Hive still
/// owns tests and sessions (docs/ARCHITECTURE.md §3). As with every repository
/// here, callers see only this interface, so the backing store can change
/// without touching a screen.
class OnboardingRepository {
  OnboardingRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _kCompleted = 'onboarding.completed';
  static const _kBirthYear = 'profile.birthYear';
  static const _kHeightCm = 'profile.heightCm';
  static const _kSex = 'profile.sex';
  static const _kCigarettes = 'profile.cigarettesPerWeek';

  bool get isComplete => _prefs.getBool(_kCompleted) ?? false;

  ProfileDraft readProfile() => ProfileDraft(
        birthYear: _prefs.getInt(_kBirthYear),
        heightCm: _prefs.getInt(_kHeightCm),
        sex: switch (_prefs.getString(_kSex)) {
          'female' => Sex.female,
          'male' => Sex.male,
          'preferNotToSay' => Sex.preferNotToSay,
          _ => null,
        },
        cigarettesPerWeek: _prefs.getInt(_kCigarettes) ?? 0,
      );

  Future<void> saveProfile(ProfileDraft profile) async {
    if (profile.birthYear != null) {
      await _prefs.setInt(_kBirthYear, profile.birthYear!);
    }
    if (profile.heightCm != null) {
      await _prefs.setInt(_kHeightCm, profile.heightCm!);
    }
    if (profile.sex != null) {
      await _prefs.setString(_kSex, profile.sex!.name);
    }
    await _prefs.setInt(_kCigarettes, profile.cigarettesPerWeek);
  }

  Future<void> markComplete() => _prefs.setBool(_kCompleted, true);

  /// Exposed for the Phase 6 settings screen and for testing the flow.
  Future<void> reset() async {
    await _prefs.remove(_kCompleted);
  }
}

/// Overridden in `main()` once SharedPreferences has loaded.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(ref.watch(sharedPreferencesProvider)),
);
