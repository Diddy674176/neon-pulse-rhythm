import 'judgment.dart';

/// Pure audio-clock timing engine.
///
/// Hit detection uses ONLY:
///   delta = noteTimeMs - currentAudioTimeMs
/// (after applying calibration offset). Frame deltas and FPS are never used
/// for judgment — rendering can run at 60 or 120 Hz independently.
class TimingEngine {
  TimingEngine({
    this.windows = JudgmentWindows.standard,
    this.audioLatencyOffsetMs = 0,
    this.touchLatencyOffsetMs = 0,
  });

  JudgmentWindows windows;

  /// Positive values mean audio is heard later than reported clock (compensate).
  int audioLatencyOffsetMs;

  /// Positive values mean touch is registered later than the actual tap.
  int touchLatencyOffsetMs;

  /// Combined calibration applied to the audio clock when judging.
  int get totalOffsetMs => audioLatencyOffsetMs + touchLatencyOffsetMs;

  /// Effective audio time used for judgment.
  /// [rawAudioTimeMs] must come from the audio playback position.
  double effectiveAudioTimeMs(double rawAudioTimeMs) {
    return rawAudioTimeMs + totalOffsetMs;
  }

  /// Signed delta: negative = early, positive = late.
  /// [noteTimeMs] is chart time; [rawAudioTimeMs] is player position.
  double deltaMs({
    required double noteTimeMs,
    required double rawAudioTimeMs,
  }) {
    final current = effectiveAudioTimeMs(rawAudioTimeMs);
    return noteTimeMs - current;
  }

  /// Absolute error used for window checks.
  double absErrorMs({
    required double noteTimeMs,
    required double rawAudioTimeMs,
  }) {
    return deltaMs(noteTimeMs: noteTimeMs, rawAudioTimeMs: rawAudioTimeMs).abs();
  }

  /// Judge a press at [rawAudioTimeMs] against [noteTimeMs].
  /// Does NOT depend on frame rate or frame count.
  Judgment judge({
    required double noteTimeMs,
    required double rawAudioTimeMs,
  }) {
    final err = absErrorMs(noteTimeMs: noteTimeMs, rawAudioTimeMs: rawAudioTimeMs);
    if (err <= windows.perfectMs) return Judgment.perfect;
    if (err <= windows.greatMs) return Judgment.great;
    if (err <= windows.goodMs) return Judgment.good;
    return Judgment.miss;
  }

  /// Whether the note is still hittable (within good window or approaching).
  bool isInHitWindow({
    required double noteTimeMs,
    required double rawAudioTimeMs,
  }) {
    final d = deltaMs(noteTimeMs: noteTimeMs, rawAudioTimeMs: rawAudioTimeMs);
    return d.abs() <= windows.goodMs;
  }

  /// Note has passed beyond the late good window → auto-miss.
  bool shouldAutoMiss({
    required double noteTimeMs,
    required double rawAudioTimeMs,
  }) {
    final d = deltaMs(noteTimeMs: noteTimeMs, rawAudioTimeMs: rawAudioTimeMs);
    return d < -windows.goodMs;
  }

  TimingEngine copyWith({
    JudgmentWindows? windows,
    int? audioLatencyOffsetMs,
    int? touchLatencyOffsetMs,
  }) {
    return TimingEngine(
      windows: windows ?? this.windows,
      audioLatencyOffsetMs: audioLatencyOffsetMs ?? this.audioLatencyOffsetMs,
      touchLatencyOffsetMs: touchLatencyOffsetMs ?? this.touchLatencyOffsetMs,
    );
  }
}

/// Simulates presses at a fixed audio timeline for FPS-independence tests.
/// Advances audio time in frame steps but judgment uses audio time only.
class TimingSimulator {
  TimingSimulator(this.engine);

  final TimingEngine engine;

  Judgment pressAtAudioTime({
    required double noteTimeMs,
    required double pressAudioTimeMs,
  }) {
    return engine.judge(
      noteTimeMs: noteTimeMs,
      rawAudioTimeMs: pressAudioTimeMs,
    );
  }

  /// Walk a frame loop at [fps] but press when audio clock hits [pressAudioTimeMs].
  /// Returns the judgment of that single press (proves FPS does not matter).
  Judgment simulateFrameLoopPress({
    required double noteTimeMs,
    required double pressAudioTimeMs,
    required double fps,
    double startAudioMs = 0,
    double endAudioMs = 10000,
  }) {
    final dt = 1000.0 / fps;
    var audio = startAudioMs;
    Judgment? result;
    while (audio <= endAudioMs) {
      if (result == null && audio >= pressAudioTimeMs) {
        result = engine.judge(
          noteTimeMs: noteTimeMs,
          rawAudioTimeMs: pressAudioTimeMs,
        );
      }
      audio += dt;
    }
    return result ?? Judgment.miss;
  }
}
