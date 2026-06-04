import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_record.dart';
import 'onboarding_repository.dart';

/// Completed breathing sessions.
///
/// Backed by a JSON list in `shared_preferences` for now. This is explicitly a
/// placeholder — Phase 6 swaps it for Hive (docs/ARCHITECTURE.md §3), which is
/// mechanical precisely because nothing outside this class knows how records
/// are stored. Fine at the scale of one record per session; do not start
/// querying or paginating against it.
class SessionRepository {
  SessionRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'sessions.records';

  List<SessionRecord> readAll() {
    final raw = _prefs.getStringList(_key) ?? const [];
    final records = <SessionRecord>[];
    for (final entry in raw) {
      try {
        records.add(
          SessionRecord.fromJson(jsonDecode(entry) as Map<String, dynamic>),
        );
      } on FormatException {
        // A malformed entry should cost the user one row of history, not the
        // whole screen.
        continue;
      }
    }
    records.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return records;
  }

  Future<void> add(SessionRecord record) async {
    final raw = _prefs.getStringList(_key) ?? <String>[];
    raw.add(jsonEncode(record.toJson()));
    await _prefs.setStringList(_key, raw);
  }

  Future<void> clear() => _prefs.remove(_key);

  /// Consecutive days ending today (or yesterday, so a streak is not lost
  /// before the day is over).
  int currentStreak({DateTime? now}) {
    final records = readAll();
    if (records.isEmpty) return 0;

    final today = _dayOf(now ?? DateTime.now());
    final days = records.map((r) => _dayOf(r.startedAt)).toSet();

    var cursor = today;
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }

    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static DateTime _dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(ref.watch(sharedPreferencesProvider)),
);
