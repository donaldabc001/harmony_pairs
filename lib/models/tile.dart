// models/tile.dart
//
// Plain data object representing a single tile (face-down/face-up card) on
// the board. The board owns a List<Tile> and mutates the boolean flags as
// the player taps tiles; the UI rebuilds from that state.

import 'package:flutter/material.dart';

/// Lifecycle states a tile can be in during play.
enum TileStatus {
  hidden,   // face-down, the player has not flipped it
  revealed, // face-up, awaiting comparison with another revealed tile
  locked,   // face-up and confirmed matched (stays this way until restart)
}

/// One tile on the board.
///
/// Pairs share the same [groupKey] and the same [artworkPath]. The board
/// builds two Tile instances per chosen instrument, then shuffles the list
/// to randomize positions.
class Tile {
  /// Identifies which pair this tile belongs to. Two tiles match iff their
  /// `groupKey` values are equal.
  final int groupKey;

  /// Asset path to the instrument illustration shown on the face.
  final String artworkPath;

  /// Tint shown on the back face of this tile.
  final Color backTint;

  /// Current lifecycle status. Mutated by the board controller.
  TileStatus status;

  Tile({
    required this.groupKey,
    required this.artworkPath,
    required this.backTint,
    this.status = TileStatus.hidden,
  });

  bool get isHidden   => status == TileStatus.hidden;
  bool get isRevealed => status == TileStatus.revealed;
  bool get isLocked   => status == TileStatus.locked;

  /// True iff the tile should display its face (revealed or locked).
  bool get showFace => status != TileStatus.hidden;
}
