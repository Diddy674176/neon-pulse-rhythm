import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import '../platform/native_fs.dart' as nfs;
import '../song/imported_library.dart';
import '../song/song_catalog.dart';
import 'chart_data.dart';

class ChartLoader {
  Future<ChartData> loadAsset(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return ChartData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<ChartData> loadFile(String path) async {
    if (kIsWeb) {
      throw UnsupportedError('Device chart paths are unavailable on web.');
    }
    final raw = await nfs.readPathAsString(path);
    return ChartData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<ChartData> loadForSong(
    SongMeta song, {
    ImportedLibrary? imported,
  }) async {
    if (song.isImported) {
      if (imported != null) {
        final raw = await imported.readChartJson(song);
        return ChartData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
      return loadFile(song.chartPath);
    }
    return loadAsset(song.chartPath);
  }

  ChartData loadFromString(String raw) {
    return ChartData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
