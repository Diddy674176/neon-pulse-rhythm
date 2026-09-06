import 'package:flutter/services.dart';

class HapticsService {
  HapticsService({this.enabled = true});
  bool enabled;
  Future<void> light() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
  }
  Future<void> medium() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
  }
  Future<void> heavy() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
  }
  Future<void> forJudgment(String label) async {
    if (!enabled) return;
    switch (label) {
      case 'PERFECT':
        await medium();
        break;
      case 'GREAT':
        await light();
        break;
      case 'MISS':
        await heavy();
        break;
      default:
        await light();
    }
  }
}
