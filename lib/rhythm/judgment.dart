/// Hit judgment tiers for AETHER BEAT.
/// Windows are half-widths in milliseconds around the note time.
enum Judgment {
  perfect,
  great,
  good,
  miss,
  none,
}

extension JudgmentX on Judgment {
  String get label {
    switch (this) {
      case Judgment.perfect:
        return 'PERFECT';
      case Judgment.great:
        return 'GREAT';
      case Judgment.good:
        return 'GOOD';
      case Judgment.miss:
        return 'MISS';
      case Judgment.none:
        return '';
    }
  }

  int get scoreBase {
    switch (this) {
      case Judgment.perfect:
        return 1000;
      case Judgment.great:
        return 700;
      case Judgment.good:
        return 300;
      case Judgment.miss:
      case Judgment.none:
        return 0;
    }
  }

  double get accuracyWeight {
    switch (this) {
      case Judgment.perfect:
        return 1.0;
      case Judgment.great:
        return 0.7;
      case Judgment.good:
        return 0.3;
      case Judgment.miss:
      case Judgment.none:
        return 0.0;
    }
  }
}

/// Configurable judgment windows (milliseconds, absolute delta).
class JudgmentWindows {
  const JudgmentWindows({
    this.perfectMs = 25,
    this.greatMs = 50,
    this.goodMs = 90,
  });

  final int perfectMs;
  final int greatMs;
  final int goodMs;

  static const JudgmentWindows standard = JudgmentWindows();
}
