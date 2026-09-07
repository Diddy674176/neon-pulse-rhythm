import 'package:flutter/material.dart';
import '../app_state.dart';
import '../scoring/score_model.dart';
import '../song/song_catalog.dart';
import '../ui/neon_widgets.dart';
import '../ui/page_routes.dart';
import '../vfx/neon_palette.dart';
import 'gameplay_screen.dart';
import 'main_menu_screen.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({
    super.key,
    required this.song,
    required this.score,
    required this.practice,
  });

  final SongMeta song;
  final ScoreModel score;
  final bool practice;

  SongMeta? _nextSong() {
    final songs = AppState.instance.catalog.songs;
    final i = songs.indexWhere((s) => s.id == song.id);
    if (i < 0 || songs.isEmpty) return null;
    return songs[(i + 1) % songs.length];
  }

  Color get _gradeColor {
    switch (score.grade) {
      case 'SS':
      case 'S':
        return NeonPalette.text;
      case 'A':
        return NeonPalette.accent;
      case 'B':
      case 'C':
        return NeonPalette.muted;
      default:
        return NeonPalette.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final next = _nextSong();
    return SafeNeonScaffold(
      title: 'RESULTS',
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            NeonPanel(
              child: Column(
                children: [
                  Text(
                    score.grade,
                    style: TextStyle(
                      color: _gradeColor,
                      fontSize: 72,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    song.title,
                    style: const TextStyle(color: NeonPalette.muted, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${score.score}',
                    style: const TextStyle(
                      color: NeonPalette.text,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ACCURACY ${(score.accuracy * 100).toStringAsFixed(2)}%',
                    style: const TextStyle(color: NeonPalette.text, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'MAX COMBO ${score.maxCombo}',
                    style: const TextStyle(color: NeonPalette.accent, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 16),
                  _row('PERFECT', score.perfect, NeonPalette.perfect),
                  _row('GREAT', score.great, NeonPalette.great),
                  _row('GOOD', score.good, NeonPalette.good),
                  _row('MISS', score.miss, NeonPalette.danger),
                ],
              ),
            ),
            const Spacer(),
            NeonMenuButton(
              label: 'REPLAY',
              filled: true,
              icon: Icons.replay,
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  aetherRoute(GameplayScreen(song: song, practice: practice)),
                );
              },
            ),
            if (next != null && next.id != song.id)
              NeonMenuButton(
                label: 'NEXT  ·  ${next.title.toUpperCase()}',
                icon: Icons.skip_next_rounded,
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    aetherRoute(GameplayScreen(song: next, practice: practice)),
                  );
                },
              ),
            NeonMenuButton(
              label: 'MENU',
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  aetherRoute(const MainMenuScreen()),
                  (_) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, int count, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: c, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
          Text('$count', style: TextStyle(color: c, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
