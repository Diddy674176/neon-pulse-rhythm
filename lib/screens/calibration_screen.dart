import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../ui/neon_widgets.dart';
import '../vfx/neon_palette.dart';

/// Measures audio/touch latency offset using a flashing beat + tap.
/// Offset is stored and applied by TimingEngine (audio clock primary).
class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  final List<int> _deltas = [];
  Timer? _timer;
  int _beatIndex = 0;
  bool _flash = false;
  static const _intervalMs = 500;

  int get audioOffset => AppState.instance.settings.audioLatencyOffsetMs;
  int get touchOffset => AppState.instance.settings.touchLatencyOffsetMs;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: _intervalMs), (_) {
      setState(() {
        _flash = true;
        _beatIndex++;
      });
      HapticFeedback.selectionClick();
      Future<void>.delayed(const Duration(milliseconds: 80), () {
        if (mounted) setState(() => _flash = false);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onTap() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final phase = now % _intervalMs;
    final delta = phase > _intervalMs / 2 ? phase - _intervalMs : phase;
    setState(() {
      _deltas.add(delta);
      if (_deltas.length > 12) _deltas.removeAt(0);
    });
  }

  int get _suggestedTouch {
    if (_deltas.isEmpty) return touchOffset;
    final sorted = [..._deltas]..sort();
    return sorted[sorted.length ~/ 2];
  }

  Future<void> _apply() async {
    final s = AppState.instance.settings;
    s.touchLatencyOffsetMs = _suggestedTouch;
    await AppState.instance.persistSettings();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Touch offset set to ${s.touchLatencyOffsetMs} ms')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance.settings;
    return SafeNeonScaffold(
      title: 'CALIBRATION',
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Tap with each flash. Timing uses audio clock in-game;\n'
              'these offsets compensate device latency.',
              textAlign: TextAlign.center,
              style: TextStyle(color: NeonPalette.muted),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 60),
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _flash
                      ? NeonPalette.cyan.withOpacity(0.9)
                      : NeonPalette.bgElevated,
                  border: Border.all(color: NeonPalette.cyan, width: 3),
                  boxShadow: _flash
                      ? [
                          BoxShadow(
                            color: NeonPalette.cyan.withOpacity(0.6),
                            blurRadius: 40,
                          )
                        ]
                      : null,
                ),
                child: const Center(
                  child: Text(
                    'TAP',
                    style: TextStyle(
                      color: NeonPalette.text,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Samples: ${_deltas.length}  ·  Beats: $_beatIndex',
                style: const TextStyle(color: NeonPalette.muted)),
            Text(
              'Suggested touch offset: $_suggestedTouch ms',
              style: const TextStyle(color: NeonPalette.lime, fontSize: 16),
            ),
            const SizedBox(height: 16),
            NeonPanel(
              child: Column(
                children: [
                  Text('Audio latency offset: ${s.audioLatencyOffsetMs} ms',
                      style: const TextStyle(color: NeonPalette.text)),
                  Slider(
                    min: -100,
                    max: 100,
                    divisions: 200,
                    value: s.audioLatencyOffsetMs.toDouble(),
                    activeColor: NeonPalette.cyan,
                    onChanged: (v) {
                      setState(() => s.audioLatencyOffsetMs = v.round());
                    },
                    onChangeEnd: (_) => AppState.instance.persistSettings(),
                  ),
                  Text('Touch latency offset: ${s.touchLatencyOffsetMs} ms',
                      style: const TextStyle(color: NeonPalette.text)),
                  Slider(
                    min: -100,
                    max: 100,
                    divisions: 200,
                    value: s.touchLatencyOffsetMs.toDouble(),
                    activeColor: NeonPalette.magenta,
                    onChanged: (v) {
                      setState(() => s.touchLatencyOffsetMs = v.round());
                    },
                    onChangeEnd: (_) => AppState.instance.persistSettings(),
                  ),
                ],
              ),
            ),
            const Spacer(),
            NeonMenuButton(label: 'APPLY SUGGESTED TOUCH', onPressed: _apply),
          ],
        ),
      ),
    );
  }
}
