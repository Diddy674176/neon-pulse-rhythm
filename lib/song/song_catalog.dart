import 'dart:convert';
import 'package:flutter/services.dart';

import 'imported_library.dart';

class SongMeta {
  SongMeta({
    required this.id,
    required this.title,
    required this.artist,
    required this.bpm,
    required this.durationMs,
    required this.chartPath,
    required this.audioPath,
    this.difficulties = const ['Normal'],
    this.coverColor = '#00F5FF',
    this.isImported = false,
    this.offsetMs = 0,
    this.laneCount = 4,
  });

  final String id;
  final String title;
  final String artist;
  final double bpm;
  final int durationMs;
  final String chartPath;
  final String audioPath;
  final List<String> difficulties;
  final String coverColor;
  final bool isImported;
  final double offsetMs;
  final int laneCount;

  factory SongMeta.fromJson(Map<String, dynamic> j) => SongMeta(
        id: j['id'] as String,
        title: j['title'] as String? ?? 'Untitled',
        artist: j['artist'] as String? ?? '',
        bpm: (j['bpm'] as num?)?.toDouble() ?? 120,
        durationMs: j['durationMs'] as int? ?? 0,
        chartPath: j['chartPath'] as String,
        audioPath: j['audioPath'] as String,
        difficulties: (j['difficulties'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const ['Normal'],
        coverColor: j['coverColor'] as String? ?? '#00F5FF',
        isImported: j['isImported'] as bool? ?? false,
        offsetMs: (j['offsetMs'] as num?)?.toDouble() ?? 0,
        laneCount: j['laneCount'] as int? ?? 4,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'bpm': bpm,
        'durationMs': durationMs,
        'chartPath': chartPath,
        'audioPath': audioPath,
        'difficulties': difficulties,
        'coverColor': coverColor,
        'isImported': isImported,
        'offsetMs': offsetMs,
        'laneCount': laneCount,
      };
}

class SongCatalog {
  List<SongMeta> songs = [];
  final ImportedLibrary imported = ImportedLibrary();

  Future<void> load({String asset = 'assets/songs/catalog.json'}) async {
    final raw = await rootBundle.loadString(asset);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final builtIn = (map['songs'] as List<dynamic>)
        .map((e) => SongMeta.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final user = await imported.loadAll();
    songs = [...builtIn, ...user];
  }

  Future<void> reloadImported() async {
    final builtIn = songs.where((s) => !s.isImported).toList();
    final user = await imported.loadAll();
    songs = [...builtIn, ...user];
  }
}
