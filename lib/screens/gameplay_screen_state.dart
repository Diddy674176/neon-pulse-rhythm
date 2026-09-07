part of 'gameplay_screen.dart';

class _GameplayScreenState extends State<GameplayScreen> {
  AetherGame? _game;
  AudioClock? _clock;
  bool _loading = true;
  String? _error;
  final Map<int, Offset> _downs = {};
  final Map<int, int> _lanes = {};
  Timer? _posPoll;
  /// In-run autoplay label — ValueNotifier avoids rebuilding GameWidget on toggle.
  late final ValueNotifier<bool> _autoPlayOn;

  @override
  void initState() {
    super.initState();
    _autoPlayOn = ValueNotifier(AppState.instance.settings.autoPlay);
    _boot();
  }

  Future<void> _boot() async {
    try {
      final app = AppState.instance;
      // Web: keep reduced VFX on for smoother frames.
      if (kIsWeb) {
        app.settings.reducedVfx = true;
      }
      final chart = await ChartLoader().loadForSong(
        widget.song,
        imported: widget.song.isImported ? app.catalog.imported : null,
      );
      final timing = TimingEngine(
        audioLatencyOffsetMs: app.settings.audioLatencyOffsetMs,
        touchLatencyOffsetMs: app.settings.touchLatencyOffsetMs,
      );
      AudioClock clock;
      if (app.audio != null) {
        final audio = app.audio!;
        try {
          Uint8List? importBytes;
          if (widget.song.isImported && kIsWeb) {
            importBytes =
                await app.catalog.imported.readAudioBytes(widget.song);
          }
          await audio.loadSongAudio(
            audioPath: widget.song.audioPath,
            isImported: widget.song.isImported,
            bytes: importBytes,
          );
          clock = audio;
          _posPoll = Timer.periodic(const Duration(milliseconds: 32), (_) {
            audio.refreshPosition();
          });
        } catch (_) {
          if (widget.song.isImported) rethrow;
          clock = SimulatedAudioClock();
        }
      } else {
        if (widget.song.isImported) {
          throw StateError('Audio service unavailable for imported track.');
        }
        clock = SimulatedAudioClock();
      }
      _clock = clock;
      _game = AetherGame(
        chart: chart,
        clock: clock,
        settings: app.settings,
        timing: timing,
        haptics: app.haptics,
        sfx: app.sfx,
        practiceMode: widget.practice,
        onFinished: _onFinished,
      );
      setState(() => _loading = false);
      await Future<void>.delayed(const Duration(milliseconds: 200));
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
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ResultsScreen(
          song: widget.song,
          score: score,
          practice: widget.practice,
        ),
        transitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  Future<void> _restart() async {
    await _game?.restart();
    if (_clock is SimulatedAudioClock) {
      await _startSimulated(_clock as SimulatedAudioClock);
    }
  }

  void _toggleAutoPlay() {
    final s = AppState.instance.settings;
    s.autoPlay = !s.autoPlay;
    _game?.autoPlay = s.autoPlay;
    _autoPlayOn.value = s.autoPlay;
    AppState.instance.persistSettings();
    // Do NOT setState — keeps GameWidget from rebuilding mid-run.
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (_game == null) return KeyEventResult.ignored;
    final lane = laneForKey(event.logicalKey, _game!.laneCount);
    if (lane == null) return KeyEventResult.ignored;
    final x = _game!.laneX(lane);
    final y = _game!.hitLineY;
    final pos = Offset(x, y);
    if (event is KeyDownEvent) {
      _game!.onPointerDown(pos);
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent) {
      _game!.onPointerUp(pos, lane);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _posPoll?.cancel();
    _autoPlayOn.dispose();
    _clock?.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: NeonPalette.bg,
        body: Center(child: CircularProgressIndicator(color: NeonPalette.accent)),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: NeonPalette.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!, style: const TextStyle(color: NeonPalette.danger)),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: NeonPalette.bg,
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: SafeArea(
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
                    final lane =
                        _lanes.remove(e.pointer) ?? _game!.laneAt(e.localPosition);
                    final start = _downs.remove(e.pointer);
                    if (start != null) {
                      final delta = e.localPosition - start;
                      if (delta.distance >= 28) {
                        final dir = delta.dy.abs() > delta.dx.abs()
                            ? (delta.dy < 0
                                ? SwipeDirection.up
                                : SwipeDirection.down)
                            : (delta.dx < 0
                                ? SwipeDirection.left
                                : SwipeDirection.right);
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
                top: 4,
                left: 4,
                child: IconButton(
                  onPressed: () {
                    _clock?.pause();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close, color: NeonPalette.muted),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Single in-run Auto Play toggle (no canvas duplicate).
                    ValueListenableBuilder<bool>(
                      valueListenable: _autoPlayOn,
                      builder: (_, autoOn, __) => TextButton(
                        onPressed: _toggleAutoPlay,
                        style: TextButton.styleFrom(
                          foregroundColor:
                              autoOn ? NeonPalette.accent : NeonPalette.muted,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        child: Text(
                          autoOn ? 'AUTO PLAY ON' : 'AUTO PLAY OFF',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    if (widget.practice) ...[
                      TextButton(
                        onPressed: _restart,
                        child: const Text('RESTART',
                            style: TextStyle(color: NeonPalette.text, fontSize: 12)),
                      ),
                      TextButton(
                        onPressed: () {
                          final s = AppState.instance.settings;
                          s.showTimingNumbers = !s.showTimingNumbers;
                          // Timing overlay is read from settings each paint — no setState.
                        },
                        child: const Text('TIMING',
                            style: TextStyle(color: NeonPalette.muted, fontSize: 12)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
