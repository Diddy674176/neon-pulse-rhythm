import 'dart:convert';
import 'dart:typed_data';

import 'package:idb_shim/idb_browser.dart';
import 'package:uuid/uuid.dart';

import '../chart/chart_generator.dart';
import 'song_catalog.dart';

/// Web library — stores imported MP3 bytes + charts in IndexedDB (with memory fallback).
class ImportedLibrary {
  static const _dbName = 'aether_beat_library';
  static const _dbVersion = 1;
  static const _storeMeta = 'songs';
  static const _storeAudio = 'audio';
  static const _storeChart = 'charts';
  static const _uuid = Uuid();

  Database? _db;
  bool _memoryOnly = false;

  final Map<String, SongMeta> _memMeta = {};
  final Map<String, Uint8List> _memAudio = {};
  final Map<String, String> _memChart = {};

  Future<Database?> _openDb() async {
    if (_memoryOnly) return null;
    if (_db != null) return _db;
    try {
      final factory = idbFactoryBrowser;
      _db = await factory.open(
        _dbName,
        version: _dbVersion,
        onUpgradeNeeded: (VersionChangeEvent e) {
          final db = e.database;
          if (!db.objectStoreNames.contains(_storeMeta)) {
            db.createObjectStore(_storeMeta, keyPath: 'id');
          }
          if (!db.objectStoreNames.contains(_storeAudio)) {
            db.createObjectStore(_storeAudio);
          }
          if (!db.objectStoreNames.contains(_storeChart)) {
            db.createObjectStore(_storeChart);
          }
        },
      );
      return _db;
    } catch (_) {
      _memoryOnly = true;
      return null;
    }
  }

  Future<List<SongMeta>> loadAll() async {
    final db = await _openDb();
    if (db == null) {
      return _memMeta.values.toList();
    }
    try {
      final txn = db.transaction(_storeMeta, idbModeReadOnly);
      final store = txn.objectStore(_storeMeta);
      final raw = await store.getAll();
      await txn.completed;
      final out = <SongMeta>[];
      for (final item in raw) {
        if (item is Map) {
          final meta = SongMeta.fromJson(Map<String, dynamic>.from(item));
          if (meta.isImported) out.add(meta);
        }
      }
      for (final m in out) {
        _memMeta[m.id] = m;
      }
      return out;
    } catch (_) {
      return _memMeta.values.toList();
    }
  }

  Future<void> _saveMetaList(Database db, List<SongMeta> songs) async {
    final txn = db.transaction(_storeMeta, idbModeReadWrite);
    final store = txn.objectStore(_storeMeta);
    await store.clear();
    for (final s in songs) {
      await store.put(s.toJson());
    }
    await txn.completed;
  }

  /// Import from in-memory MP3 bytes (web file_picker). [sourcePath] is ignored on web.
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
    final _ignoredPath = sourcePath;
    assert(_ignoredPath == null || _ignoredPath.isNotEmpty || _ignoredPath.isEmpty);
    final bytes = audioBytes;
    if (bytes == null || bytes.isEmpty) {
      throw const ImportException('No MP3 data to import. Pick a file again.');
    }
    if (bytes.lengthInBytes > 40 * 1024 * 1024) {
      throw const ImportException('MP3 is too large (max ~40MB for browser storage).');
    }

    final id = 'import_${_uuid.v4().replaceAll('-', '').substring(0, 12)}';
    final audioKey = 'idb:$id/audio.mp3';
    final chartKey = 'idb:$id/chart.json';
    final safeDuration = durationMs > 0 ? durationMs : 60000;

    final chart = ChartGenerator().generate(
      songId: id,
      title: title.trim().isEmpty ? 'Imported Track' : title.trim(),
      artist: artist.trim().isEmpty ? 'Unknown Artist' : artist.trim(),
      bpm: bpm.clamp(40, 300),
      durationMs: safeDuration.toDouble(),
      audioPath: audioKey,
      difficulty: difficulty,
      laneCount: laneCount.clamp(4, 6),
      offsetMs: offsetMs,
    );
    final chartJson =
        const JsonEncoder.withIndent('  ').convert(chart.toJson());

    final meta = SongMeta(
      id: id,
      title: chart.title,
      artist: chart.artist,
      bpm: chart.bpm,
      durationMs: safeDuration,
      chartPath: chartKey,
      audioPath: audioKey,
      difficulties: [difficulty],
      coverColor: '#FF2BD6',
      isImported: true,
      offsetMs: offsetMs,
      laneCount: laneCount.clamp(4, 6),
    );

    _memMeta[id] = meta;
    _memAudio[id] = bytes;
    _memChart[id] = chartJson;

    final db = await _openDb();
    if (db != null) {
      try {
        final audioTxn = db.transaction(_storeAudio, idbModeReadWrite);
        await audioTxn.objectStore(_storeAudio).put(bytes, id);
        await audioTxn.completed;

        final chartTxn = db.transaction(_storeChart, idbModeReadWrite);
        await chartTxn.objectStore(_storeChart).put(chartJson, id);
        await chartTxn.completed;

        final all = await loadAll();
        final merged = [
          for (final s in all)
            if (s.id != id) s,
          meta,
        ];
        await _saveMetaList(db, merged);
      } catch (e) {
        _memoryOnly = _db == null;
      }
    }

    return meta;
  }

  Future<void> delete(String songId) async {
    _memMeta.remove(songId);
    _memAudio.remove(songId);
    _memChart.remove(songId);

    final db = await _openDb();
    if (db == null) return;
    try {
      final txnMeta = db.transaction(_storeMeta, idbModeReadWrite);
      await txnMeta.objectStore(_storeMeta).delete(songId);
      await txnMeta.completed;

      final txnA = db.transaction(_storeAudio, idbModeReadWrite);
      await txnA.objectStore(_storeAudio).delete(songId);
      await txnA.completed;

      final txnC = db.transaction(_storeChart, idbModeReadWrite);
      await txnC.objectStore(_storeChart).delete(songId);
      await txnC.completed;
    } catch (_) {}
  }

  Future<String> readChartJson(SongMeta song) async {
    final cached = _memChart[song.id];
    if (cached != null) return cached;

    final db = await _openDb();
    if (db != null) {
      try {
        final txn = db.transaction(_storeChart, idbModeReadOnly);
        final value = await txn.objectStore(_storeChart).getObject(song.id);
        await txn.completed;
        if (value is String && value.isNotEmpty) {
          _memChart[song.id] = value;
          return value;
        }
      } catch (_) {}
    }
    throw const ImportException('Imported chart not found in browser storage.');
  }

  Future<Uint8List> readAudioBytes(SongMeta song) async {
    final cached = _memAudio[song.id];
    if (cached != null) return cached;

    final db = await _openDb();
    if (db != null) {
      try {
        final txn = db.transaction(_storeAudio, idbModeReadOnly);
        final value = await txn.objectStore(_storeAudio).getObject(song.id);
        await txn.completed;
        if (value is Uint8List) {
          _memAudio[song.id] = value;
          return value;
        }
        if (value is List<int>) {
          final bytes = Uint8List.fromList(value);
          _memAudio[song.id] = bytes;
          return bytes;
        }
        if (value is ByteBuffer) {
          final bytes = value.asUint8List();
          _memAudio[song.id] = bytes;
          return bytes;
        }
      } catch (_) {}
    }
    throw const ImportException('Imported audio not found in browser storage.');
  }
}

class ImportException implements Exception {
  const ImportException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Estimate duration from MP3 byte length (~128kbps ≈ 16KB/s).
Future<int> probeAudioDurationMs({String? path, Uint8List? bytes}) async {
  try {
    final length = bytes?.lengthInBytes;
    if (length == null || length <= 0) return 60000;
    final estimate = ((length / 16000) * 1000).round();
    return estimate.clamp(5000, 15 * 60 * 1000);
  } catch (_) {
    return 60000;
  }
}
