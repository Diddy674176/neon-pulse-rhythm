import 'package:flutter/material.dart';
import '../app_state.dart';
import '../song/song_catalog.dart';
import '../ui/neon_widgets.dart';
import '../vfx/neon_palette.dart';
import 'gameplay_screen.dart';

class SongSelectScreen extends StatelessWidget {
  const SongSelectScreen({super.key, required this.practice});
  final bool practice;

  @override
  Widget build(BuildContext context) {
    final songs = AppState.instance.catalog.songs;
    return SafeNeonScaffold(
      title: practice ? 'PRACTICE' : 'SONGS',
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: songs.length,
        itemBuilder: (context, i) {
          final s = songs[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: NeonPanel(
              child: InkWell(
                onTap: () => _open(context, s),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [NeonPalette.cyan, NeonPalette.magenta],
                        ),
                      ),
                      child: const Icon(Icons.graphic_eq, color: Colors.black87, size: 32),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.title,
                            style: const TextStyle(
                              color: NeonPalette.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          Text(s.artist, style: const TextStyle(color: NeonPalette.muted)),
                          Text(
                            '${s.bpm.toStringAsFixed(0)} BPM  ·  ${(s.durationMs / 1000).toStringAsFixed(0)}s  ·  ${s.difficulties.join(", ")}',
                            style: const TextStyle(color: NeonPalette.cyan, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: NeonPalette.cyan),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _open(BuildContext context, SongMeta song) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameplayScreen(song: song, practice: practice),
      ),
    );
  }
}
