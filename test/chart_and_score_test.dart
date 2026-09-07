import 'package:flutter_test/flutter_test.dart';
import 'package:aether_beat/chart/chart_data.dart';
import 'package:aether_beat/rhythm/judgment.dart';
import 'package:aether_beat/scoring/score_model.dart';

void main() {
  test('chart JSON parse includes tap hold swipe', () {
    final chart = ChartData.fromJson({
      'songId': 't',
      'title': 'T',
      'artist': 'A',
      'bpm': 128,
      'durationMs': 10000,
      'audio': 'assets/audio/x.ogg',
      'notes': [
        {'type': 'tap', 'lane': 0, 'timeMs': 0},
        {'type': 'hold', 'lane': 1, 'timeMs': 500, 'endTimeMs': 1000},
        {'type': 'swipe', 'lane': 2, 'timeMs': 1500, 'direction': 'up'},
      ],
    });
    expect(chart.notes.length, 3);
    expect(chart.beatMs, closeTo(468.75, 0.01));
  });

  test('score grade and accuracy', () {
    final s = ScoreModel();
    s.apply(Judgment.perfect, comboBefore: 0);
    s.apply(Judgment.perfect, comboBefore: 1);
    s.apply(Judgment.great, comboBefore: 2);
    expect(s.perfect, 2);
    expect(s.great, 1);
    expect(s.grade, anyOf('S', 'A', 'SS'));
    expect(s.accuracy, greaterThan(0.8));
  });
}
