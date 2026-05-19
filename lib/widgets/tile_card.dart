// widgets/tile_card.dart
//
// Visual representation of a single Tile on the board, with a 3D flip
// animation between its back face (a tinted "musical-note" tile) and its
// front face (the instrument illustration).
//
// The widget is reactive: it watches the Tile.status field passed in by
// the parent. When status changes between hidden/revealed/locked, the
// animation controller is told to play forward or rewind.

import 'dart:math';
import 'package:flutter/material.dart';

import '../models/tile.dart';
import '../theme/app_palette.dart';

class TileCard extends StatefulWidget {
  final Tile tile;
  final VoidCallback onTap;

  const TileCard({super.key, required this.tile, required this.onTap});

  @override
  State<TileCard> createState() => _TileCardState();
}

class _TileCardState extends State<TileCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;
  late final Animation<double> _flipAngle;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    // 0..π — half rotation around the Y axis.
    _flipAngle = Tween<double>(begin: 0.0, end: pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutCubic),
    );

    // Defensive: if a Tile starts already showing its face (e.g. after a
    // hot reload during dev), set the controller to its end-state.
    if (widget.tile.showFace) {
      _flipController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant TileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Drive the animation toward the new status of the underlying tile.
    if (widget.tile.showFace) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _flipAngle,
        builder: (context, _) {
          final angle = _flipAngle.value;
          // Once past the midpoint we should render the front, mirrored to
          // keep the artwork right-side-up after the flip.
          final pastHalfway = angle > pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012) // perspective coefficient
              ..rotateY(angle),
            child: pastHalfway
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _renderFrontFace(),
                  )
                : _renderBackFace(),
          );
        },
      ),
    );
  }

  // ---- back face ---------------------------------------------------------

  /// Tinted "musical-note" face shown when the tile is hidden.
  Widget _renderBackFace() {
    final tint = widget.tile.backTint;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint, _darken(tint, 0.18)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: tint.withOpacity(0.45),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 42,
          color: Colors.white.withOpacity(0.92),
          shadows: const [
            Shadow(
              color: Colors.black26,
              offset: Offset(1.5, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }

  // ---- front face --------------------------------------------------------

  /// White tile with the instrument illustration. Locked tiles get a brass
  /// ring around them so cleared pairs stand out from in-progress flips.
  Widget _renderFrontFace() {
    final isCleared = widget.tile.isLocked;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCleared ? AppPalette.brass : Colors.grey.shade300,
          width: isCleared ? 3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            widget.tile.artworkPath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _renderPlaceholder(),
          ),
        ),
      ),
    );
  }

  /// Fallback shown when an asset is missing — keeps the game playable.
  Widget _renderPlaceholder() {
    return Container(
      color: widget.tile.backTint.withOpacity(0.15),
      child: Center(
        child: Icon(
          Icons.queue_music_rounded,
          size: 36,
          color: widget.tile.backTint,
        ),
      ),
    );
  }

  // ---- color util --------------------------------------------------------

  /// Returns [base] darkened by [amount] in [0..1].
  Color _darken(Color base, double amount) {
    final hsl = HSLColor.fromColor(base);
    final adjusted = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return adjusted.toColor();
  }
}
