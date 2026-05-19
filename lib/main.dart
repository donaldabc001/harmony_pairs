// main.dart
//
// Harmony Pairs — a music-themed memory pair-matching game.
//
// Course   : COMP-5450-SA Mobile Programming (Spring 2026)
// Author   : Chengbiao Qin (Student ID: 1269476)
// School   : Lakehead University, Department of Computer Science
// Mentor   : Dr. Sabah Mohammed

import 'package:flutter/material.dart';
import 'screens/launch_screen.dart';
import 'services/preferences_store.dart';
import 'theme/app_palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore previously saved preferences (dark mode, sound on/off, best
  // scores) before the first frame is drawn.
  await PreferencesStore.instance.initialize();

  runApp(const HarmonyPairsRoot());
}

/// Top-level widget. Listens to the preferences store so light/dark theme
/// swaps refresh the whole UI when the user toggles them from the settings.
class HarmonyPairsRoot extends StatefulWidget {
  const HarmonyPairsRoot({super.key});

  @override
  State<HarmonyPairsRoot> createState() => _HarmonyPairsRootState();
}

class _HarmonyPairsRootState extends State<HarmonyPairsRoot> {
  @override
  void initState() {
    super.initState();
    // Repaint when any preference changes (theme, sound flag, best scores).
    PreferencesStore.instance.addListener(_onPrefsChanged);
  }

  @override
  void dispose() {
    PreferencesStore.instance.removeListener(_onPrefsChanged);
    super.dispose();
  }

  void _onPrefsChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isDark = PreferencesStore.instance.isDarkMode;

    return MaterialApp(
      title: 'Harmony Pairs',
      debugShowCheckedModeBanner: false,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: const LaunchScreen(),
    );
  }

  ThemeData _buildLightTheme() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppPalette.lightBackdrop,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppPalette.navy,
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      );

  ThemeData _buildDarkTheme() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppPalette.darkBackdrop,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppPalette.navy,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      );
}
