import '../audio/audio_clock.dart';
import '../chart/chart_data.dart';
import '../chart/note.dart';
import '../combo/combo_tracker.dart';
import '../input/lane_input.dart';
import '../rhythm/judgment.dart';
import '../rhythm/timing_engine.dart';
import '../scoring/score_model.dart';
import 'note_runtime.dart';

typedef JudgmentCallback = void Function(NoteRuntime note, Judgment j, double deltaMs);

/// Core gameplay loop logic — timing from [AudioClock] only.
class GameplayController {
  GameplayController({
    required this.chart,
    required this.clock,
    required this.timing,
    this.onJudgment,
    this.approachMs = 1500,
  }) {
    notes = chart.notes.map(NoteRuntime.new).toList();
  }

  final ChartData chart;
  final AudioClock clock;
  final TimingEngine timing;
  final JudgmentCallback? onJudgment;
  final double approachMs;

  late List<NoteRuntime> notes;
  final ScoreModel score = ScoreModel();
  final ComboTracker combo = ComboTracker();
  bool finished = false;
  Judgment lastJudgment = Judgment.none;
  double lastDeltaMs = 0;

  double get audioTimeMs => clock.currentTimeMs;

  List<NoteRuntime> visibleNotes() {
    final t = audioTimeMs;
    return notes.where((n) {
      if (n.resolved && n.note.type != NoteType.hold) return false;
      final start = n.note.timeMs - approachMs;
      final end = (n.note.endTimeMs ?? n.note.timeMs) + timing.windows.goodMs + 200;
      return t >= start && t <= end;
    }).toList();
  }

  void tick() {
    final t = audioTimeMs;
    for (final n in notes) {
      if (n.resolved) continue;
      if (n.note.type == NoteType.hold && n.holdActive) {
        if (timing.shouldAutoMiss(
          noteTimeMs: n.note.endTimeMs ?? n.note.timeMs,
          rawAudioTimeMs: t,
        )) {
          _resolve(n, Judgment.miss, timing.deltaMs(
            noteTimeMs: n.note.endTimeMs ?? n.note.timeMs,
            rawAudioTimeMs: t,
          ));
        }
        continue;
      }
      if (timing.shouldAutoMiss(noteTimeMs: n.note.timeMs, rawAudioTimeMs: t)) {
        _resolve(n, Judgment.miss, timing.deltaMs(noteTimeMs: n.note.timeMs, rawAudioTimeMs: t));
      }
    }
    if (!finished && t >= chart.durationMs + 500) {
      finished = true;
    }
    if (!finished && notes.every((n) => n.resolved)) {
      finished = true;
    }
  }

  void handleInput(LaneInputEvent e) {
    final candidates = notes.where((n) {
      if (n.resolved) return false;
      if (n.laneMismatch(e.lane)) return false;
      return _matchesKind(n, e);
    }).toList();

    if (candidates.isEmpty) return;

    candidates.sort((a, b) {
      final da = (a.note.timeMs - e.audioTimeMs).abs();
      final db = (b.note.timeMs - e.audioTimeMs).abs();
      return da.compareTo(db);
    });

    final n = candidates.first;

    if (e.kind == InputKind.holdStart && n.note.type == NoteType.hold) {
      final j = timing.judge(noteTimeMs: n.note.timeMs, rawAudioTimeMs: e.audioTimeMs);
      if (j == Judgment.miss) {
        _resolve(n, Judgment.miss, timing.deltaMs(noteTimeMs: n.note.timeMs, rawAudioTimeMs: e.audioTimeMs));
        return;
      }
      n.holdActive = true;
      n.hitDeltaMs = timing.deltaMs(noteTimeMs: n.note.timeMs, rawAudioTimeMs: e.audioTimeMs);
      return;
    }

    if (e.kind == InputKind.holdEnd && n.note.type == NoteType.hold && n.holdActive) {
      final j = timing.judge(
        noteTimeMs: n.note.endTimeMs ?? n.note.timeMs,
        rawAudioTimeMs: e.audioTimeMs,
      );
      final d = timing.deltaMs(
        noteTimeMs: n.note.endTimeMs ?? n.note.timeMs,
        rawAudioTimeMs: e.audioTimeMs,
      );
      _resolve(n, j == Judgment.miss ? Judgment.good : j, d);
      return;
    }

    if (n.note.type == NoteType.swipe) {
      if (e.kind != InputKind.swipe) return;
    }

    final j = timing.judge(noteTimeMs: n.note.timeMs, rawAudioTimeMs: e.audioTimeMs);
    final d = timing.deltaMs(noteTimeMs: n.note.timeMs, rawAudioTimeMs: e.audioTimeMs);
    if (j == Judgment.miss && !timing.isInHitWindow(noteTimeMs: n.note.timeMs, rawAudioTimeMs: e.audioTimeMs)) {
      return;
    }
    _resolve(n, j, d);
  }

  bool _matchesKind(NoteRuntime n, LaneInputEvent e) {
    switch (n.note.type) {
      case NoteType.tap:
        return e.kind == InputKind.tap;
      case NoteType.hold:
        return e.kind == InputKind.holdStart || e.kind == InputKind.holdEnd;
      case NoteType.swipe:
        return e.kind == InputKind.swipe || e.kind == InputKind.tap;
    }
  }

  void _resolve(NoteRuntime n, Judgment j, double deltaMs) {
    if (n.resolved) return;
    n.hit = j != Judgment.miss;
    n.missed = j == Judgment.miss;
    n.judgment = j;
    n.hitDeltaMs = deltaMs;
    n.holdActive = false;
    if (j == Judgment.miss) {
      combo.breakCombo();
    } else {
      combo.hit();
    }
    score.apply(j, comboBefore: j == Judgment.miss ? 0 : combo.value - 1);
    score.currentCombo = combo.value;
    score.multiplier = combo.multiplier;
    lastJudgment = j;
    lastDeltaMs = deltaMs;
    onJudgment?.call(n, j, deltaMs);
  }
}

extension on NoteRuntime {
  bool laneMismatch(int lane) => note.lane != lane;
}
