import 'package:flutter/services.dart';

/// Map keyboard keys to lane indices for web/desktop play.
int? laneForKey(LogicalKeyboardKey key, int laneCount) {
  final n = laneCount.clamp(4, 6);
  const digitMap = <LogicalKeyboardKey, int>{
    LogicalKeyboardKey.digit1: 0,
    LogicalKeyboardKey.digit2: 1,
    LogicalKeyboardKey.digit3: 2,
    LogicalKeyboardKey.digit4: 3,
    LogicalKeyboardKey.digit5: 4,
    LogicalKeyboardKey.digit6: 5,
    LogicalKeyboardKey.numpad1: 0,
    LogicalKeyboardKey.numpad2: 1,
    LogicalKeyboardKey.numpad3: 2,
    LogicalKeyboardKey.numpad4: 3,
    LogicalKeyboardKey.numpad5: 4,
    LogicalKeyboardKey.numpad6: 5,
  };
  if (digitMap.containsKey(key)) {
    final lane = digitMap[key]!;
    return lane < n ? lane : null;
  }
  late final List<LogicalKeyboardKey> keys;
  if (n <= 4) {
    keys = [
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.keyF,
      LogicalKeyboardKey.keyJ,
      LogicalKeyboardKey.keyK,
    ];
  } else if (n == 5) {
    keys = [
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.keyF,
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.keyJ,
      LogicalKeyboardKey.keyK,
    ];
  } else {
    keys = [
      LogicalKeyboardKey.keyS,
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.keyF,
      LogicalKeyboardKey.keyJ,
      LogicalKeyboardKey.keyK,
      LogicalKeyboardKey.keyL,
    ];
  }
  final idx = keys.indexOf(key);
  return idx >= 0 ? idx : null;
}
