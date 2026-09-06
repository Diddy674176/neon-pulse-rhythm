import 'package:flutter/material.dart';
import '../app_state.dart';
import '../song/song_catalog.dart';
import '../ui/neon_widgets.dart';
import '../vfx/neon_palette.dart';
import 'gameplay_screen.dart';
import 'import_song_screen.dart';

class SongSelectScreen extends StatefulWidget {
  const SongSelectScreen({super.key, required this.practice});
  final bool practice;

  @override
  State<SongSelectScreen> createState() => _SongSelectScreenState();
}

class _SongSelectScreenState extends State<SongSelectScreen> {
  Future<void> _openImport() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ImportSongScreen()),
    );
    if (result != null && mounted) setState(() {});
  }

  Future<void> _deleteImported(SongMeta song) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeonPalette.bgElevated,
        title: const Text('Remove import?', style: TextStyle(color: NeonPalette.text)),
        content: Text(
          'Delete “${song.title}” from the offline library?',
          style: const TextStyle(color: NeonPalette.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(color: NeonPalette.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE', style: TextStyle(color: NeonPalette.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AppState.instance.catalog.imported.delete(song.id);
    await AppState.instance.catalog.reloadImported();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final songs = AppState.instance.catalog.songs;
    return SafeNeonScaffold(
      title: widget.practice ? 'PRACTICE' : 'SONGS',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openImport,
        backgroundColor: NeonPalette.magenta.withOpacity(0.9),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('IMPORT MP3', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
      ),
      body: songs.isEmpty
          ? const Center(
              child: Text('No songs yet — import an MP3.', style: TextStyle(color: NeonPalette.muted)),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: songs.length,
              itemBuilder: (context, i) {
                final s = songs[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NeonPanel(
                    child: InkWell(
                      onTap: () => _open(context, s),
                      onLongPress: s.isImported ? () => _deleteImported(s) : null,
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: s.isImported
                                    ? const [NeonPalette.magenta, NeonPalette.violet]
                                    : const [NeonPalette.cyan, NeonPalette.magenta],
                              ),
                            ),
                            child: Icon(
                              s.isImported ? Icons.audio_file : Icons.graphic_eq,
                              color: Colors.black87,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        s.title,
                                        style: const TextStyle(
                                          color: NeonPalette.text,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    if (s.isImported)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: NeonPalette.magenta),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'IMPORTED',
                                          style: TextStyle(
                                            color: NeonPalette.magenta,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Text(
                                  s.artist,
                                  style: const TextStyle(color: NeonPalette.muted),
                                ),
                                Text(
                                  '${s.bpm.toStringAsFixed(0)} BPM  ·  ${(s.durationMs / 1000).toStringAsFixed(0)}s  ·  ${s.difficulties.join(", ")}'
                                  '${s.isImported ? "  ·  ${s.laneCount} lanes" : ""}',
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
        builder: (_) => GameplayScreen(song: song, practice: widget.practice),
      ),
    );
  }
}
