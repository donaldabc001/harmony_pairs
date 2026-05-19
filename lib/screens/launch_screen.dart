// screens/launch_screen.dart
//
// First screen the user sees after opening the app.
//
// Layout (top → bottom):
//   1. Settings row in the top-right (dark mode toggle + sound toggle)
//   2. App logo + title block
//   3. Stage picker (3 selectable cards: Rookie / Maestro / Virtuoso)
//   4. Best-score readout for the currently picked stage
//   5. "Begin" button that pushes [BoardScreen]

import 'package:flutter/material.dart';

import '../models/stage.dart';
import '../services/preferences_store.dart';
import '../theme/app_palette.dart';
import 'board_screen.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  /// Stage the user is currently considering (default: Maestro).
  Stage _pickedStage = Stage.maestro;

  @override
  void initState() {
    super.initState();
    PreferencesStore.instance.addListener(_onPrefsChanged);
  }

  @override
  void dispose() {
    PreferencesStore.instance.removeListener(_onPrefsChanged);
    super.dispose();
  }

  void _onPrefsChanged() => setState(() {});

  // --- UI building blocks ---------------------------------------------------

  Color get _textColor =>
      PreferencesStore.instance.isDarkMode ? AppPalette.textDark : AppPalette.textLight;

  Color get _surface =>
      PreferencesStore.instance.isDarkMode ? AppPalette.surfaceDark : AppPalette.surfaceLight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSettingsRow(),
              const SizedBox(height: 18),
              _buildHero(),
              const SizedBox(height: 32),
              _buildSectionTitle('Choose your stage'),
              const SizedBox(height: 12),
              ...Stage.all.map(_buildStageCard),
              const SizedBox(height: 18),
              _buildBestScoreCard(),
              const SizedBox(height: 28),
              _buildBeginButton(),
              const SizedBox(height: 16),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  /// Top row: dark-mode + sound-effects toggles, right-aligned.
  Widget _buildSettingsRow() {
    final prefs = PreferencesStore.instance;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          tooltip: prefs.isSoundOn ? 'Mute sound' : 'Enable sound',
          icon: Icon(
            prefs.isSoundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            color: AppPalette.navy,
          ),
          onPressed: () => prefs.toggleSound(),
        ),
        IconButton(
          tooltip: prefs.isDarkMode ? 'Switch to light theme' : 'Switch to dark theme',
          icon: Icon(
            prefs.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: prefs.isDarkMode ? AppPalette.brass : AppPalette.navy,
          ),
          onPressed: () => prefs.toggleDarkMode(),
        ),
      ],
    );
  }

  /// Logo emblem + title + subtitle.
  Widget _buildHero() {
    return Column(
      children: [
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppPalette.navy, AppPalette.navyLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppPalette.navy.withOpacity(0.35),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.music_note_rounded,
            size: 72,
            color: AppPalette.brass,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Harmony Pairs',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: _textColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'A music-themed pair-matching puzzle',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: _textColor.withOpacity(0.65),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String text) => Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: _textColor,
        ),
      );

  Widget _buildStageCard(Stage stage) {
    final picked = stage.label == _pickedStage.label;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: GestureDetector(
        onTap: () => setState(() => _pickedStage = stage),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: picked ? AppPalette.navy : _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: picked ? AppPalette.navy : Colors.grey.shade300,
              width: 2,
            ),
            boxShadow: picked
                ? [
                    BoxShadow(
                      color: AppPalette.navy.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                picked ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: picked ? AppPalette.brass : Colors.grey.shade500,
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage.label,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: picked ? Colors.white : _textColor,
                      ),
                    ),
                    Text(
                      stage.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: picked
                            ? Colors.white.withOpacity(0.85)
                            : _textColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows the best moves/time recorded for the currently picked stage.
  Widget _buildBestScoreCard() {
    final best = PreferencesStore.instance.readBestScore(_pickedStage.storageKey);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.brass.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.brass.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: AppPalette.brass, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: best == null
                ? Text(
                    'No personal best yet — set one!',
                    style: TextStyle(color: _textColor.withOpacity(0.75)),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Best — ${_pickedStage.label}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${best.moves} moves • ${_formatSeconds(best.seconds)}',
                        style: TextStyle(
                          color: _textColor.withOpacity(0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeginButton() {
    return SizedBox(
      height: 58,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BoardScreen(stage: _pickedStage)),
          );
        },
        icon: const Icon(Icons.play_arrow_rounded, size: 28),
        label: const Text(
          'Begin',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1.0),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.navy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
        ),
      ),
    );
  }

  Widget _buildFooter() => Text(
        'Chengbiao Qin • COMP-5450 Mobile Programming • Lakehead University',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10.5, color: _textColor.withOpacity(0.5)),
      );

  String _formatSeconds(int total) {
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
