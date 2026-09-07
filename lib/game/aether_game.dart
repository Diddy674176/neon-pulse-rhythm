import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import '../audio/audio_clock.dart';
import '../audio/sfx_service.dart';
import '../chart/chart_data.dart';
import '../chart/note.dart';
import '../gameplay/gameplay_controller.dart';
import '../haptics/haptics_service.dart';
import '../input/lane_input.dart';
import '../rhythm/judgment.dart';
import '../rhythm/timing_engine.dart';
import '../settings/game_settings.dart';
import '../vfx/neon_palette.dart';

class _HitFx {
  _HitFx({required this.lane, required this.x, required this.y, required this.judgment, required this.combo, this.milestone = false});
  final int lane; final double x; final double y; final Judgment judgment; final int combo; final bool milestone;
  double age = 0; static const life = 0.32;
  double get t => (age / life).clamp(0.0, 1.0); bool get dead => age >= life;
}

class AetherGame extends FlameGame {
  AetherGame({required this.chart, required this.clock, required this.settings, required this.timing, required this.haptics, this.sfx, this.practiceMode = false, this.onFinished});
  final ChartData chart; final AudioClock clock; final GameSettings settings; final TimingEngine timing; final HapticsService haptics;
  final SfxService? sfx; final bool practiceMode; final void Function()? onFinished;
  late GameplayController controller; bool _started = false; bool _finishNotified = false;
  final Paint _bg = Paint()..color = NeonPalette.bg; final Paint _lane = Paint();
  final Paint _div = Paint()..color = NeonPalette.laneDivider..strokeWidth = 1.5;
  final Paint _hit = Paint()..color = NeonPalette.hitLine..strokeWidth = 3;
  final Paint _band = Paint()..color = NeonPalette.hitZoneSoft; final Paint _tile = Paint()..color = NeonPalette.tile;
  final Paint _edge = Paint()..color = NeonPalette.tileEdge..style = PaintingStyle.stroke..strokeWidth = 1.5;
  final Paint _hold = Paint()..color = const Color(0xFF2A2A2A); final Paint _holdOn = Paint()..color = const Color(0xFF505050);
  final Paint _holdEdge = Paint()..color = const Color(0xFF6A6A6A)..style = PaintingStyle.stroke..strokeWidth = 1.5;
  final Paint _flash = Paint(); final Paint _press = Paint()..color = const Color(0x22000000);
  TextPainter? _hud; TextPainter? _jud; TextPainter? _swipeTip;
  int _ls = -1; int _lc = -1; double _la = -1; double _lm = -1; Judgment _lj = Judgment.none; double _ld = 0;
  final List<_HitFx> _fx = []; static const _fxCap = 6; double _judAge = 1; final Set<int> _pressedLanes = {};
  double _hudThrottle = 0; double _lastSfxAudioMs = -9999; bool _hudDirty = true;

  /// Web always prefers reduced decorative work for smoother frames.
  bool get _liteVfx => settings.reducedVfx || kIsWeb;

  bool get autoPlay => settings.autoPlay;
  set autoPlay(bool v) { settings.autoPlay = v; controller.autoPlay = v; }
  @override Color backgroundColor() => NeonPalette.bg;

  @override Future<void> onLoad() async {
    if (kIsWeb) settings.reducedVfx = true;
    controller = GameplayController(chart: chart, clock: clock, timing: timing, approachMs: 1600 / settings.noteSpeed, autoPlay: settings.autoPlay, onJudgment: _onJudgment);
  }

  void _onJudgment(note, Judgment j, double d) {
    if (!kIsWeb && (j == Judgment.perfect || !_liteVfx)) haptics.forJudgment(j.label);
    _playSfx(j);
    _judAge = 0;
    _hudDirty = true;
    if (_liteVfx && j != Judgment.perfect && j != Judgment.miss) {
      // Skip non-essential hit flashes when lite.
    } else {
      final lanes = laneCount;
      final lane = settings.handedness == Handedness.left ? (lanes - 1 - note.note.lane % lanes) : note.note.lane % lanes;
      final milestone = !_liteVfx && _isMilestone(controller.combo.value);
      if (_fx.length >= _fxCap) _fx.removeAt(0);
      _fx.add(_HitFx(lane: lane, x: laneX(lane), y: hitLineY, judgment: j, combo: controller.combo.value, milestone: milestone));
    }
  }

  void _playSfx(Judgment j) {
    final t = clock.currentTimeMs;
    final minGap = _liteVfx ? 55.0 : 28.0;
    if (t - _lastSfxAudioMs < minGap && j != Judgment.miss) return;
    if (_liteVfx && (j == Judgment.great || j == Judgment.good)) return;
    _lastSfxAudioMs = t;
    if (j == Judgment.miss) {
      sfx?.playMiss();
    } else {
      sfx?.playHit(j.label);
    }
  }

  bool _isMilestone(int c) => c == 10 || c == 25 || c == 50 || c == 100 || (c > 0 && c % 50 == 0);
  Future<void> start() async { _started = true; await clock.play(); }
  Future<void> restart() async { _finishNotified = false; _fx.clear(); _judAge = 1; _hudDirty = true; await clock.stop(); await clock.seek(0); await onLoad(); await clock.play(); _started = true; }

  int get laneCount => settings.laneCount.clamp(4, 6);
  double get hitLineY => size.y * 0.78;
  double get _topY => size.y * 0.08; double get _pad => size.x * 0.035; double get _gutter => 5.0;
  double get _slot => (size.x - _pad * 2) / laneCount;
  Rect laneRect(int lane) { final l = _pad + _slot * lane + _gutter; final r = _pad + _slot * (lane + 1) - _gutter; return Rect.fromLTRB(l, _topY, r, size.y * 0.93); }
  double laneX(int lane) => laneRect(lane).center.dx;
  double tileW(int lane) => (laneRect(lane).width * 0.94 * settings.noteSize).clamp(28.0, laneRect(lane).width);
  double tileH() => (54.0 * settings.noteSize).clamp(38.0, 76.0);
  int laneAt(Offset p) { final i = ((p.dx - _pad) / _slot).floor().clamp(0, laneCount - 1); return settings.handedness == Handedness.left ? (laneCount - 1 - i) : i; }

  void onPointerDown(Offset pos) {
    final lane = laneAt(pos); _pressedLanes.add(lane); final t = clock.currentTimeMs;
    final holdNear = controller.notes.any((n) => !n.resolved && n.note.type == NoteType.hold && n.note.lane == lane && timing.isInHitWindow(noteTimeMs: n.note.timeMs, rawAudioTimeMs: t));
    controller.handleInput(LaneInputEvent(kind: holdNear ? InputKind.holdStart : InputKind.tap, lane: lane, audioTimeMs: t));
  }
  void onPointerUp(Offset pos, int lane) { _pressedLanes.remove(lane); controller.handleInput(LaneInputEvent(kind: InputKind.holdEnd, lane: lane, audioTimeMs: clock.currentTimeMs)); }
  void onSwipe(Offset pos, SwipeDirection dir) => controller.handleInput(LaneInputEvent(kind: InputKind.swipe, lane: laneAt(pos), audioTimeMs: clock.currentTimeMs, direction: dir));

  @override void update(double dt) {
    super.update(dt); if (!_started) return;
    controller.autoPlay = settings.autoPlay; controller.tick();
    _judAge = math.min(_judAge + dt, 1.0);
    _hudThrottle += dt;
    for (final f in _fx) { f.age += dt; } _fx.removeWhere((f) => f.dead);
    if (controller.finished && !_finishNotified) { _finishNotified = true; onFinished?.call(); }
  }

  @override void render(Canvas canvas) {
    super.render(canvas); canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _bg);
    final lanes = laneCount;
    for (var i = 0; i < lanes; i++) {
      final rect = laneRect(i);
      _lane.color = settings.highContrast ? (i.isEven ? const Color(0xFFF2F2F2) : const Color(0xFFE8E8E8)) : NeonPalette.laneColors[i % NeonPalette.laneColors.length];
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), _lane);
      if (_pressedLanes.contains(i)) canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), _press);
      if (i > 0) { final x = _pad + _slot * i; canvas.drawLine(Offset(x, _topY), Offset(x, hitLineY + 28), _div); }
    }
    final th = tileH();
    canvas.drawRect(Rect.fromLTRB(_pad, hitLineY - th * 0.5, size.x - _pad, hitLineY + th * 0.45), _band);
    canvas.drawLine(Offset(_pad, hitLineY), Offset(size.x - _pad, hitLineY), _hit);
    final t = controller.audioTimeMs; final approach = controller.approachMs; final travel = hitLineY - _topY;
    final viewTop = -th * 2; final viewBot = size.y + th;
    for (final n in controller.visibleNotes()) {
      final note = n.note;
      final lane = settings.handedness == Handedness.left ? (lanes - 1 - note.lane % lanes) : note.lane % lanes;
      final cx = laneX(lane); final tw = tileW(lane);
      final progress = ((note.timeMs - t) / approach).clamp(-0.35, 1.0); final y = hitLineY - progress * travel;

      if (note.type == NoteType.hold) {
        final ep = (((note.endTimeMs ?? note.timeMs) - t) / approach).clamp(-0.35, 1.0);
        final endY = hitLineY - ep * travel;
        final top = math.min(y, endY);
        final bot = math.max(y, endY);
        if (bot < viewTop || top > viewBot) continue;
        final bodyH = math.max(bot - top, th * 1.6);
        final bodyPaint = n.holdActive ? _holdOn : _hold;
        final body = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, (top + bot) / 2), width: tw * 0.78, height: bodyH),
          const Radius.circular(9),
        );
        canvas.drawRRect(body, bodyPaint);
        if (!_liteVfx || n.holdActive) canvas.drawRRect(body, _holdEdge);
        final headH = th * 1.35;
        final headScale = n.holdActive ? 1.05 : 1.0;
        final head = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, y), width: tw * headScale, height: headH * headScale),
          const Radius.circular(8),
        );
        canvas.drawRRect(head, _tile);
        if (settings.highContrast || !_liteVfx) canvas.drawRRect(head, _edge);
        continue;
      }

      if (y < viewTop || y > viewBot) continue;

      final rr = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, y), width: tw, height: th), const Radius.circular(7));
      canvas.drawRRect(rr, _tile);
      if (settings.highContrast || !_liteVfx) canvas.drawRRect(rr, _edge);
      if (note.type == NoteType.swipe) {
        _swipeTip ??= TextPainter(
          textDirection: TextDirection.ltr,
          text: const TextSpan(text: '▲', style: TextStyle(color: Color(0x88FFFFFF), fontSize: 14)),
        )..layout();
        _swipeTip!.paint(canvas, Offset(cx - _swipeTip!.width / 2, y - _swipeTip!.height / 2));
      }
    }
    _paintFx(canvas, th); _paintHud(canvas); _paintJud(canvas);
  }

  void _paintFx(Canvas canvas, double th) {
    for (final f in _fx) {
      final fade = 1.0 - f.t; if (fade <= 0) continue;
      if (!_liteVfx || f.judgment == Judgment.perfect) {
        final punch = 1.0 + (1.0 - f.t) * 0.14; final tw = tileW(f.lane) * punch;
        final color = switch (f.judgment) {
          Judgment.perfect => const Color(0xEEFFFFFF), Judgment.great => const Color(0xCC7EB6FF),
          Judgment.good => const Color(0x99B0B0B0), Judgment.miss => const Color(0x99E85D5D), Judgment.none => const Color(0x00FFFFFF),
        };
        _flash.color = color.withValues(alpha: fade * 0.85);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(f.x, f.y), width: tw, height: th * punch), const Radius.circular(7)), _flash);
      }
      if (!_liteVfx && f.milestone && f.combo > 0) {
        final pop = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.center, text: TextSpan(text: '${f.combo} COMBO', style: TextStyle(color: NeonPalette.accent.withValues(alpha: fade), fontSize: 16 + (1 - f.t) * 6, fontWeight: FontWeight.w800, letterSpacing: 1.2)))..layout();
        pop.paint(canvas, Offset(size.x / 2 - pop.width / 2, hitLineY - 130 - f.t * 20));
      }
    }
  }

  void _paintHud(Canvas canvas) {
    final s = controller.score.score; final c = controller.combo.value; final a = controller.score.accuracy; final m = controller.score.multiplier;
    final changed = s != _ls || c != _lc || (a - _la).abs() > 0.002 || (m - _lm).abs() > 0.05;
    if (_hud == null || (_hudDirty && changed && (_hudThrottle >= 0.12 || c != _lc || s != _ls))) {
      _ls = s; _lc = c; _la = a; _lm = m; _hudThrottle = 0; _hudDirty = false;
      _hud = TextPainter(textDirection: TextDirection.ltr, text: TextSpan(children: [
        TextSpan(text: '$s\n', style: const TextStyle(color: NeonPalette.text, fontSize: 24, fontWeight: FontWeight.w800, height: 1.1)),
        TextSpan(text: '×${m.toStringAsFixed(1)}   COMBO $c   ${(a * 100).toStringAsFixed(1)}%', style: const TextStyle(color: NeonPalette.muted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
      ]))..layout(maxWidth: size.x * 0.6);
    }
    _hud?.paint(canvas, const Offset(16, 18));
  }

  void _paintJud(Canvas canvas) {
    if (controller.lastJudgment == Judgment.none || _judAge >= 1.0) return;
    if (_jud == null || controller.lastJudgment != _lj || (controller.lastDeltaMs - _ld).abs() > 0.5) {
      _lj = controller.lastJudgment; _ld = controller.lastDeltaMs;
      final color = switch (controller.lastJudgment) { Judgment.perfect => NeonPalette.perfect, Judgment.great => NeonPalette.great, Judgment.good => NeonPalette.good, Judgment.miss => NeonPalette.danger, Judgment.none => NeonPalette.muted };
      final label = controller.lastJudgment.label; final show = settings.showTimingNumbers || practiceMode;
      _jud = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.center, text: TextSpan(text: show ? '$label\n${controller.lastDeltaMs >= 0 ? '+' : ''}${controller.lastDeltaMs.toStringAsFixed(0)}ms' : label, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 1.5, height: 1.15)))..layout();
    }
    final punch = 1.0 + (1.0 - _easeOut(_judAge)) * 0.18; final fade = (1.0 - _judAge).clamp(0.0, 1.0);
    canvas.save(); canvas.translate(size.x / 2, hitLineY - 92); canvas.scale(punch); canvas.translate(-_jud!.width / 2, -_jud!.height / 2);
    canvas.saveLayer(Rect.fromLTWH(0, 0, _jud!.width, _jud!.height), Paint()..color = Color.fromRGBO(255, 255, 255, fade));
    _jud!.paint(canvas, Offset.zero); canvas.restore(); canvas.restore();
  }
}

double _easeOut(double t) => 1 - (1 - t) * (1 - t);
