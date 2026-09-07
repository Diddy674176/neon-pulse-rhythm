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
    this.autoPlay = false,
  }) {
    notes = chart.notes.map(NoteRuntime.new).toList();
  }

  final ChartData chart;
  final AudioClock clock;
  final TimingEngine timing;
  final JudgmentCallback? onJudgment;
  final double approachMs;
  bool autoPlay;

  late List<NoteRuntime> notes;
  final ScoreModel score = ScoreModel();
  final ComboTracker combo = ComboTracker();
  bool finished = false;
  Judgment lastJudgment = Judgment.none;
  double lastDeltaMs = 0;

  /// First index that may still need work — skips a long resolved prefix.
  int _scanFrom = 0;

  /// Reused buffer — avoids allocating a new List every frame.
  final List<NoteRuntime> _visibleBuf = <NoteRuntime>[];

  double get audioTimeMs => clock.currentTimeMs;

  void _advanceScan() {
    while (_scanFrom < notes.length && notes[_scanFrom].resolved) {
      _scanFrom++;
    }
  }

  List<NoteRuntime> visibleNotes() {
    final t = audioTimeMs;
    _visibleBuf.clear();
    final latePad = timing.windows.goodMs + 200;
    _advanceScan();
    for (var i = _scanFrom; i < notes.length; i++) {
      final n = notes[i];
      if (n.resolved) continue;
      final start = n.note.timeMs - approachMs;
      if (t < start) {
        // Notes are time-sorted in charts; later ones are also not visible yet.
        if (n.note.timeMs - t > approachMs + 50) break;
        continue;
      }
      final end = (n.note.endTimeMs ?? n.note.timeMs) + latePad;
      if (t <= end) _visibleBuf.add(n);
    }
    return _visibleBuf;
  }

  /// Call every frame for auto-misses + optional autoplay — uses audio time.
  void tick() {
    final t = audioTimeMs;
    if (autoPlay) _runAutoPlay(t);

    _advanceScan();
    for (var i = _scanFrom; i < notes.length; i++) {
      final n = notes[i];
      if (n.resolved) continue;

      if (n.note.type == NoteType.hold && n.holdActive) {
        final end = n.note.endTimeMs ?? n.note.timeMs;
        // Held through the late window → credit the start judgment (kept the hold).
        if (timing.shouldAutoMiss(noteTimeMs: end, rawAudioTimeMs: t)) {
          final grade = n.startJudgment ?? Judgment.perfect;
          _resolve(
            n,
            grade == Judgment.miss ? Judgment.good : grade,
            timing.deltaMs(noteTimeMs: end, rawAudioTimeMs: t),
          );
        }
        continue;
      }

      // Never pressed (or hold never started) → miss after start window.
      if (timing.shouldAutoMiss(noteTimeMs: n.note.timeMs, rawAudioTimeMs: t)) {
        _resolve(
          n,
          Judgment.miss,
          timing.deltaMs(noteTimeMs: n.note.timeMs, rawAudioTimeMs: t),
        );
      }
    }
    if (!finished && t >= chart.durationMs + 500) {
      finished = true;
    }
    if (!finished && notes.every((n) => n.resolved)) {
      finished = true;
    }
  }

  /// Fire Perfect-timed hits when |noteTime - audioTime| ≤ Perfect window.
  void _runAutoPlay(double t) {
    final perfect = timing.windows.perfectMs.toDouble();
    _advanceScan();
    for (var i = _scanFrom; i < notes.length; i++) {
      final n = notes[i];
      if (n.resolved) continue;

      if (n.note.type == NoteType.hold) {
        if (!n.holdActive) {
          final err = timing.absErrorMs(noteTimeMs: n.note.timeMs, rawAudioTimeMs: t);
          if (err <= perfect) {
            handleInput(LaneInputEvent(
              kind: InputKind.holdStart,
              lane: n.note.lane,
              audioTimeMs: t,
            ));
          }
        } else {
          final end = n.note.endTimeMs ?? n.note.timeMs;
          // Release at/near end (not early). Prefer exact end or slightly late.
          final d = timing.deltaMs(noteTimeMs: end, rawAudioTimeMs: t);
          if (d <= perfect) {
            handleInput(LaneInputEvent(
              kind: InputKind.holdEnd,
              lane: n.note.lane,
              audioTimeMs: t,
            ));
          }
        }
        continue;
      }

      final err = timing.absErrorMs(noteTimeMs: n.note.timeMs, rawAudioTimeMs: t);
      if (err > perfect) continue;

      if (n.note.type == NoteType.swipe) {
        handleInput(LaneInputEvent(
          kind: InputKind.swipe,
          lane: n.note.lane,
          audioTimeMs: t,
          direction: n.note.direction,
        ));
      } else {
        handleInput(LaneInputEvent(
          kind: InputKind.tap,
          lane: n.note.lane,
          audioTimeMs: t,
        ));
      }
    }
  }

  void handleInput(LaneInputEvent e) {
    final candidates = <NoteRuntime>[];
    _advanceScan();
    for (var i = _scanFrom; i < notes.length; i++) {
      final n = notes[i];
      if (n.resolved) continue;
      if (n.laneMismatch(e.lane)) continue;
      if (!_matchesKind(n, e)) continue;
      candidates.add(n);
    }

    if (candidates.isEmpty) return;

    candidates.sort((a, b) {
      final ta = e.kind == InputKind.holdEnd
          ? (a.note.endTimeMs ?? a.note.timeMs)
          : a.note.timeMs;
      final tb = e.kind == InputKind.holdEnd
          ? (b.note.endTimeMs ?? b.note.timeMs)
          : b.note.timeMs;
      final da = (ta - e.audioTimeMs).abs();
      final db = (tb - e.audioTimeMs).abs();
      return da.compareTo(db);
    });

    final n = candidates.first;

    if (e.kind == InputKind.holdStart && n.note.type == NoteType.hold) {
      if (n.holdActive) return;
      final j = timing.judge(noteTimeMs: n.note.timeMs, rawAudioTimeMs: e.audioTimeMs);
      if (j == Judgment.miss) {
        // Press outside the start window — only resolve if inside extended check.
        if (!timing.isInHitWindow(noteTimeMs: n.note.timeMs, rawAudioTimeMs: e.audioTimeMs)) {
          return;
        }
        _resolve(
          n,
          Judgment.miss,
          timing.deltaMs(noteTimeMs: n.note.timeMs, rawAudioTimeMs: e.audioTimeMs),
        );
        return;
      }
      n.holdActive = true;
      n.startJudgment = j;
      n.hitDeltaMs =
          timing.deltaMs(noteTimeMs: n.note.timeMs, rawAudioTimeMs: e.audioTimeMs);
      return;
    }

    if (e.kind == InputKind.holdEnd && n.note.type == NoteType.hold) {
      if (!n.holdActive) return;
      final end = n.note.endTimeMs ?? n.note.timeMs;
      final d = timing.deltaMs(noteTimeMs: end, rawAudioTimeMs: e.audioTimeMs);
      // Released too early (well before end) → miss.
      if (d > timing.windows.goodMs) {
        _resolve(n, Judgment.miss, d);
        return;
      }
      final endJ = timing.judge(noteTimeMs: end, rawAudioTimeMs: e.audioTimeMs);
      final startJ = n.startJudgment ?? Judgment.perfect;
      final grade = endJ == Judgment.miss
          ? Judgment.miss
          : _worse(startJ, endJ);
      _resolve(n, grade, d);
      return;
    }

    if (n.note.type == NoteType.swipe) {
      if (e.kind != InputKind.swipe && e.kind != InputKind.tap) return;
    }

    final j = timing.judge(noteTimeMs: n.note.timeMs, rawAudioTimeMs: e.audioTimeMs);
    final d = timing.deltaMs(noteTimeMs: n.note.timeMs, rawAudioTimeMs: e.audioTimeMs);
    if (j == Judgment.miss &&
        !timing.isInHitWindow(noteTimeMs: n.note.timeMs, rawAudioTimeMs: e.audioTimeMs)) {
      return;
    }
    _resolve(n, j, d);
  }

  bool _matchesKind(NoteRuntime n, LaneInputEvent e) {
    switch (n.note.type) {
      case NoteType.tap:
        return e.kind == InputKind.tap;
      case NoteType.hold:
        if (e.kind == InputKind.holdStart) return !n.holdActive;
        if (e.kind == InputKind.holdEnd) return n.holdActive;
        return false;
      case NoteType.swipe:
        return e.kind == InputKind.swipe || e.kind == InputKind.tap;
    }
  }

  static Judgment _worse(Judgment a, Judgment b) {
    int rank(Judgment j) => switch (j) {
          Judgment.perfect => 0,
          Judgment.great => 1,
          Judgment.good => 2,
          Judgment.miss => 3,
          Judgment.none => 4,
        };
    return rank(a) >= rank(b) ? a : b;
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
