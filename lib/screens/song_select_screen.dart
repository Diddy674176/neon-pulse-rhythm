import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../app_state.dart';
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
  void _toggleAutoPlay() {
    final s = AppState.instance.settings;
    s.autoPlay = !s.autoPlay;
    AppState.instance.persistSettings();
    setState(() {});
  }

  Future<void> _openImport() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ImportSongScreen()),
    );
    if (result != null && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final songs = AppState.instance.catalog.songs;
    final autoOn = AppState.instance.settings.autoPlay;
    return SafeNeonScaffold(
      title: widget.practice ? 'PRACTICE' : 'SONGS',
      floatingActionButton: kIsWeb
          ? null
          : FloatingActionButton.extended(
              onPressed: _openImport,
              backgroundColor: NeonPalette.surface,
              foregroundColor: NeonPalette.text,
              elevation: 0,
              icon: const Icon(Icons.add),
              label: const Text('IMPORT', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    autoOn ? 'Auto Play will hit Perfect for you' : 'Tap a song to play',
                    style: const TextStyle(color: NeonPalette.muted, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: _toggleAutoPlay,
                  style: TextButton.styleFrom(
                    foregroundColor: autoOn ? NeonPalette.accent : NeonPalette.muted,
                  ),
                  child: Text(
                    autoOn ? 'AUTO PLAY ON' : 'AUTO PLAY OFF',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 0, 16, kIsWeb ? 24 : 88),
              itemCount: songs.length,
              itemBuilder: (context, i) {
                final s = songs[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: NeonPanel(
                    child: ListTile(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GameplayScreen(song: s, practice: widget.practice),
                        ),
                      ),
                      leading: Icon(
                        s.isImported ? Icons.audio_file_outlined : Icons.music_note_outlined,
                        color: NeonPalette.text,
                      ),
                      title: Text(s.title, style: const TextStyle(color: NeonPalette.text, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${s.artist} · ${s.bpm.toStringAsFixed(0)} BPM',
                        style: const TextStyle(color: NeonPalette.muted, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: NeonPalette.muted),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
