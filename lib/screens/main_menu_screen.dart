import 'package:flutter/material.dart';
import '../app_state.dart';
import '../ui/neon_widgets.dart';
import '../vfx/neon_palette.dart';
import 'song_select_screen.dart';
import 'import_song_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hz = AppState.instance.refresh.bucket();
    return SafeNeonScaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const SizedBox(height: 48),
            const Text(
              'AETHER BEAT',
              style: TextStyle(
                color: NeonPalette.text,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: 3.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'TAP THE TILES  ·  ${hz}Hz',
              style: const TextStyle(
                color: NeonPalette.muted,
                letterSpacing: 2,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            NeonMenuButton(
              label: 'PLAY',
              icon: Icons.play_arrow_rounded,
              filled: true,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SongSelectScreen(practice: false),
                ),
              ),
            ),
            NeonMenuButton(
              label: 'SONGS',
              icon: Icons.library_music_outlined,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SongSelectScreen(practice: false),
                ),
              ),
            ),
            NeonMenuButton(
              label: 'IMPORT MP3',
              icon: Icons.file_upload_outlined,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ImportSongScreen()),
              ),
            ),
            NeonMenuButton(
              label: 'PRACTICE',
              icon: Icons.fitness_center,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SongSelectScreen(practice: true),
                ),
              ),
            ),
            NeonMenuButton(
              label: 'SETTINGS',
              icon: Icons.settings_outlined,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            NeonMenuButton(
              label: 'PROFILE',
              icon: Icons.person_outline,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
            const Spacer(),
            const Text(
              'AUDIO-CLOCK TIMING  ·  OFFLINE',
              style: TextStyle(
                color: NeonPalette.muted,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
