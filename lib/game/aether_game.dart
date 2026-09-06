import 'dart:ui';
import 'package:flame/game.dart';
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
import 'dart:ui' as ui;

/// Flame render surface. Input stamped with audio clock from Flutter gestures.
class AetherGame extends FlameGame {
  AetherGame({
    required this.chart,
    required this.clock,
    required this.settings,
    required this.timing,
    required this.haptics,
    this.practiceMode = false,
    this.onFinished,
  });

  final ChartData chart;
  final AudioClock clock;
  final GameSettings settings;
  final TimingEngine timing;
  final HapticsService haptics;
  final bool practiceMode;
  final void Function()? onFinished;

  late GameplayController controller;
  bool _started = false;
  bool _finishNotified = false;

  @override
  Color backgroundColor() => NeonPalette.bg;

  @override
  Future<void> onLoad() async {
    controller = GameplayController(
      chart: chart,
      clock: clock,
      timing: timing,
      approachMs: 1600 / settings.noteSpeed,
      onJudgment: (n, j, d) => haptics.forJudgment(j.label),
    );
  }

  Future<void> start() async {
    _started = true;
    await clock.play();
  }

  Future<void> restart() async {
    _finishNotified = false;
    await clock.stop();
    await clock.seek(0);
    await onLoad();
    await clock.play();
    _started = true;
  }

  int get laneCount => settings.laneCount.clamp(4, 6);
  double get hitLineY => size.y * 0.82;

  double laneX(int lane) {
    final pad = size.x * 0.08;
    final slot = (size.x - pad * 2) / laneCount;
    return pad + slot * (lane + 0.5);
  }

  int laneAt(Offset p) {
    final pad = size.x * 0.08;
    final slot = (size.x - pad * 2) / laneCount;
    final idx = ((p.dx - pad) / slot).floor().clamp(0, laneCount - 1);
    return settings.handedness == Handedness.left ? (laneCount - 1 - idx) : idx;
  }

  void onPointerDown(Offset pos) {
    final lane = laneAt(pos);
    final t = clock.currentTimeMs;
    final holdNear = controller.notes.any((n) =>
        !n.resolved &&
        n.note.type == NoteType.hold &&
        n.note.lane == lane &&
        timing.isInHitWindow(noteTimeMs: n.note.timeMs, rawAudioTimeMs: t));
    controller.handleInput(LaneInputEvent(
      kind: holdNear ? InputKind.holdStart : InputKind.tap,
      lane: lane,
      audioTimeMs: t,
    ));
  }

  void onPointerUp(Offset pos, int lane) {
    controller.handleInput(LaneInputEvent(
      kind: InputKind.holdEnd,
      lane: lane,
      audioTimeMs: clock.currentTimeMs,
    ));
  }

  void onSwipe(Offset pos, SwipeDirection dir) {
    controller.handleInput(LaneInputEvent(
      kind: InputKind.swipe,
      lane: laneAt(pos),
      audioTimeMs: clock.currentTimeMs,
      direction: dir,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_started) return;
    controller.tick();
    if (controller.finished && !_finishNotified) {
      _finishNotified = true;
      onFinished?.call();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = Offset.zero & Size(size.x, size.y);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.y), const [
          Color(0xFF12062A),
          NeonPalette.bg,
          Color(0xFF061018),
        ]),
    );
    for (var i = 0; i < laneCount; i++) {
      final x = laneX(i);
      final color = NeonPalette.laneColors[i % NeonPalette.laneColors.length]
          .withOpacity(settings.highContrast ? 0.55 : 0.22);
      canvas.drawLine(Offset(x, size.y * 0.08), Offset(x, hitLineY),
          Paint()..color = color..strokeWidth = 2);
    }
    canvas.drawLine(
      Offset(size.x * 0.05, hitLineY),
      Offset(size.x * 0.95, hitLineY),
      Paint()..color = NeonPalette.cyan.withOpacity(0.85)..strokeWidth = 3,
    );
    final t = controller.audioTimeMs;
    final approach = controller.approachMs;
    for (final n in controller.visibleNotes()) {
      final note = n.note;
      final lane = settings.handedness == Handedness.left
          ? (laneCount - 1 - note.lane % laneCount)
          : note.lane % laneCount;
      final x = laneX(lane);
      final progress = ((note.timeMs - t) / approach).clamp(-0.2, 1.0);
      final y = hitLineY - progress * (hitLineY - size.y * 0.1);
      final color = NeonPalette.laneColors[lane % NeonPalette.laneColors.length];
      final radius = 18.0 * settings.noteSize;
      if (note.type == NoteType.hold) {
        final endProgress =
            (((note.endTimeMs ?? note.timeMs) - t) / approach).clamp(-0.2, 1.0);
        final yEnd = hitLineY - endProgress * (hitLineY - size.y * 0.1);
        canvas.drawLine(
          Offset(x, y),
          Offset(x, yEnd),
          Paint()
            ..color = color.withOpacity(n.holdActive ? 0.7 : 0.35)
            ..strokeWidth = radius * 0.9
            ..strokeCap = StrokeCap.round,
        );
      }
      final fill = Paint()..color = color.withOpacity(0.9);
      if (note.type == NoteType.swipe) {
        final path = Path()
          ..moveTo(x, y - radius)
          ..lineTo(x + radius, y)
          ..lineTo(x, y + radius)
          ..lineTo(x - radius, y)
          ..close();
        canvas.drawPath(path, fill);
      } else {
        canvas.drawCircle(Offset(x, y), radius, fill);
      }
    }
    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(children: [
        TextSpan(
          text: '${controller.score.score}\n',
          style: const TextStyle(
              color: NeonPalette.cyan, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        TextSpan(
          text:
              'x${controller.combo.multiplier.toStringAsFixed(1)}  COMBO ${controller.combo.value}\n',
          style: const TextStyle(
              color: NeonPalette.magenta, fontSize: 14, fontWeight: FontWeight.w700),
        ),
        TextSpan(
          text: 'ACC ${(controller.score.accuracy * 100).toStringAsFixed(1)}%',
          style: const TextStyle(color: NeonPalette.muted, fontSize: 12),
        ),
      ]),
    )..layout(maxWidth: size.x);
    tp.paint(canvas, const Offset(16, 24));
    if (controller.lastJudgment != Judgment.none) {
      final color = switch (controller.lastJudgment) {
        Judgment.perfect => NeonPalette.lime,
        Judgment.great => NeonPalette.cyan,
        Judgment.good => NeonPalette.amber,
        Judgment.miss => NeonPalette.danger,
        Judgment.none => NeonPalette.muted,
      };
      final label = controller.lastJudgment.label;
      final jtp = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: settings.showTimingNumbers || practiceMode
              ? '$label\n${controller.lastDeltaMs >= 0 ? '+' : ''}${controller.lastDeltaMs.toStringAsFixed(0)}ms'
              : label,
          style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w900),
        ),
      )..layout();
      jtp.paint(canvas, Offset(size.x / 2 - jtp.width / 2, hitLineY - 90));
    }
  }
}
