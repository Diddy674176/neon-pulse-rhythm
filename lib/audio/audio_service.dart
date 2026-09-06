import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'audio_clock.dart';

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

  Future<void> loadAsset(String assetPath) async {
    await _player.setSource(AssetSource(_stripAssetsPrefix(assetPath)));
    await setVolumes();
  }

  /// Decode `.b64` or split `.b64.0`+`.b64.1` sidecars when binary is missing.
  Future<void> loadAssetOrB64(String assetPath) async {
    try {
      await loadAsset(assetPath);
    } catch (_) {
      String b64;
      try {
        b64 = await rootBundle.loadString('$assetPath.b64');
      } catch (_) {
        final p0 = await rootBundle.loadString('$assetPath.b64.0');
        final p1 = await rootBundle.loadString('$assetPath.b64.1');
        b64 = p0 + p1;
      }
      final bytes = base64Decode(b64);
      final dir = await getTemporaryDirectory();
      final name = assetPath.split('/').last;
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes, flush: true);
      await _player.setSource(DeviceFileSource(file.path));
      await setVolumes();
    }
  }

  Future<void> loadBytes(Uint8List bytes, {String ext = 'ogg'}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/aether_track.$ext');
    await file.writeAsBytes(bytes, flush: true);
    await _player.setSource(DeviceFileSource(file.path));
    await setVolumes();
  }

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
