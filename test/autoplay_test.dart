import 'package:flutter_test/flutter_test.dart';
import 'package:aether_beat/audio/audio_clock.dart';
import 'package:aether_beat/chart/chart_data.dart';
import 'package:aether_beat/chart/note.dart';
import 'package:aether_beat/gameplay/gameplay_controller.dart';
import 'package:aether_beat/rhythm/judgment.dart';
import 'package:aether_beat/rhythm/timing_engine.dart';

void main() {
  test('autoplay hits Perfect when within Perfect window', () async {
    final clock = SimulatedAudioClock();
    final chart = ChartData(
      songId: 't',
      title: 'Test',
      artist: 'Test',
      difficulty: 'easy',
      bpm: 120,
      offsetMs: 0,
      durationMs: 5000,
      audioAsset: '',
      laneCount: 4,
      notes: [
        ChartNote(id: 'n1', timeMs: 1000, lane: 0, type: NoteType.tap),
        ChartNote(id: 'n2', timeMs: 2000, lane: 1, type: NoteType.tap),
      ],
    );
    final timing = TimingEngine();
    final c = GameplayController(
      chart: chart,
      clock: clock,
      timing: timing,
      autoPlay: true,
    );

    await clock.play();
    await clock.seek(900);
    c.tick();
    expect(c.notes[0].resolved, isFalse);

    await clock.seek(1000);
    c.tick();
    expect(c.notes[0].resolved, isTrue);
    expect(c.notes[0].judgment, Judgment.perfect);

    await clock.seek(2000);
    c.tick();
    expect(c.notes[1].judgment, Judgment.perfect);
    expect(c.score.perfect, 2);
    expect(c.score.miss, 0);
  });
}
