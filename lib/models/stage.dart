// models/stage.dart
//
// Difficulty / "stage" descriptor. Each Stage maps to a grid size and a
// human-readable label shown on the launch screen. The board derives the
// number of pairs from `cols × rows` automatically.

class Stage {
  final String label;
  final String description;
  final int cols;
  final int rows;
  final String storageKey; // used to namespace best-score persistence

  const Stage({
    required this.label,
    required this.description,
    required this.cols,
    required this.rows,
    required this.storageKey,
  });

  int get totalTiles => cols * rows;
  int get totalPairs => totalTiles ~/ 2;

  /// Three preset stages — note the grid sizes are intentionally different
  /// from the assignment's screenshot to make the build feel original.
  static const Stage rookie = Stage(
    label: 'Rookie',
    description: '3 × 4 board • 6 pairs',
    cols: 3,
    rows: 4,
    storageKey: 'best_rookie',
  );

  static const Stage maestro = Stage(
    label: 'Maestro',
    description: '4 × 4 board • 8 pairs',
    cols: 4,
    rows: 4,
    storageKey: 'best_maestro',
  );

  static const Stage virtuoso = Stage(
    label: 'Virtuoso',
    description: '4 × 6 board • 12 pairs',
    cols: 4,
    rows: 6,
    storageKey: 'best_virtuoso',
  );

  static const List<Stage> all = [rookie, maestro, virtuoso];
}
