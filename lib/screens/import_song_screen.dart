import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../song/imported_library.dart';
import '../ui/neon_widgets.dart';
import '../vfx/neon_palette.dart';

class ImportSongScreen extends StatefulWidget {
  const ImportSongScreen({super.key});

  @override
  State<ImportSongScreen> createState() => _ImportSongScreenState();
}

class _ImportSongScreenState extends State<ImportSongScreen> {
  String? _pickedPath;
  String? _pickedName;
  Uint8List? _pickedBytes;
  final _title = TextEditingController();
  final _artist = TextEditingController();
  final _bpm = TextEditingController(text: '128');
  final _offset = TextEditingController(text: '0');
  String _difficulty = 'Normal';
  int _lanes = 4;
  bool _busy = false;
  String? _error;
  String? _status;

  static const _difficulties = ['Easy', 'Normal', 'Hard', 'Expert'];

  bool get _hasPick =>
      kIsWeb ? (_pickedBytes != null && _pickedBytes!.isNotEmpty) : (_pickedPath != null);

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _bpm.dispose();
    _offset.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() {
      _error = null;
      _status = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['mp3'],
        withData: kIsWeb,
      );
      if (result == null || result.files.isEmpty) {
        // Cancelled — clear prior errors, keep any previous pick.
        setState(() => _error = null);
        return;
      }
      final f = result.files.single;
      final name = f.name;
      final lowerName = name.toLowerCase();
      if (!lowerName.endsWith('.mp3') && !lowerName.endsWith('.mpeg')) {
        setState(() => _error = 'Please choose an .mp3 file.');
        return;
      }

      if (kIsWeb) {
        final bytes = f.bytes;
        if (bytes == null || bytes.isEmpty) {
          setState(() => _error =
              'Could not read that file in the browser. Try a smaller MP3 or another browser.');
          return;
        }
        final base = name.replaceAll(RegExp(r'\.mp3$', caseSensitive: false), '');
        setState(() {
          _pickedBytes = bytes;
          _pickedPath = name;
          _pickedName = name;
          if (_title.text.trim().isEmpty) _title.text = base;
        });
        return;
      }

      final path = f.path;
      if (path == null || path.isEmpty) {
        setState(() => _error =
            'Could not access that file path (scoped storage). Try another folder.');
        return;
      }
      if (!path.toLowerCase().endsWith('.mp3') &&
          !path.toLowerCase().endsWith('.mpeg')) {
        setState(() => _error = 'Please choose an .mp3 file.');
        return;
      }
      final base = name.replaceAll(RegExp(r'\.mp3$', caseSensitive: false), '');
      setState(() {
        _pickedPath = path;
        _pickedName = name;
        _pickedBytes = null;
        if (_title.text.trim().isEmpty) _title.text = base;
      });
    } on PlatformException catch (e) {
      setState(() => _error = 'File picker failed: ${e.message ?? e.code}');
    } catch (e) {
      setState(() => _error = 'File picker error: $e');
    }
  }

  Future<void> _import() async {
    if (_busy) return;
    if (!_hasPick) {
      setState(() => _error = 'Pick an MP3 first.');
      return;
    }
    final bpm = double.tryParse(_bpm.text.trim());
    if (bpm == null || bpm < 40 || bpm > 300) {
      setState(() => _error = 'BPM must be a number between 40 and 300.');
      return;
    }
    final offset = double.tryParse(_offset.text.trim()) ?? 0;
    setState(() {
      _busy = true;
      _error = null;
      _status = 'Copying & generating chart…';
    });
    try {
      final durationMs = await probeAudioDurationMs(
        path: kIsWeb ? null : _pickedPath,
        bytes: _pickedBytes,
      );
      var resolvedDuration = durationMs;
      final audio = AppState.instance.audio;
      if (audio != null) {
        try {
          if (kIsWeb && _pickedBytes != null) {
            await audio.loadBytes(_pickedBytes!, ext: 'mp3');
          } else if (_pickedPath != null) {
            await audio.loadFile(_pickedPath!);
          }
          final d = await audio.getDuration();
          if (d != null && d.inMilliseconds > 1000) {
            resolvedDuration = d.inMilliseconds;
          }
          await audio.stop();
        } catch (_) {
          // Keep size-based estimate.
        }
      }

      final meta = await AppState.instance.catalog.imported.importMp3(
        sourcePath: kIsWeb ? null : _pickedPath,
        audioBytes: kIsWeb ? _pickedBytes : null,
        title: _title.text,
        artist: _artist.text,
        bpm: bpm,
        difficulty: _difficulty,
        laneCount: _lanes,
        offsetMs: offset,
        durationMs: resolvedDuration,
      );
      await AppState.instance.catalog.reloadImported();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = 'Imported “${meta.title}” (${meta.durationMs ~/ 1000}s).';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: NeonPalette.bgElevated,
          content: Text(
            'Imported ${meta.title} — chart ready',
            style: const TextStyle(color: NeonPalette.cyan),
          ),
        ),
      );
      Navigator.of(context).pop(meta);
    } on ImportException catch (e) {
      setState(() {
        _busy = false;
        _error = e.message;
        _status = null;
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = 'Import failed: $e';
        _status = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeNeonScaffold(
      title: 'IMPORT MP3',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          NeonPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  kIsWeb
                      ? 'Pick an MP3 from your device. AETHER BEAT stores it in this browser (IndexedDB) and auto-builds a beat-grid chart from BPM + length.'
                      : 'Pick an MP3 from your device. AETHER BEAT copies it into app storage and auto-builds a beat-grid chart from BPM + length.',
                  style: const TextStyle(color: NeonPalette.muted, height: 1.4),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pick,
                  icon: const Icon(Icons.folder_open, color: NeonPalette.cyan),
                  label: Text(
                    _pickedName ?? 'CHOOSE MP3',
                    style: const TextStyle(
                      color: NeonPalette.cyan,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: NeonPalette.cyan),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                if (_pickedPath != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    kIsWeb
                        ? '$_pickedName (${((_pickedBytes?.lengthInBytes ?? 0) / 1024).toStringAsFixed(0)} KB)'
                        : _pickedPath!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: NeonPalette.muted, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          NeonPanel(
            child: Column(
              children: [
                _field(_title, 'Title'),
                _field(_artist, 'Artist'),
                _field(_bpm, 'BPM', keyboard: TextInputType.number),
                _field(_offset, 'Offset (ms)',
                    keyboard: const TextInputType.numberWithOptions(signed: true)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Difficulty', style: TextStyle(color: NeonPalette.muted)),
                    const Spacer(),
                    DropdownButton<String>(
                      value: _difficulty,
                      dropdownColor: NeonPalette.bgElevated,
                      style: const TextStyle(color: NeonPalette.cyan),
                      items: [
                        for (final d in _difficulties)
                          DropdownMenuItem(value: d, child: Text(d)),
                      ],
                      onChanged: _busy
                          ? null
                          : (v) {
                              if (v != null) setState(() => _difficulty = v);
                            },
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('Lanes', style: TextStyle(color: NeonPalette.muted)),
                    const Spacer(),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 4, label: Text('4')),
                        ButtonSegment(value: 5, label: Text('5')),
                        ButtonSegment(value: 6, label: Text('6')),
                      ],
                      selected: {_lanes},
                      onSelectionChanged: _busy
                          ? null
                          : (s) => setState(() => _lanes = s.first),
                      style: const ButtonStyle(
                        foregroundColor: WidgetStatePropertyAll(NeonPalette.cyan),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: const TextStyle(color: NeonPalette.danger)),
            ),
          if (_status != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_status!, style: const TextStyle(color: NeonPalette.lime)),
            ),
          if (!_busy)
            NeonMenuButton(
              label: 'IMPORT & GENERATE',
              icon: Icons.download,
              accent: NeonPalette.magenta,
              onPressed: _import,
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator(color: NeonPalette.magenta)),
            ),
          const SizedBox(height: 8),
          const Text(
            'Charts use downbeats, phrases, holds, and swipes scaled by difficulty. Timing still uses the audio clock.',
            textAlign: TextAlign.center,
            style: TextStyle(color: NeonPalette.muted, fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        enabled: !_busy,
        keyboardType: keyboard,
        style: const TextStyle(color: NeonPalette.text),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: NeonPalette.muted),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: NeonPalette.cyan.withOpacity(0.35)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: NeonPalette.cyan),
          ),
        ),
      ),
    );
  }
}
