import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import '../platform/native_fs.dart' as nfs;
import 'audio_clock.dart';
import 'procedural_tracks.dart';

/// Plays song audio and exposes [AudioClock] from the player position.
class AudioService implements AudioClock {
  AudioService({this.musicVolume = 0.9, this.masterVolume = 1.0});

  final AudioPlayer _player = AudioPlayer();
  double musicVolume;
  double masterVolume;
  bool _playing = false;
  double _lastPos = 0;
  final _posController = StreamController<double>.broadcast();
  StreamSubscription<Duration>? _posSub;

  @override
  double get currentTimeMs => _lastPos;

  @override
  bool get isPlaying => _playing;

  @override
  Stream<double> get positionStream => _posController.stream;

  Future<void> init() async {
    await _player.setReleaseMode(ReleaseMode.stop);
    _posSub = _player.onPositionChanged.listen((d) {
      _lastPos = d.inMicroseconds / 1000.0;
      _posController.add(_lastPos);
    });
    _player.onPlayerStateChanged.listen((s) {
      _playing = s == PlayerState.playing;
    });
  }

  Future<void> setVolumes({double? master, double? music}) async {
    if (master != null) masterVolume = master;
    if (music != null) musicVolume = music;
    await _player.setVolume((masterVolume * musicVolume).clamp(0.0, 1.0));
  }

  /// Load from Flutter asset path (ogg/wav).
  Future<void> loadAsset(String assetPath) async {
    await _player.setSource(AssetSource(_stripAssetsPrefix(assetPath)));
    await setVolumes();
  }

  String? _mimeForExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'mp3':
      case 'mpeg':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      case 'm4a':
      case 'aac':
        return 'audio/mp4';
      default:
        return null;
    }
  }

  Future<void> _playBytes(Uint8List bytes, {String ext = 'ogg'}) async {
    if (kIsWeb) {
      await _player.setSource(BytesSource(bytes, mimeType: _mimeForExt(ext)));
    } else {
      final path = await nfs.writeTempAudioBytes(bytes, ext);
      await _player.setSource(DeviceFileSource(path));
    }
    await setVolumes();
  }

  /// Decode a `.b64` sibling asset if the binary was shipped as text.
  /// Supports single `.b64` or numbered parts `.b64.0` … `.b64.N`.
  Future<void> loadAssetOrB64(String assetPath) async {
    try {
      await loadAsset(assetPath);
    } catch (_) {
      final b64 = await _loadB64Parts('$assetPath.b64');
      final bytes = Uint8List.fromList(base64Decode(b64));
      final ext = assetPath.contains('.') ? assetPath.split('.').last : 'ogg';
      await _playBytes(bytes, ext: ext);
    }
  }

  Future<String> _loadB64Parts(String basePath) async {
    try {
      return await rootBundle.loadString(basePath);
    } catch (_) {
      final buf = StringBuffer();
      for (var i = 0; i < 32; i++) {
        try {
          buf.write(await rootBundle.loadString('$basePath.$i'));
        } catch (_) {
          if (i == 0) rethrow;
          break;
        }
      }
      return buf.toString();
    }
  }

  Future<void> loadBytes(Uint8List bytes, {String ext = 'ogg'}) async {
    await _playBytes(bytes, ext: ext);
  }

  /// Load a device file (e.g. imported MP3 under app documents).
  Future<void> loadFile(String path) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Device file paths are unavailable on web — use loadBytes / BytesSource.',
      );
    }
    if (!await nfs.pathExists(path)) {
      throw StateError('Audio file missing: $path');
    }
    await _player.setSource(DeviceFileSource(path));
    await setVolumes();
  }

  /// Prefer asset/b64 for catalog tracks; device file or bytes for imports.
  Future<void> loadSongAudio({
    required String audioPath,
    required bool isImported,
    Uint8List? bytes,
  }) async {
    if (isImported) {
      if (bytes != null && bytes.isNotEmpty) {
        await _playBytes(bytes, ext: 'mp3');
        return;
      }
      if (kIsWeb) {
        throw StateError('Imported track bytes missing for web playback.');
      }
      await loadFile(audioPath);
    } else {
      // Prefer tiny procedural beds for built-in catalog (reliable on Pages).
      final wav = ProceduralTracks.maybeBuild(audioPath);
      if (wav != null) {
        await _playBytes(wav, ext: 'wav');
        return;
      }
      await loadAssetOrB64(audioPath);
    }
  }

  Future<Duration?> getDuration() => _player.getDuration();

  String _stripAssetsPrefix(String path) {
    const prefix = 'assets/';
    if (path.startsWith(prefix)) return path.substring(prefix.length);
    return path;
  }

  @override
  Future<void> play() async {
    await _player.resume();
    _playing = true;
  }

  Future<void> playFromStart() async {
    await _player.seek(Duration.zero);
    await _player.resume();
    _playing = true;
    _lastPos = 0;
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _playing = false;
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _playing = false;
    _lastPos = 0;
    _posController.add(0);
  }

  @override
  Future<void> seek(double timeMs) async {
    await _player.seek(Duration(milliseconds: timeMs.round()));
    _lastPos = timeMs;
    _posController.add(_lastPos);
  }

  /// Poll position (some platforms throttle onPositionChanged).
  Future<double> refreshPosition() async {
    final d = await _player.getCurrentPosition();
    if (d != null) {
      _lastPos = d.inMicroseconds / 1000.0;
      _posController.add(_lastPos);
    }
    return _lastPos;
  }

  @override
  Future<void> dispose() async {
    await _posSub?.cancel();
    await _player.dispose();
    await _posController.close();
  }
}
