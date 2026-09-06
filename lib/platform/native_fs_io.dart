import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String> writeTempAudioBytes(Uint8List bytes, String ext) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/aether_track.$ext');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<bool> pathExists(String path) => File(path).exists();

Future<String> readPathAsString(String path) => File(path).readAsString();
