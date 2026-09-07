import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../ui/neon_widgets.dart';
import '../ui/page_routes.dart';
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
    final result = await Navigator.of(context).push(aetherRoute(const ImportSongScreen()));
    if (result != null && mounted) setState(() {});
  }

  Color _accentFor(String cover) {
    try {
      final h = cover.replaceAll('#', '');
      if (h.length == 6) {
        return Color(int.parse('FF$h', radix: 16));
      }
    } catch (_) {}
    return NeonPalette.accent;
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
                    autoOn ? 'Auto Play will hit Perfect for you' : 'Tap dark tiles on the hit line',
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
                final durSec = (s.durationMs / 1000).round();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SongCard(
                    title: s.title,
                    subtitle: '${s.artist} · ${s.bpm.toStringAsFixed(0)} BPM · ${durSec}s',
                    badge: s.isImported ? 'IMPORTED' : s.difficulties.first,
                    accent: _accentFor(s.coverColor),
                    onTap: () => Navigator.of(context).push(
                      aetherRoute(GameplayScreen(song: s, practice: widget.practice)),
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
