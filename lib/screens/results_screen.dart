import 'package:flutter/material.dart';
import '../scoring/score_model.dart';
import '../song/song_catalog.dart';
import '../ui/neon_widgets.dart';
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

  @override
  Widget build(BuildContext context) {
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
                    style: const TextStyle(
                      color: NeonPalette.text,
                      fontSize: 64,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                    ),
                  ),
                  Text(
                    song.title,
                    style: const TextStyle(color: NeonPalette.muted, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${score.score}',
                    style: const TextStyle(
                      color: NeonPalette.text,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'ACCURACY ${(score.accuracy * 100).toStringAsFixed(2)}%  ·  MAX COMBO ${score.maxCombo}',
                    style: const TextStyle(color: NeonPalette.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  _row('PERFECT', score.perfect, NeonPalette.text),
                  _row('GREAT', score.great, NeonPalette.accent),
                  _row('GOOD', score.good, NeonPalette.muted),
                  _row('MISS', score.miss, NeonPalette.danger),
                ],
              ),
            ),
            const Spacer(),
            NeonMenuButton(
              label: 'RETRY',
              filled: true,
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) =>
                        GameplayScreen(song: song, practice: practice),
                  ),
                );
              },
            ),
            NeonMenuButton(
              label: 'MENU',
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainMenuScreen()),
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
              style: TextStyle(
                  color: c, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
          Text('$count', style: TextStyle(color: c, fontSize: 18)),
        ],
      ),
    );
  }
}
