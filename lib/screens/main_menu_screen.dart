import 'package:flutter/material.dart';
import '../app_state.dart';
import '../ui/neon_widgets.dart';
import '../vfx/neon_palette.dart';
import 'song_select_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hz = AppState.instance.refresh.bucket();
    return SafeNeonScaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 36),
            const Text(
              'AETHER BEAT',
              style: TextStyle(
                color: NeonPalette.cyan,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                shadows: [
                  Shadow(color: NeonPalette.magenta, blurRadius: 18),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'NEON RHYTHM  ·  ${hz}Hz PANEL',
              style: const TextStyle(
                color: NeonPalette.muted,
                letterSpacing: 3,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            NeonMenuButton(
              label: 'PLAY',
              icon: Icons.play_arrow,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SongSelectScreen(practice: false),
                ),
              ),
            ),
            NeonMenuButton(
              label: 'SONGS',
              icon: Icons.library_music,
              accent: NeonPalette.magenta,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SongSelectScreen(practice: false),
                ),
              ),
            ),
            NeonMenuButton(
              label: 'PRACTICE',
              icon: Icons.fitness_center,
              accent: NeonPalette.violet,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SongSelectScreen(practice: true),
                ),
              ),
            ),
            NeonMenuButton(
              label: 'SETTINGS',
              icon: Icons.settings,
              accent: NeonPalette.amber,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            NeonMenuButton(
              label: 'PROFILE',
              icon: Icons.person_outline,
              accent: NeonPalette.lime,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
            const Spacer(),
            const Text(
              'AUDIO CLOCK TIMING  ·  OFFLINE',
              style: TextStyle(color: NeonPalette.muted, fontSize: 11, letterSpacing: 2),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
