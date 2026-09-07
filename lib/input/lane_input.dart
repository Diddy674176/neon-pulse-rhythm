import '../chart/note.dart';

enum InputKind { tap, holdStart, holdEnd, swipe }

class LaneInputEvent {
  LaneInputEvent({
    required this.kind,
    required this.lane,
    required this.audioTimeMs,
    this.direction,
  });

  final InputKind kind;
  final int lane;
  final double audioTimeMs;
  final SwipeDirection? direction;
}

typedef LaneInputCallback = void Function(LaneInputEvent event);
