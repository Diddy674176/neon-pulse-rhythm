import 'dart:async';

/// Primary timing reference: audio playback position in milliseconds.
/// Gameplay MUST query this clock for hit detection — never frame counts.
abstract class AudioClock {
  double get currentTimeMs;
  bool get isPlaying;
  Stream<double> get positionStream;
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(double timeMs);
  Future<void> dispose();
}

class SimulatedAudioClock implements AudioClock {
  SimulatedAudioClock({this.timeMs = 0, this.playing = false});

  double timeMs;
  bool playing;
  final _controller = StreamController<double>.broadcast();

  @override
  double get currentTimeMs => timeMs;

  @override
  bool get isPlaying => playing;

  @override
  Stream<double> get positionStream => _controller.stream;

  void advance(double deltaMs) {
    if (!playing) return;
    timeMs += deltaMs;
    _controller.add(timeMs);
  }

  void setPosition(double ms) {
    timeMs = ms;
    _controller.add(timeMs);
  }

  @override
  Future<void> play() async {
    playing = true;
  }

  @override
  Future<void> pause() async {
    playing = false;
  }

  @override
  Future<void> stop() async {
    playing = false;
    timeMs = 0;
    _controller.add(timeMs);
  }

  @override
  Future<void> seek(double timeMs) async {
    this.timeMs = timeMs;
    _controller.add(this.timeMs);
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}
