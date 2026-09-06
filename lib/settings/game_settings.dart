enum PerformanceMode { performance, balanced, quality, battery }

enum Handedness { right, left }

class GameSettings {
  GameSettings({
    this.masterVolume = 1.0,
    this.musicVolume = 0.9,
    this.sfxVolume = 0.8,
    this.hapticsEnabled = true,
    this.performanceMode = PerformanceMode.balanced,
    this.audioLatencyOffsetMs = 0,
    this.touchLatencyOffsetMs = 0,
    this.laneCount = 4,
    this.noteSpeed = 1.0,
    this.noteSize = 1.0,
    this.highContrast = false,
    this.handedness = Handedness.right,
    this.showTimingNumbers = false,
    this.practiceSpeed = 1.0,
  });

  double masterVolume;
  double musicVolume;
  double sfxVolume;
  bool hapticsEnabled;
  PerformanceMode performanceMode;
  int audioLatencyOffsetMs;
  int touchLatencyOffsetMs;
  int laneCount;
  double noteSpeed;
  double noteSize;
  bool highContrast;
  Handedness handedness;
  bool showTimingNumbers;
  double practiceSpeed;

  int get targetFpsHint {
    switch (performanceMode) {
      case PerformanceMode.performance:
        return 120;
      case PerformanceMode.balanced:
        return 90;
      case PerformanceMode.quality:
        return 60;
      case PerformanceMode.battery:
        return 60;
    }
  }

  Map<String, dynamic> toJson() => {
        'masterVolume': masterVolume,
        'musicVolume': musicVolume,
        'sfxVolume': sfxVolume,
        'hapticsEnabled': hapticsEnabled,
        'performanceMode': performanceMode.name,
        'audioLatencyOffsetMs': audioLatencyOffsetMs,
        'touchLatencyOffsetMs': touchLatencyOffsetMs,
        'laneCount': laneCount,
        'noteSpeed': noteSpeed,
        'noteSize': noteSize,
        'highContrast': highContrast,
        'handedness': handedness.name,
        'showTimingNumbers': showTimingNumbers,
        'practiceSpeed': practiceSpeed,
      };

  factory GameSettings.fromJson(Map<String, dynamic> j) {
    PerformanceMode mode = PerformanceMode.balanced;
    for (final m in PerformanceMode.values) {
      if (m.name == j['performanceMode']) mode = m;
    }
    Handedness hand = Handedness.right;
    for (final h in Handedness.values) {
      if (h.name == j['handedness']) hand = h;
    }
    return GameSettings(
      masterVolume: (j['masterVolume'] as num?)?.toDouble() ?? 1.0,
      musicVolume: (j['musicVolume'] as num?)?.toDouble() ?? 0.9,
      sfxVolume: (j['sfxVolume'] as num?)?.toDouble() ?? 0.8,
      hapticsEnabled: j['hapticsEnabled'] as bool? ?? true,
      performanceMode: mode,
      audioLatencyOffsetMs: j['audioLatencyOffsetMs'] as int? ?? 0,
      touchLatencyOffsetMs: j['touchLatencyOffsetMs'] as int? ?? 0,
      laneCount: j['laneCount'] as int? ?? 4,
      noteSpeed: (j['noteSpeed'] as num?)?.toDouble() ?? 1.0,
      noteSize: (j['noteSize'] as num?)?.toDouble() ?? 1.0,
      highContrast: j['highContrast'] as bool? ?? false,
      handedness: hand,
      showTimingNumbers: j['showTimingNumbers'] as bool? ?? false,
      practiceSpeed: (j['practiceSpeed'] as num?)?.toDouble() ?? 1.0,
    );
  }

  GameSettings copy() => GameSettings.fromJson(toJson());
}
