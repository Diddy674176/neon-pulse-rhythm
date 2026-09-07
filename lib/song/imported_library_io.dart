import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../chart/chart_generator.dart';
import 'song_catalog.dart';

/// Offline library of user-imported MP3s under app documents (IO platforms).
class ImportedLibrary {
  static const _uuid = Uuid();

  Directory? _root;

  Future<Directory> _ensureRoot() async {
    if (_root != null) return _root!;
    final docs = await getApplicationDocumentsDirectory();
    final root = Directory('${docs.path}/aether_beat/library');
    if (!await root.exists()) await root.create(recursive: true);
    _root = root;
    return root;
  }

  Future<File> _indexFile() async {
    final root = await _ensureRoot();
    return File('${root.path}/library.json');
  }

  Future<List<SongMeta>> loadAll() async {
    try {
      final file = await _indexFile();
      if (!await file.exists()) return [];
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final list = map['songs'] as List<dynamic>? ?? [];
      return list
          .map((e) => SongMeta.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((s) => s.isImported)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveIndex(List<SongMeta> songs) async {
    final file = await _indexFile();
    final payload = {
      'songs': songs.map((s) => s.toJson()).toList(),
    };
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
  }

  /// Copy [sourcePath] or write [audioBytes] into documents, generate chart, persist metadata.
  Future<SongMeta> importMp3({
    String? sourcePath,
    Uint8List? audioBytes,
    required String title,
    required String artist,
    required double bpm,
    required String difficulty,
    required int laneCount,
    required double offsetMs,
    required int durationMs,
  }) async {
    final hasPath = sourcePath != null && sourcePath.isNotEmpty;
    final hasBytes = audioBytes != null && audioBytes.isNotEmpty;
    if (!hasPath && !hasBytes) {
      throw const ImportException('No MP3 selected.');
    }

    if (sourcePath != null && sourcePath.isNotEmpty) {
      final lower = sourcePath.toLowerCase();
      if (!lower.endsWith('.mp3') && !lower.endsWith('.mpeg')) {
        throw const ImportException('Only MP3 files are supported.');
      }
      final sourceMp3 = File(sourcePath);
      if (!await sourceMp3.exists()) {
        throw const ImportException('Selected file was not found.');
      }
    }

    final root = await _ensureRoot();
    final id = 'import_${_uuid.v4().replaceAll('-', '').substring(0, 12)}';
    final songDir = Directory('${root.path}/$id');
    await songDir.create(recursive: true);

    final audioDest = File('${songDir.path}/audio.mp3');
    try {
      if (audioBytes != null && audioBytes.isNotEmpty) {
        await audioDest.writeAsBytes(audioBytes, flush: true);
      } else {
        await File(sourcePath!).copy(audioDest.path);
      }
    } catch (e) {
      throw ImportException('Could not copy MP3 into app storage: $e');
    }

    final safeDuration = durationMs > 0 ? durationMs : 60000;
    final chart = ChartGenerator().generate(
      songId: id,
      title: title.trim().isEmpty ? 'Imported Track' : title.trim(),
      artist: artist.trim().isEmpty ? 'Unknown Artist' : artist.trim(),
      bpm: bpm.clamp(40, 300),
      durationMs: safeDuration.toDouble(),
      audioPath: audioDest.path,
      difficulty: difficulty,
      laneCount: laneCount.clamp(4, 6),
      offsetMs: offsetMs,
    );

    final chartDest = File('${songDir.path}/chart.json');
    await chartDest.writeAsString(
      const JsonEncoder.withIndent('  ').convert(chart.toJson()),
    );

    final meta = SongMeta(
      id: id,
      title: chart.title,
      artist: chart.artist,
      bpm: chart.bpm,
      durationMs: safeDuration,
      chartPath: chartDest.path,
      audioPath: audioDest.path,
      difficulties: [difficulty],
      coverColor: '#FF2BD6',
      isImported: true,
      offsetMs: offsetMs,
      laneCount: laneCount.clamp(4, 6),
    );

    final all = await loadAll();
    all.add(meta);
    await _saveIndex(all);
    return meta;
  }

  Future<void> delete(String songId) async {
    final all = await loadAll();
    all.removeWhere((s) => s.id == songId);
    await _saveIndex(all);
    final root = await _ensureRoot();
    final dir = Directory('${root.path}/$songId');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<String> readChartJson(SongMeta song) async {
    try {
      return await File(song.chartPath).readAsString();
    } catch (e) {
      throw ImportException('Could not read imported chart: $e');
    }
  }

  Future<Uint8List> readAudioBytes(SongMeta song) async {
    try {
      return await File(song.audioPath).readAsBytes();
    } catch (e) {
      throw ImportException('Could not read imported audio: $e');
    }
  }
}

class ImportException implements Exception {
  const ImportException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Probe duration via file size estimate (~128kbps MP3 ≈ 16KB/s).
Future<int> probeAudioDurationMs({String? path, Uint8List? bytes}) async {
  try {
    int length;
    if (bytes != null && bytes.isNotEmpty) {
      length = bytes.lengthInBytes;
    } else if (path != null && path.isNotEmpty) {
      length = await File(path).length();
    } else {
      return 60000;
    }
    final estimate = ((length / 16000) * 1000).round();
    return estimate.clamp(5000, 15 * 60 * 1000);
  } catch (_) {
    return 60000;
  }
}
