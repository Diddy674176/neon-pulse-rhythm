import 'dart:typed_data';

/// Web / non-IO stubs — device filesystem is unavailable.

Future<String> writeTempAudioBytes(Uint8List bytes, String ext) async {
  throw UnsupportedError('Temporary audio files are not available on web.');
}

Future<bool> pathExists(String path) async => false;

Future<String> readPathAsString(String path) async {
  throw UnsupportedError('Reading device files is not available on web.');
}
