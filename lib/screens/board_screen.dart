// screens/board_screen.dart
//
// Active gameplay screen — owns the board state, runs the match/mismatch
// resolution loop, drives the timer, and displays the victory dialog.
//
// State machine for a player turn:
//   1. Player taps a hidden tile  →  it transitions to "revealed".
//   2. Player taps a second hidden tile.
//   3. If both `groupKey`s agree   →  both lock, score updates, may win.
//      Otherwise                  →  board freezes briefly, both flip back.

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/score_record.dart';
import '../models/stage.dart';
import '../models/tile.dart';
import '../services/preferences_store.dart';
import '../services/sound_engine.dart';
import '../theme/app_palette.dart';
import '../widgets/tile_card.dart';

class BoardScreen extends StatefulWidget {
  final Stage stage;
  const BoardScreen({super.key, required this.stage});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  // ---- state -------------------------------------------------------------

  /// Master list of tiles displayed in row-major order in the GridView.
  List<Tile> _board = [];

  /// Indices of tiles currently in `revealed` status awaiting comparison.
  /// Never holds more than two entries.
  final List<int> _awaitingPair = [];

  /// Aggregate counters surfaced in the HUD.
  int _moveCounter = 0;
  int _lockedPairCount = 0;
  int _elapsedSeconds = 0;
  Timer? _wallClock;

  /// While true, the board ignores taps. We use this during the brief
  /// "flip back" delay after a mismatch so the player can't queue up a
  /// third reveal mid-resolution.
  bool _boardLocked = false;

  // ---- instrument pool ---------------------------------------------------
  //
  // Listed in the order they ship in assets/. The board takes the first N
  // (after shuffling) where N == required pair count.
  static const List<String> _instrumentArt = [
    'assets/images/guitar.png',
    'assets/images/piano.png',
    'assets/images/drum.png',
    'assets/images/violin.png',
    'assets/images/saxophone.png',
    'assets/images/trumpet.png',
    'assets/images/microphone.png',
    'assets/images/harmonica.png',
    'assets/images/flute.png',
    'assets/images/headphones.png',
    'assets/images/vinyl.png',
    'assets/images/note.png',
  ];

  // ---- lifecycle ---------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _assembleBoard();
    _startWallClock();
  }

  @override
  void dispose() {
    _wallClock?.cancel();
    super.dispose();
  }

  // ---- board setup -------------------------------------------------------

  /// Creates a fresh shuffled deck for the current stage and resets all
  /// counters. Called on first build and whenever the player restarts.
  void _assembleBoard() {
    final pairCount = widget.stage.totalPairs;

    // Shuffle copies of the source pools so we don't mutate the constants.
    final artworkRandomized = List<String>.from(_instrumentArt)..shuffle();
    final tintsRandomized = List<Color>.from(AppPalette.tileTints)..shuffle();
    final selectedArtwork = artworkRandomized.take(pairCount).toList();

    // Build the deck: two Tile instances per chosen instrument.
    final deck = <Tile>[];
    for (var i = 0; i < pairCount; i++) {
      final tint = tintsRandomized[i % tintsRandomized.length];
      // pair member #1
      deck.add(Tile(groupKey: i, artworkPath: selectedArtwork[i], backTint: tint));
      // pair member #2
      deck.add(Tile(groupKey: i, artworkPath: selectedArtwork[i], backTint: tint));
    }

    // Randomize seat positions.
    deck.shuffle(Random());

    setState(() {
      _board = deck;
      _awaitingPair.clear();
      _moveCounter = 0;
      _lockedPairCount = 0;
      _elapsedSeconds = 0;
      _boardLocked = false;
    });
  }

  void _startWallClock() {
    _wallClock?.cancel();
    _wallClock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  // ---- tap handling ------------------------------------------------------

  /// Handler bound to every tile in the grid. The Tile UI calls this on tap.
  void _handleTileTap(int index) {
    if (_boardLocked) return;
    final tile = _board[index];
    if (tile.isRevealed || tile.isLocked) return;
    if (_awaitingPair.length >= 2) return;

    SoundEngine.instance.flip();

    setState(() {
      tile.status = TileStatus.revealed;
      _awaitingPair.add(index);
    });

    // Two cards are now face-up → resolve the turn.
    if (_awaitingPair.length == 2) {
      _moveCounter++;
      _resolveTurn();
    }
  }

  void _resolveTurn() {
    final firstIdx = _awaitingPair[0];
    final secondIdx = _awaitingPair[1];

    final isPair = _board[firstIdx].groupKey == _board[secondIdx].groupKey;

    if (isPair) {
      // Match — keep both face-up forever.
      SoundEngine.instance.match();
      setState(() {
        _board[firstIdx].status = TileStatus.locked;
        _board[secondIdx].status = TileStatus.locked;
        _awaitingPair.clear();
        _lockedPairCount++;
      });

      if (_lockedPairCount == widget.stage.totalPairs) {
        _wallClock?.cancel();
        Future.delayed(const Duration(milliseconds: 450), _onBoardCleared);
      }
    } else {
      // Mismatch — give the player a beat to memorize, then flip both back.
      SoundEngine.instance.mismatch();
      _boardLocked = true;
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() {
          _board[firstIdx].status = TileStatus.hidden;
          _board[secondIdx].status = TileStatus.hidden;
          _awaitingPair.clear();
          _boardLocked = false;
        });
      });
    }
  }

  // ---- victory ---------------------------------------------------------

  Future<void> _onBoardCleared() async {
    SoundEngine.instance.victory();

    // Try to update the persistent best-score record. We capture whether a
    // new record was set so we can celebrate appropriately in the dialog.
    final attempt = ScoreRecord(
      moves: _moveCounter,
      seconds: _elapsedSeconds,
      achievedOn: DateTime.now(),
    );
    final isNewBest = await PreferencesStore.instance
        .submitScore(widget.stage.storageKey, attempt);

    if (!mounted) return;
    _showVictoryDialog(isNewBest);
  }

  void _showVictoryDialog(bool isNewBest) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Icon(
              isNewBest ? Icons.emoji_events_rounded : Icons.celebration_rounded,
              color: AppPalette.brass,
              size: 30,
            ),
            const SizedBox(width: 10),
            Text(isNewBest ? 'New Record!' : 'Bravo!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isNewBest
                  ? 'You set a new personal best on ${widget.stage.label}.'
                  : 'All pairs matched. Great memory!',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 14),
            _statRow(Icons.touch_app_rounded, 'Moves', '$_moveCounter'),
            _statRow(Icons.timer_outlined, 'Time', _formatTime(_elapsedSeconds)),
            _statRow(Icons.star_rounded, 'Stage', widget.stage.label),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // back to launch screen
            },
            child: const Text('Back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _assembleBoard();
              _startWallClock();
            },
            child: const Text('Replay'),
          ),
        ],
      ),
    );
  }

  Widget _statRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppPalette.navy),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }

  String _formatTime(int total) {
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ---- build -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = PreferencesStore.instance.isDarkMode;
    final fg = isDark ? AppPalette.textDark : AppPalette.textLight;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'Harmony Pairs',
              style: TextStyle(color: fg, fontSize: 19, fontWeight: FontWeight.w700),
            ),
            Text(
              widget.stage.label,
              style: TextStyle(color: fg.withOpacity(0.6), fontSize: 11),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // Moves badge — brass accent, matches the brass-on-navy palette.
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppPalette.brass,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 5),
                  Text(
                    '$_moveCounter',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // HUD: time + pair progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _hudChip(Icons.timer_outlined, _formatTime(_elapsedSeconds), 'Elapsed'),
                _hudChip(Icons.style_rounded,
                    '$_lockedPairCount / ${widget.stage.totalPairs}', 'Pairs'),
              ],
            ),
          ),

          // The actual grid.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: widget.stage.cols,
                  childAspectRatio: 0.82,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _board.length,
                itemBuilder: (context, idx) => TileCard(
                  tile: _board[idx],
                  onTap: () => _handleTileTap(idx),
                ),
              ),
            ),
          ),

          // Bottom action — "Shuffle" (same effect as restart, friendlier wording).
          Padding(
            padding: const EdgeInsets.only(bottom: 14, top: 4),
            child: TextButton.icon(
              onPressed: () {
                _assembleBoard();
                _startWallClock();
              },
              icon: const Icon(Icons.shuffle_rounded, color: AppPalette.navy),
              label: const Text(
                'Shuffle',
                style: TextStyle(
                  color: AppPalette.navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hudChip(IconData icon, String value, String label) {
    final isDark = PreferencesStore.instance.isDarkMode;
    final fg = isDark ? AppPalette.textDark : AppPalette.textLight;
    return Row(
      children: [
        Icon(icon, color: AppPalette.navy, size: 22),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: fg,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: fg.withOpacity(0.55), fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}
