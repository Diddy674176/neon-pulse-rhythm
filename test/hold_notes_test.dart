import 'package:flutter_test/flutter_test.dart';
import 'package:aether_beat/audio/audio_clock.dart';
import 'package:aether_beat/chart/chart_data.dart';
import 'package:aether_beat/chart/note.dart';
import 'package:aether_beat/gameplay/gameplay_controller.dart';
import 'package:aether_beat/input/lane_input.dart';
import 'package:aether_beat/rhythm/judgment.dart';
import 'package:aether_beat/rhythm/timing_engine.dart';

ChartData _chart(List<ChartNote> notes) => ChartData(
      songId: 'hold',
      title: 'Hold Test',
      artist: 'Test',
      difficulty: 'easy',
      bpm: 120,
      offsetMs: 0,
      durationMs: 8000,
      audioAsset: '',
      laneCount: 4,
      notes: notes,
    );

void main() {
  late SimulatedAudioClock clock;
  late TimingEngine timing;

  setUp(() {
    clock = SimulatedAudioClock();
    timing = TimingEngine();
  });

  test('hold: press at start + release at end → Perfect', () async {
    final c = GameplayController(
      chart: _chart([
        ChartNote(id: 'h1', timeMs: 1000, endTimeMs: 1500, lane: 0, type: NoteType.hold),
      ]),
      clock: clock,
      timing: timing,
    );
    await clock.play();
    await clock.seek(1000);
    c.handleInput(LaneInputEvent(kind: InputKind.holdStart, lane: 0, audioTimeMs: 1000));
    expect(c.notes[0].holdActive, isTrue);
    expect(c.notes[0].resolved, isFalse);

    await clock.seek(1500);
    c.handleInput(LaneInputEvent(kind: InputKind.holdEnd, lane: 0, audioTimeMs: 1500));
    expect(c.notes[0].resolved, isTrue);
    expect(c.notes[0].judgment, Judgment.perfect);
    expect(c.score.miss, 0);
  });

  test('hold: early release → Miss', () async {
    final c = GameplayController(
      chart: _chart([
        ChartNote(id: 'h1', timeMs: 1000, endTimeMs: 2000, lane: 1, type: NoteType.hold),
      ]),
      clock: clock,
      timing: timing,
    );
    await clock.play();
    await clock.seek(1000);
    c.handleInput(LaneInputEvent(kind: InputKind.holdStart, lane: 1, audioTimeMs: 1000));
    expect(c.notes[0].holdActive, isTrue);

    // Release 500ms before end (well outside good window of 90ms).
    await clock.seek(1500);
    c.handleInput(LaneInputEvent(kind: InputKind.holdEnd, lane: 1, audioTimeMs: 1500));
    expect(c.notes[0].resolved, isTrue);
    expect(c.notes[0].judgment, Judgment.miss);
  });

  test('hold: never pressed → auto Miss after start window', () async {
    final c = GameplayController(
      chart: _chart([
        ChartNote(id: 'h1', timeMs: 1000, endTimeMs: 1400, lane: 2, type: NoteType.hold),
      ]),
      clock: clock,
      timing: timing,
    );
    await clock.play();
    await clock.seek(1000 + timing.windows.goodMs + 1);
    c.tick();
    expect(c.notes[0].resolved, isTrue);
    expect(c.notes[0].judgment, Judgment.miss);
  });

  test('hold: release without press is ignored', () async {
    final c = GameplayController(
      chart: _chart([
        ChartNote(id: 'h1', timeMs: 1000, endTimeMs: 1400, lane: 0, type: NoteType.hold),
      ]),
      clock: clock,
      timing: timing,
    );
    await clock.play();
    await clock.seek(1400);
    c.handleInput(LaneInputEvent(kind: InputKind.holdEnd, lane: 0, audioTimeMs: 1400));
    expect(c.notes[0].resolved, isFalse);
    expect(c.notes[0].holdActive, isFalse);
  });

  test('autoplay holds: press at start, release at end', () async {
    final c = GameplayController(
      chart: _chart([
        ChartNote(id: 'h1', timeMs: 1000, endTimeMs: 1600, lane: 0, type: NoteType.hold),
        ChartNote(id: 't1', timeMs: 2000, lane: 1, type: NoteType.tap),
      ]),
      clock: clock,
      timing: timing,
      autoPlay: true,
    );
    await clock.play();

    await clock.seek(1000);
    c.tick();
    expect(c.notes[0].holdActive, isTrue);
    expect(c.notes[0].resolved, isFalse);

    await clock.seek(1600);
    c.tick();
    expect(c.notes[0].resolved, isTrue);
    expect(c.notes[0].judgment, Judgment.perfect);

    await clock.seek(2000);
    c.tick();
    expect(c.notes[1].judgment, Judgment.perfect);
    expect(c.score.miss, 0);
  });

  test('hold: held past end window auto-completes (not miss)', () async {
    final c = GameplayController(
      chart: _chart([
        ChartNote(id: 'h1', timeMs: 1000, endTimeMs: 1300, lane: 0, type: NoteType.hold),
      ]),
      clock: clock,
      timing: timing,
    );
    await clock.play();
    await clock.seek(1000);
    c.handleInput(LaneInputEvent(kind: InputKind.holdStart, lane: 0, audioTimeMs: 1000));
    expect(c.notes[0].holdActive, isTrue);

    // Still holding past end + good window.
    await clock.seek(1300 + timing.windows.goodMs + 1);
    c.tick();
    expect(c.notes[0].resolved, isTrue);
    expect(c.notes[0].judgment, isNot(Judgment.miss));
  });
}
