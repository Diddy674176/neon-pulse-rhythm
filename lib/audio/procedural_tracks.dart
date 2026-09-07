import 'dart:math';
import 'dart:typed_data';

/// Tiny built-in catalog beds (WAV) — no third-party IP, original AETHER BEAT tones.
class ProceduralTracks {
  ProceduralTracks._();

  static Uint8List? maybeBuild(String audioPath) {
    final id = _idFromPath(audioPath);
    if (id == null) return null;
    switch (id) {
      case 'circuit_mirage':
        return build(durationMs: 16000, bpm: 128, seed: 11);
      case 'pulse_drift':
        return build(durationMs: 22500, bpm: 110, seed: 29);
      case 'void_step':
        return build(durationMs: 16000, bpm: 140, seed: 47);
      default:
        return null;
    }
  }

  static String? _idFromPath(String path) {
    final name = path.split('/').last;
    if (!name.endsWith('.ogg') && !name.endsWith('.wav')) return null;
    return name.replaceAll(RegExp(r'\.(ogg|wav)$'), '');
  }

  /// Mono 16-bit PCM WAV at 16 kHz — small, web-friendly via [BytesSource].
  static Uint8List build({
    required int durationMs,
    required int bpm,
    required int seed,
  }) {
    const sr = 16000;
    final n = (sr * durationMs / 1000).round();
    final samples = Float64List(n);
    final rng = Random(seed);
    final beat = 60.0 / bpm;
    final scale = _scaleFor(seed);

    for (var bi = 0; bi < (durationMs / 1000 / beat).ceil() + 4; bi++) {
      final t0 = bi * beat;
      if (t0 >= durationMs / 1000) break;
      final freq = scale[bi % scale.length];
      if (freq > 0) {
        _pluck(samples, sr, t0, freq, 0.32);
      }
      if (bi % 2 == 0) {
        _kick(samples, sr, t0, 0.45);
      }
      if (bi % 4 == 0) {
        _noiseHat(samples, sr, t0, rng, 0.08);
      }
    }

    var peak = 1e-6;
    for (final s in samples) {
      final a = s.abs();
      if (a > peak) peak = a;
    }
    final scaleAmp = 0.82 / peak;

    final dataSize = n * 2;
    final bytes = BytesBuilder(copy: false);
    void u32(int v) => bytes.add([v & 255, (v >> 8) & 255, (v >> 16) & 255, (v >> 24) & 255]);
    void u16(int v) => bytes.add([v & 255, (v >> 8) & 255]);

    bytes.add('RIFF'.codeUnits);
    u32(36 + dataSize);
    bytes.add('WAVEfmt '.codeUnits);
    u32(16); // pcm chunk
    u16(1); // pcm
    u16(1); // mono
    u32(sr);
    u32(sr * 2); // byte rate
    u16(2); // block align
    u16(16); // bits
    bytes.add('data'.codeUnits);
    u32(dataSize);

    final pcm = ByteData(dataSize);
    for (var i = 0; i < n; i++) {
      final v = (samples[i] * scaleAmp * 32767).round().clamp(-32767, 32767);
      pcm.setInt16(i * 2, v, Endian.little);
    }
    bytes.add(pcm.buffer.asUint8List());
    return bytes.toBytes();
  }

  static List<double> _scaleFor(int seed) {
    const a = <double>[261.63, 0, 329.63, 392.0, 0, 329.63, 0, 261.63];
    const b = <double>[220.0, 0, 261.63, 0, 293.66, 349.23, 0, 293.66];
    const c = <double>[196.0, 246.94, 0, 293.66, 0, 246.94, 196.0, 0];
    switch (seed % 3) {
      case 0:
        return a;
      case 1:
        return b;
      default:
        return c;
    }
  }

  static void _pluck(Float64List samples, int sr, double t0, double freq, double amp) {
    final start = (t0 * sr).round();
    final len = (0.09 * sr).round();
    for (var j = 0; j < len; j++) {
      final i = start + j;
      if (i >= samples.length) break;
      final env = exp(-j / (0.04 * sr));
      samples[i] += amp * env * sin(2 * pi * freq * (j / sr));
    }
  }

  static void _kick(Float64List samples, int sr, double t0, double amp) {
    final start = (t0 * sr).round();
    final len = (0.055 * sr).round();
    for (var j = 0; j < len; j++) {
      final i = start + j;
      if (i >= samples.length) break;
      final env = exp(-j / (0.022 * sr));
      final f = 70.0 + (40.0 * (1 - j / len));
      samples[i] += amp * env * sin(2 * pi * f * (j / sr));
    }
  }

  static void _noiseHat(Float64List samples, int sr, double t0, Random rng, double amp) {
    final start = (t0 * sr).round();
    final len = (0.02 * sr).round();
    for (var j = 0; j < len; j++) {
      final i = start + j;
      if (i >= samples.length) break;
      final env = exp(-j / (0.008 * sr));
      samples[i] += amp * env * (rng.nextDouble() * 2 - 1);
    }
  }
}
