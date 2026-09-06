import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Short punchy hit/miss SFX with a small player pool (never blocks the clock).
class SfxService {
  SfxService();

  final List<AudioPlayer> _pool = [];
  int _cursor = 0;
  double masterVolume = 1.0;
  double sfxVolume = 0.8;
  bool ready = false;

  final Map<String, Uint8List> _bytes = {};

  static const _poolSize = 4;
  static const _keys = {
    'PERFECT': 'hit_perfect',
    'GREAT': 'hit_great',
    'GOOD': 'hit_good',
    'MISS': 'hit_miss',
  };

  Future<void> init() async {
    try {
      for (final name in _keys.values) {
        _bytes[name] = await _loadOggBytes(name);
      }
      for (var i = 0; i < _poolSize; i++) {
        final p = AudioPlayer();
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setPlayerMode(PlayerMode.lowLatency);
        _pool.add(p);
      }
      ready = true;
    } catch (e) {
      debugPrint('SfxService init: $e');
      ready = _pool.isNotEmpty && _bytes.isNotEmpty;
    }
  }

  Future<Uint8List> _loadOggBytes(String name) async {
    try {
      final data = await rootBundle.load('assets/audio/$name.ogg');
      return data.buffer.asUint8List();
    } catch (_) {
      try {
        final b64 = await rootBundle.loadString('assets/audio/$name.ogg.b64');
        return Uint8List.fromList(base64Decode(b64));
      } catch (_) {
        final p0 = await rootBundle.loadString('assets/audio/$name.ogg.b64.0');
        final p1 = await rootBundle.loadString('assets/audio/$name.ogg.b64.1');
        return Uint8List.fromList(base64Decode(p0 + p1));
      }
    }
  }

  void setVolumes({double? master, double? sfx}) {
    if (master != null) masterVolume = master;
    if (sfx != null) sfxVolume = sfx;
  }

  double get _vol => (masterVolume * sfxVolume).clamp(0.0, 1.0);

  Future<void> playHit(String judgmentLabel) async {
    if (!ready || _vol <= 0.001) return;
    final key = _keys[judgmentLabel] ?? 'hit_good';
    _fire(key);
  }

  Future<void> playMiss() async {
    if (!ready || _vol <= 0.001) return;
    _fire('hit_miss');
  }

  void _fire(String key) {
    final bytes = _bytes[key];
    if (bytes == null || _pool.isEmpty) return;
    final p = _pool[_cursor % _pool.length];
    _cursor++;
    () async {
      try {
        await p.stop();
        await p.setVolume(_vol);
        await p.play(BytesSource(bytes));
      } catch (e) {
        debugPrint('sfx play: $e');
      }
    }();
  }

  Future<void> dispose() async {
    for (final p in _pool) {
      await p.dispose();
    }
    _pool.clear();
    _bytes.clear();
    ready = false;
  }
}
