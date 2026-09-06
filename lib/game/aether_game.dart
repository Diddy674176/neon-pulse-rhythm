import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import '../audio/audio_clock.dart';
import '../chart/chart_data.dart';
import '../chart/note.dart';
import '../gameplay/gameplay_controller.dart';
import '../haptics/haptics_service.dart';
import '../input/lane_input.dart';
import '../rhythm/judgment.dart';
import '../rhythm/timing_engine.dart';
import '../settings/game_settings.dart';
import '../vfx/neon_palette.dart';

class AetherGame extends FlameGame {
  AetherGame({required this.chart, required this.clock, required this.settings, required this.timing, required this.haptics, this.practiceMode = false, this.onFinished});
  final ChartData chart; final AudioClock clock; final GameSettings settings; final TimingEngine timing; final HapticsService haptics; final bool practiceMode; final void Function()? onFinished;
  late GameplayController controller; bool _started = false; bool _finishNotified = false;
  final Paint _bg = Paint()..color = NeonPalette.bg;
  final Paint _lane = Paint()..color = NeonPalette.laneFill;
  final Paint _div = Paint()..color = NeonPalette.laneDivider..strokeWidth = 1;
  final Paint _hit = Paint()..color = NeonPalette.hitZone..strokeWidth = 2.5;
  final Paint _band = Paint()..color = NeonPalette.hitZoneSoft;
  final Paint _tile = Paint()..color = NeonPalette.tile;
  final Paint _edge = Paint()..color = NeonPalette.tileEdge..style = PaintingStyle.stroke..strokeWidth = 1.5;
  final Paint _hold = Paint()..color = const Color(0xFF1A1A1A);
  final Paint _holdOn = Paint()..color = const Color(0xFF2A2A2A);
  TextPainter? _hud; TextPainter? _jud; TextPainter? _ap;
  int _ls = -1; int _lc = -1; double _la = -1; Judgment _lj = Judgment.none; double _ld = 0;

  bool get autoPlay => settings.autoPlay;
  set autoPlay(bool v) { settings.autoPlay = v; controller.autoPlay = v; }

  @override Color backgroundColor() => NeonPalette.bg;

  @override Future<void> onLoad() async {
    controller = GameplayController(chart: chart, clock: clock, timing: timing, approachMs: 1600 / settings.noteSpeed, autoPlay: settings.autoPlay,
      onJudgment: (n, j, d) { if (!kIsWeb && (j == Judgment.perfect || !settings.reducedVfx)) haptics.forJudgment(j.label); });
  }

  Future<void> start() async { _started = true; await clock.play(); }
  Future<void> restart() async { _finishNotified = false; await clock.stop(); await clock.seek(0); await onLoad(); await clock.play(); _started = true; }

  int get laneCount => settings.laneCount.clamp(4, 6);
  double get hitLineY => size.y * 0.78;
  double get _topY => size.y * 0.06;
  double get _pad => size.x * 0.04;
  double get _slot => (size.x - _pad * 2) / laneCount;
  Rect laneRect(int lane) { final l = _pad + _slot * lane + 4; final r = _pad + _slot * (lane + 1) - 4; return Rect.fromLTRB(l, _topY, r, size.y * 0.92); }
  double laneX(int lane) => laneRect(lane).center.dx;
  double tileW(int lane) => (laneRect(lane).width * 0.92 * settings.noteSize).clamp(28.0, laneRect(lane).width);
  double tileH() => (52.0 * settings.noteSize).clamp(36.0, 72.0);
  int laneAt(Offset p) { final i = ((p.dx - _pad) / _slot).floor().clamp(0, laneCount - 1); return settings.handedness == Handedness.left ? (laneCount - 1 - i) : i; }

  void onPointerDown(Offset pos) {
    final lane = laneAt(pos); final t = clock.currentTimeMs;
    final holdNear = controller.notes.any((n) => !n.resolved && n.note.type == NoteType.hold && n.note.lane == lane && timing.isInHitWindow(noteTimeMs: n.note.timeMs, rawAudioTimeMs: t));
    controller.handleInput(LaneInputEvent(kind: holdNear ? InputKind.holdStart : InputKind.tap, lane: lane, audioTimeMs: t));
  }
  void onPointerUp(Offset pos, int lane) => controller.handleInput(LaneInputEvent(kind: InputKind.holdEnd, lane: lane, audioTimeMs: clock.currentTimeMs));
  void onSwipe(Offset pos, SwipeDirection dir) => controller.handleInput(LaneInputEvent(kind: InputKind.swipe, lane: laneAt(pos), audioTimeMs: clock.currentTimeMs, direction: dir));

  @override void update(double dt) {
    super.update(dt); if (!_started) return; controller.autoPlay = settings.autoPlay; controller.tick();
    if (controller.finished && !_finishNotified) { _finishNotified = true; onFinished?.call(); }
  }

  @override void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _bg);
    final lanes = laneCount;
    for (var i = 0; i < lanes; i++) {
      canvas.drawRRect(RRect.fromRectAndRadius(laneRect(i), const Radius.circular(6)), _lane);
      if (i > 0) { final x = _pad + _slot * i; canvas.drawLine(Offset(x, _topY), Offset(x, hitLineY + 24), _div); }
    }
    final th = tileH();
    canvas.drawRect(Rect.fromLTRB(_pad, hitLineY - th * 0.55, size.x - _pad, hitLineY + th * 0.45), _band);
    canvas.drawLine(Offset(_pad, hitLineY), Offset(size.x - _pad, hitLineY), _hit);
    final t = controller.audioTimeMs; final approach = controller.approachMs; final travel = hitLineY - _topY;
    for (final n in controller.visibleNotes()) {
      final note = n.note;
      final lane = settings.handedness == Handedness.left ? (lanes - 1 - note.lane % lanes) : note.lane % lanes;
      final cx = laneX(lane); final tw = tileW(lane);
      final progress = ((note.timeMs - t) / approach).clamp(-0.35, 1.0);
      final y = hitLineY - progress * travel;
      if (note.type == NoteType.hold) {
        final ep = (((note.endTimeMs ?? note.timeMs) - t) / approach).clamp(-0.35, 1.0);
        final paint = n.holdActive ? _holdOn : _hold; paint.strokeWidth = tw * 0.88;
        canvas.drawLine(Offset(cx, y), Offset(cx, hitLineY - ep * travel), paint);
      }
      final rr = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, y), width: tw, height: th), const Radius.circular(6));
      canvas.drawRRect(rr, _tile);
      if (settings.highContrast || !settings.reducedVfx) canvas.drawRRect(rr, _edge);
    }
    _paintHud(canvas); _paintJud(canvas); _paintAp(canvas);
  }

  void _paintHud(Canvas canvas) {
    final s = controller.score.score; final c = controller.combo.value; final a = controller.score.accuracy;
    if (_hud == null || s != _ls || c != _lc || (a - _la).abs() > 0.0005) {
      _ls = s; _lc = c; _la = a;
      _hud = TextPainter(textDirection: TextDirection.ltr, text: TextSpan(children: [
        TextSpan(text: '$s\n', style: const TextStyle(color: NeonPalette.text, fontSize: 22, fontWeight: FontWeight.w700)),
        TextSpan(text: 'COMBO $c   ${(a * 100).toStringAsFixed(1)}%', style: const TextStyle(color: NeonPalette.muted, fontSize: 12)),
      ]))..layout(maxWidth: size.x * 0.55);
    }
    _hud!.paint(canvas, const Offset(16, 20));
  }

  void _paintJud(Canvas canvas) {
    if (controller.lastJudgment == Judgment.none) return;
    if (_jud == null || controller.lastJudgment != _lj || (controller.lastDeltaMs - _ld).abs() > 0.5) {
      _lj = controller.lastJudgment; _ld = controller.lastDeltaMs;
      final color = switch (controller.lastJudgment) { Judgment.perfect => NeonPalette.text, Judgment.great => NeonPalette.accent, Judgment.good => NeonPalette.muted, Judgment.miss => NeonPalette.danger, Judgment.none => NeonPalette.muted };
      final label = controller.lastJudgment.label;
      final show = settings.showTimingNumbers || practiceMode;
      _jud = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.center, text: TextSpan(text: show ? '$label\n${controller.lastDeltaMs >= 0 ? '+' : ''}${controller.lastDeltaMs.toStringAsFixed(0)}ms' : label, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w700)))..layout();
    }
    _jud!.paint(canvas, Offset(size.x / 2 - _jud!.width / 2, hitLineY - 88));
  }

  void _paintAp(Canvas canvas) {
    if (!settings.autoPlay) return;
    _ap ??= TextPainter(textDirection: TextDirection.ltr, text: const TextSpan(text: 'AUTO PLAY ON', style: TextStyle(color: NeonPalette.accent, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)))..layout();
    _ap!.paint(canvas, Offset(size.x - _ap!.width - 16, 24));
  }
}
