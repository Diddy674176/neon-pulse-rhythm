import 'package:flutter_test/flutter_test.dart';
import 'package:aether_beat/rhythm/judgment.dart';
import 'package:aether_beat/rhythm/timing_engine.dart';

void main() {
  group('TimingEngine audio-clock judgment', () {
    late TimingEngine engine;

    setUp(() {
      engine = TimingEngine();
    });

    test('exact hit is Perfect', () {
      expect(
        engine.judge(noteTimeMs: 1000, rawAudioTimeMs: 1000),
        Judgment.perfect,
      );
    });

    test('windows: Perfect / Great / Good / Miss', () {
      expect(engine.judge(noteTimeMs: 1000, rawAudioTimeMs: 1000 - 25), Judgment.perfect);
      expect(engine.judge(noteTimeMs: 1000, rawAudioTimeMs: 1000 - 26), Judgment.great);
      expect(engine.judge(noteTimeMs: 1000, rawAudioTimeMs: 1000 - 50), Judgment.great);
      expect(engine.judge(noteTimeMs: 1000, rawAudioTimeMs: 1000 - 51), Judgment.good);
      expect(engine.judge(noteTimeMs: 1000, rawAudioTimeMs: 1000 - 90), Judgment.good);
      expect(engine.judge(noteTimeMs: 1000, rawAudioTimeMs: 1000 - 91), Judgment.miss);
    });

    test('calibration offset shifts effective audio time', () {
      final calibrated = TimingEngine(audioLatencyOffsetMs: 40);
      expect(
        calibrated.judge(noteTimeMs: 1000, rawAudioTimeMs: 960),
        Judgment.perfect,
      );
    });

    test('delta sign: early positive, late negative', () {
      expect(engine.deltaMs(noteTimeMs: 1000, rawAudioTimeMs: 980), 20);
      expect(engine.deltaMs(noteTimeMs: 1000, rawAudioTimeMs: 1020), -20);
    });

    test('auto-miss only after late good window', () {
      expect(
        engine.shouldAutoMiss(noteTimeMs: 1000, rawAudioTimeMs: 1089),
        isFalse,
      );
      expect(
        engine.shouldAutoMiss(noteTimeMs: 1000, rawAudioTimeMs: 1091),
        isTrue,
      );
    });
  });

  group('FPS independence — same press audio time → same judgment', () {
    test('60 vs 120 FPS frame loops yield identical judgment', () {
      final engine = TimingEngine();
      final sim = TimingSimulator(engine);

      const note = 2000.0;
      const press = 1982.0;

      final at60 = sim.simulateFrameLoopPress(
        noteTimeMs: note,
        pressAudioTimeMs: press,
        fps: 60,
      );
      final at120 = sim.simulateFrameLoopPress(
        noteTimeMs: note,
        pressAudioTimeMs: press,
        fps: 120,
      );
      final at90 = sim.simulateFrameLoopPress(
        noteTimeMs: note,
        pressAudioTimeMs: press,
        fps: 90,
      );

      expect(at60, Judgment.perfect);
      expect(at120, Judgment.perfect);
      expect(at90, Judgment.perfect);
      expect(at60, at120);
      expect(at120, at90);
    });

    test('same press time across FPS for Great and Good windows', () {
      final engine = TimingEngine();
      final sim = TimingSimulator(engine);

      final g60 = sim.pressAtAudioTime(noteTimeMs: 3000, pressAudioTimeMs: 2960);
      final g120 = sim.simulateFrameLoopPress(
        noteTimeMs: 3000,
        pressAudioTimeMs: 2960,
        fps: 120,
      );
      expect(g60, Judgment.great);
      expect(g120, Judgment.great);
      expect(g60, g120);

      final good60 = sim.simulateFrameLoopPress(
        noteTimeMs: 4000,
        pressAudioTimeMs: 4070,
        fps: 60,
      );
      final good120 = sim.simulateFrameLoopPress(
        noteTimeMs: 4000,
        pressAudioTimeMs: 4070,
        fps: 120,
      );
      expect(good60, Judgment.good);
      expect(good120, good60);
    });

    test('judgment ignores frame count — only audio timestamps matter', () {
      final engine = TimingEngine();
      const audio = 1500.0;
      const note = 1510.0;
      final j1 = engine.judge(noteTimeMs: note, rawAudioTimeMs: audio);
      final j2 = engine.judge(noteTimeMs: note, rawAudioTimeMs: audio);
      expect(j1, Judgment.perfect);
      expect(j1, j2);
    });
  });
}
