// models/score_record.dart
//
// A single best-score entry. Stored as JSON inside SharedPreferences and
// loaded by [PreferencesStore] on app start. We track the smallest move
// count seen so far, with the matching elapsed-time tiebreaker.

class ScoreRecord {
  final int moves;
  final int seconds;
  final DateTime achievedOn;

  const ScoreRecord({
    required this.moves,
    required this.seconds,
    required this.achievedOn,
  });

  Map<String, dynamic> toJson() => {
        'moves': moves,
        'seconds': seconds,
        'achievedOn': achievedOn.toIso8601String(),
      };

  factory ScoreRecord.fromJson(Map<String, dynamic> data) => ScoreRecord(
        moves: data['moves'] as int,
        seconds: data['seconds'] as int,
        achievedOn: DateTime.parse(data['achievedOn'] as String),
      );

  /// "Better" means fewer moves; if moves tie, faster time wins.
  bool isBetterThan(ScoreRecord? other) {
    if (other == null) return true;
    if (moves != other.moves) return moves < other.moves;
    return seconds < other.seconds;
  }
}
