import 'dart:ui' as ui;
import 'package:flutter/scheduler.dart';
import '../settings/game_settings.dart';

class RefreshRateService {
  double? _hz;
  double get detectedHz => _hz ?? 60;

  void detect() {
    try {
      final views = ui.PlatformDispatcher.instance.views;
      if (views.isNotEmpty) {
        final hz = views.first.display.refreshRate;
        if (hz > 0) _hz = hz;
      }
    } catch (_) {
      _hz = 60;
    }
    _hz ??= 60;
  }

  int bucket() {
    final h = detectedHz;
    if (h >= 110) return 120;
    if (h >= 75) return 90;
    return 60;
  }

  Duration frameBudgetFor(PerformanceMode mode) {
    final target = switch (mode) {
      PerformanceMode.performance => bucket().clamp(60, 120),
      PerformanceMode.balanced => bucket() >= 90 ? 90 : 60,
      PerformanceMode.quality => 60,
      PerformanceMode.battery => 60,
    };
    return Duration(microseconds: (1e6 / target).round());
  }

  void applySchedulerHint(PerformanceMode mode) {
    SchedulerBinding.instance.platformDispatcher.onBeginFrame;
    detect();
  }
}
