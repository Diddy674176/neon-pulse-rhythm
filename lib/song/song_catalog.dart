import 'dart:convert';
import 'package:flutter/services.dart';

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
      );
}

class SongCatalog {
  List<SongMeta> songs = [];

  Future<void> load({String asset = 'assets/songs/catalog.json'}) async {
    final raw = await rootBundle.loadString(asset);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    songs = (map['songs'] as List<dynamic>)
        .map((e) => SongMeta.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
