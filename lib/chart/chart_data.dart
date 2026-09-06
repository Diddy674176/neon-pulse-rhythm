import 'note.dart';

class ChartData {
  ChartData({
    required this.songId,
    required this.title,
    required this.artist,
    required this.bpm,
    required this.durationMs,
    required this.audioAsset,
    required this.notes,
    this.offsetMs = 0,
    this.laneCount = 4,
    this.difficulty = 'Normal',
  });

  final String songId;
  final String title;
  final String artist;
  final double bpm;
  final double durationMs;
  final String audioAsset;
  final List<ChartNote> notes;
  final double offsetMs;
  final int laneCount;
  final String difficulty;

  double get beatMs => 60000.0 / bpm;

  factory ChartData.fromJson(Map<String, dynamic> json) {
    final rawNotes = (json['notes'] as List<dynamic>? ?? []);
    return ChartData(
      songId: json['songId'] as String? ?? 'unknown',
      title: json['title'] as String? ?? 'Untitled',
      artist: json['artist'] as String? ?? 'Unknown',
      bpm: (json['bpm'] as num?)?.toDouble() ?? 120,
      durationMs: (json['durationMs'] as num?)?.toDouble() ?? 0,
      audioAsset: json['audio'] as String? ?? '',
      offsetMs: (json['offsetMs'] as num?)?.toDouble() ?? 0,
      laneCount: json['laneCount'] as int? ?? 4,
      difficulty: json['difficulty'] as String? ?? 'Normal',
      notes: [
        for (var i = 0; i < rawNotes.length; i++)
          ChartNote.fromJson(Map<String, dynamic>.from(rawNotes[i] as Map), index: i),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'songId': songId,
        'title': title,
        'artist': artist,
        'bpm': bpm,
        'offsetMs': offsetMs,
        'durationMs': durationMs,
        'audio': audioAsset,
        'laneCount': laneCount,
        'difficulty': difficulty,
        'notes': notes.map((n) => n.toJson()).toList(),
      };
}
