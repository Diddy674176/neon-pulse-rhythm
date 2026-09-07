class ComboTracker {
  int value = 0;
  int maxValue = 0;

  void hit() {
    value += 1;
    if (value > maxValue) maxValue = value;
  }

  void breakCombo() {
    value = 0;
  }

  double get multiplier {
    final m = 1.0 + (value ~/ 10) * 0.1;
    return m.clamp(1.0, 4.0);
  }
}
