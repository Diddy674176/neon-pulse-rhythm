enum NoteType { tap, hold, swipe }

enum SwipeDirection { up, down, left, right }

class ChartNote {
  ChartNote({
    required this.type,
    required this.lane,
    required this.timeMs,
    this.endTimeMs,
    this.direction,
    this.id,
  });

  final NoteType type;
  final int lane;
  final double timeMs;
  final double? endTimeMs;
  final SwipeDirection? direction;
  final String? id;

  double get durationMs =>
      type == NoteType.hold ? ((endTimeMs ?? timeMs) - timeMs) : 0;

  factory ChartNote.fromJson(Map<String, dynamic> json, {int index = 0}) {
    final typeStr = (json['type'] as String? ?? 'tap').toLowerCase();
    final type = switch (typeStr) {
      'hold' => NoteType.hold,
      'swipe' => NoteType.swipe,
      _ => NoteType.tap,
    };
    SwipeDirection? dir;
    if (json['direction'] != null) {
      dir = switch ((json['direction'] as String).toLowerCase()) {
        'down' => SwipeDirection.down,
        'left' => SwipeDirection.left,
        'right' => SwipeDirection.right,
        _ => SwipeDirection.up,
      };
    }
    return ChartNote(
      type: type,
      lane: json['lane'] as int? ?? 0,
      timeMs: (json['timeMs'] as num).toDouble(),
      endTimeMs: (json['endTimeMs'] as num?)?.toDouble(),
      direction: dir,
      id: json['id'] as String? ?? 'n$index',
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'lane': lane,
        'timeMs': timeMs,
        if (endTimeMs != null) 'endTimeMs': endTimeMs,
        if (direction != null) 'direction': direction!.name,
        if (id != null) 'id': id,
      };
}
