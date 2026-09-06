import 'song_catalog.dart';

/// Web stub — imported MP3 library is unavailable in the browser.
class ImportedLibrary {
  Future<List<SongMeta>> loadAll() async => [];

  Future<SongMeta> importMp3({
    required String sourcePath,
    required String title,
    required String artist,
    required double bpm,
    required String difficulty,
    required int laneCount,
    required double offsetMs,
    required int durationMs,
  }) async {
    throw const ImportException(
      'MP3 import is not available in the web/PWA build. Use the Android APK.',
    );
  }

  Future<void> delete(String songId) async {}
}

class ImportException implements Exception {
  const ImportException(this.message);
  final String message;
  @override
  String toString() => message;
}

Future<int> probeAudioDurationMs(String path) async => 60000;
