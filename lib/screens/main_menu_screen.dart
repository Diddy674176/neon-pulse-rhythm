import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../ui/neon_widgets.dart';
import '../ui/page_routes.dart';
import '../vfx/neon_palette.dart';
import 'song_select_screen.dart';
import 'import_song_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeTip());
  }

  Future<void> _maybeTip() async {
    if (!mounted) return;
    if (AppState.instance.seenOnboarding) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeonPalette.bgElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: NeonPalette.tileEdge),
        ),
        title: const Text(
          'HOW TO PLAY',
          style: TextStyle(
            color: NeonPalette.text,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        content: const Text(
          'Tap the dark tiles when they reach the hit line.\n\n'
          'Tip: enable Auto Play once from Songs or Settings to watch Perfect hits fire automatically.',
          style: TextStyle(color: NeonPalette.muted, height: 1.45, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await AppState.instance.markOnboardingSeen();
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('GOT IT', style: TextStyle(color: NeonPalette.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    await AppState.instance.markOnboardingSeen();
  }

  void _go(Widget page) {
    Navigator.of(context).push(aetherRoute(page));
  }

  @override
  Widget build(BuildContext context) {
    final hz = AppState.instance.refresh.bucket();
    return SafeNeonScaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              'AETHER BEAT',
              style: TextStyle(
                color: NeonPalette.text,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
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
            const Spacer(flex: 2),
            NeonMenuButton(
              label: 'PLAY',
              icon: Icons.play_arrow_rounded,
              filled: true,
              onPressed: () => _go(const SongSelectScreen(practice: false)),
            ),
            NeonMenuButton(
              label: 'SONGS',
              icon: Icons.library_music_outlined,
              onPressed: () => _go(const SongSelectScreen(practice: false)),
            ),
            if (!kIsWeb)
              NeonMenuButton(
                label: 'IMPORT MP3',
                icon: Icons.file_upload_outlined,
                onPressed: () => _go(const ImportSongScreen()),
              ),
            NeonMenuButton(
              label: 'PRACTICE',
              icon: Icons.fitness_center,
              onPressed: () => _go(const SongSelectScreen(practice: true)),
            ),
            NeonMenuButton(
              label: 'SETTINGS',
              icon: Icons.settings_outlined,
              onPressed: () => _go(const SettingsScreen()),
            ),
            NeonMenuButton(
              label: 'PROFILE',
              icon: Icons.person_outline,
              onPressed: () => _go(const ProfileScreen()),
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
