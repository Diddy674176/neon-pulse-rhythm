import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../song/song_catalog.dart';
import 'chart_data.dart';

class ChartLoader {
  Future<ChartData> loadAsset(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return ChartData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<ChartData> loadFile(String path) async {
    final raw = await File(path).readAsString();
    return ChartData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<ChartData> loadForSong(SongMeta song) async {
    if (song.isImported) {
      return loadFile(song.chartPath);
    }
    return loadAsset(song.chartPath);
  }

  ChartData loadFromString(String raw) {
    return ChartData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
