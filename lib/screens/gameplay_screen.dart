import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../app_state.dart';
import '../audio/audio_clock.dart';
import '../chart/chart_loader.dart';
import '../chart/note.dart';
import '../game/aether_game.dart';
import '../rhythm/timing_engine.dart';
import '../song/song_catalog.dart';
import '../vfx/neon_palette.dart';
import 'results_screen.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key, required this.song, required this.practice});
  final SongMeta song;
  final bool practice;
  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  AetherGame? _game;
  AudioClock? _clock;
  bool _loading = true;
  String? _error;
  final Map<int, Offset> _downs = {};
  final Map<int, int> _lanes = {};
  Timer? _posPoll;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final app = AppState.instance;
      final chart = await ChartLoader().loadAsset(widget.song.chartPath);
      final timing = TimingEngine(
        audioLatencyOffsetMs: app.settings.audioLatencyOffsetMs,
        touchLatencyOffsetMs: app.settings.touchLatencyOffsetMs,
      );
      AudioClock clock;
      if (app.audio != null) {
        final audio = app.audio!;
        try {
          await audio.loadAssetOrB64(widget.song.audioPath);
          clock = audio;
          _posPoll = Timer.periodic(const Duration(milliseconds: 8), (_) {
            audio.refreshPosition();
          });
        } catch (_) {
          clock = SimulatedAudioClock();
        }
      } else {
        clock = SimulatedAudioClock();
      }
      _clock = clock;
      _game = AetherGame(
        chart: chart,
        clock: clock,
        settings: app.settings,
        timing: timing,
        haptics: app.haptics,
        practiceMode: widget.practice,
        onFinished: _onFinished,
      );
      setState(() => _loading = false);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await _game!.start();
      if (clock is SimulatedAudioClock) await _startSimulated(clock);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _startSimulated(SimulatedAudioClock clock) async {
    await clock.play();
    SchedulerBinding.instance.scheduleFrameCallback((_) {});
    Timer.periodic(const Duration(milliseconds: 8), (t) {
      if (!mounted || _game == null) {
        t.cancel();
        return;
      }
      if (!clock.isPlaying) return;
      clock.advance(8 * AppState.instance.settings.practiceSpeed);
      if (clock.currentTimeMs > (_game!.controller.chart.durationMs + 800)) {
        t.cancel();
      }
    });
  }

  void _onFinished() {
    if (!mounted || _game == null) return;
    final score = _game!.controller.score;
    AppState.instance.save.recordScore(widget.song.id, score.toJson());
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          song: widget.song,
          score: score,
          practice: widget.practice,
        ),
      ),
    );
  }

  Future<void> _restart() async {
    await _game?.restart();
    if (_clock is SimulatedAudioClock) {
      await _startSimulated(_clock as SimulatedAudioClock);
    }
  }

  @override
  void dispose() {
    _posPoll?.cancel();
    _clock?.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: NeonPalette.bg,
        body: Center(child: CircularProgressIndicator(color: NeonPalette.cyan)),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: NeonPalette.bg,
        body: Center(child: Text(_error!, style: const TextStyle(color: NeonPalette.danger))),
      );
    }
    return Scaffold(
      backgroundColor: NeonPalette.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) {
                  _downs[e.pointer] = e.localPosition;
                  final lane = _game!.laneAt(e.localPosition);
                  _lanes[e.pointer] = lane;
                  _game!.onPointerDown(e.localPosition);
                },
                onPointerUp: (e) {
                  final lane = _lanes.remove(e.pointer) ?? _game!.laneAt(e.localPosition);
                  final start = _downs.remove(e.pointer);
                  if (start != null) {
                    final delta = e.localPosition - start;
                    if (delta.distance >= 28) {
                      final dir = delta.dy.abs() > delta.dx.abs()
                          ? (delta.dy < 0 ? SwipeDirection.up : SwipeDirection.down)
                          : (delta.dx < 0 ? SwipeDirection.left : SwipeDirection.right);
                      _game!.onSwipe(start, dir);
                    }
                  }
                  _game!.onPointerUp(e.localPosition, lane);
                },
                onPointerCancel: (e) {
                  final lane = _lanes.remove(e.pointer);
                  _downs.remove(e.pointer);
                  if (lane != null) _game!.onPointerUp(e.localPosition, lane);
                },
                child: GameWidget(game: _game!),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () {
                  _clock?.pause();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.close, color: NeonPalette.muted),
              ),
            ),
            if (widget.practice)
              Positioned(
                top: 8,
                right: 8,
                child: Row(children: [
                  TextButton(
                    onPressed: _restart,
                    child: const Text('RESTART', style: TextStyle(color: NeonPalette.cyan)),
                  ),
                  TextButton(
                    onPressed: () {
                      final s = AppState.instance.settings;
                      s.showTimingNumbers = !s.showTimingNumbers;
                      setState(() {});
                    },
                    child: const Text('TIMING', style: TextStyle(color: NeonPalette.magenta)),
                  ),
                  PopupMenuButton<double>(
                    color: NeonPalette.bgElevated,
                    initialValue: AppState.instance.settings.practiceSpeed,
                    onSelected: (v) {
                      AppState.instance.settings.practiceSpeed = v;
                      setState(() {});
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 0.5, child: Text('0.5x (stub)')),
                      PopupMenuItem(value: 0.75, child: Text('0.75x (stub)')),
                      PopupMenuItem(value: 1.0, child: Text('1.0x')),
                    ],
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('SPEED', style: TextStyle(color: NeonPalette.amber)),
                    ),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}
