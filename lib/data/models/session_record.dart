import 'package:flutter/foundation.dart';

@immutable
class SessionRecord {
  const SessionRecord({
    required this.id,
    required this.patternId,
    required this.startedAt,
    required this.durationSec,
    required this.completedCycles,
    required this.finished,
  });

  final String id;
  final String patternId;
  final DateTime startedAt;
  final int durationSec;
  final int completedCycles;

  /// False when the user stopped early. Kept rather than discarded — a
  /// two-minute session someone actually did is worth more in the history than
  /// a gap, and the streak should count it.
  final bool finished;

  Map<String, dynamic> toJson() => {
        'id': id,
        'patternId': patternId,
        'startedAt': startedAt.toIso8601String(),
        'durationSec': durationSec,
        'completedCycles': completedCycles,
        'finished': finished,
      };

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
        id: json['id'] as String,
        patternId: json['patternId'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        durationSec: json['durationSec'] as int,
        completedCycles: json['completedCycles'] as int,
        finished: json['finished'] as bool? ?? false,
      );
}
