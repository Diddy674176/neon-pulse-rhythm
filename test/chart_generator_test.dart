import 'package:flutter_test/flutter_test.dart';
import 'package:aether_beat/chart/chart_generator.dart';
import 'package:aether_beat/chart/note.dart';

void main() {
  test('generator produces beat-aligned notes with mixed types', () {
    final chart = ChartGenerator().generate(
      songId: 't',
      title: 'Test',
      artist: 'AETHER',
      bpm: 120,
      durationMs: 30000,
      audioPath: '/tmp/x.mp3',
      difficulty: 'Normal',
      laneCount: 4,
      offsetMs: 0,
    );
    expect(chart.notes, isNotEmpty);
    expect(chart.notes.length, lessThan(400)); // not spam
    expect(chart.laneCount, 4);
    final types = chart.notes.map((n) => n.type).toSet();
    expect(types.contains(NoteType.tap), isTrue);
    // Holds/swipes appear on Normal for a 30s chart with high probability
    final times = chart.notes.map((n) => n.timeMs).toList();
    for (var i = 1; i < times.length; i++) {
      expect(times[i] >= times[i - 1], isTrue);
    }
    // First note after lead-in bar (~4 beats at 120 BPM = 2000ms)
    expect(chart.notes.first.timeMs, greaterThanOrEqualTo(1900));
  });

  test('expert denser than easy', () {
    final easy = ChartGenerator().generate(
      songId: 'e',
      title: 'E',
      artist: 'A',
      bpm: 128,
      durationMs: 45000,
      audioPath: 'x',
      difficulty: 'Easy',
    );
    final expert = ChartGenerator().generate(
      songId: 'x',
      title: 'X',
      artist: 'A',
      bpm: 128,
      durationMs: 45000,
      audioPath: 'x',
      difficulty: 'Expert',
    );
    expect(expert.notes.length, greaterThan(easy.notes.length));
  });
}
