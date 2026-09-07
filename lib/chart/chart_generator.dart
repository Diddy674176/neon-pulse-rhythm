import 'dart:math';

import 'chart_data.dart';
import 'note.dart';

/// Generates a musically intentional chart from BPM + duration.
/// Patterns follow beat grid / phrase structure — not uniform random spam.
class ChartGenerator {
  ChartGenerator({Random? random}) : _rng = random ?? Random(42);

  final Random _rng;

  ChartData generate({
    required String songId,
    required String title,
    required String artist,
    required double bpm,
    required double durationMs,
    required String audioPath,
    required String difficulty,
    int laneCount = 4,
    double offsetMs = 0,
  }) {
    final lanes = laneCount.clamp(4, 6);
    final beatMs = 60000.0 / bpm;
    final profile = _DifficultyProfile.forName(difficulty);
    final notes = <ChartNote>[];

    // Lead-in: quiet first bar, then engage.
    final startBeat = 4;
    final endMs = durationMs - beatMs; // leave trailing breath
    final totalBeats = ((endMs - offsetMs) / beatMs).floor();

    var laneCursor = 0;
    var lastLane = -1;
    var consecutiveSame = 0;
    var noteIndex = 0;

    for (var beat = startBeat; beat < totalBeats; beat++) {
      final t = offsetMs + beat * beatMs;
      if (t >= endMs) break;

      final bar = beat ~/ 4;
      final beatInBar = beat % 4;
      final phrase = bar % 8; // 8-bar phrases
      final isDownbeat = beatInBar == 0;
      final isBackbeat = beatInBar == 2;
      final inBuild = phrase >= 4 && phrase < 6;
      final inChorus = phrase >= 6;

      // Subdivision density by section + difficulty.
      final steps = _subdivisionSteps(profile, inBuild: inBuild, inChorus: inChorus);
      for (var s = 0; s < steps; s++) {
        final subT = t + (beatMs / steps) * s;
        if (subT >= endMs) break;

        // Probability gate — denser on downbeats / chorus, sparse early.
        final densityBoost = inChorus
            ? 1.25
            : inBuild
                ? 1.1
                : (phrase < 2 ? 0.7 : 1.0);
        final p = profile.baseDensity * densityBoost * (s == 0 ? 1.0 : 0.55);
        if (_rng.nextDouble() > p.clamp(0.05, 0.98)) continue;

        // Pick note type with musical bias.
        final type = _pickType(
          profile,
          isDownbeat: isDownbeat && s == 0,
          isBackbeat: isBackbeat && s == 0,
          inChorus: inChorus,
        );

        // Lane pattern: alternating streams, occasional jumps, avoid spam same lane.
        laneCursor = _nextLane(
          lanes: lanes,
          lastLane: lastLane,
          consecutiveSame: consecutiveSame,
          preferJump: isDownbeat && inChorus && profile.allowJumps,
          streamBias: profile.streamBias,
        );
        if (laneCursor == lastLane) {
          consecutiveSame++;
        } else {
          consecutiveSame = 0;
          lastLane = laneCursor;
        }

        if (type == NoteType.hold) {
          final holdBeats = profile.holdBeats;
          final end = (subT + beatMs * holdBeats).clamp(subT + beatMs * 0.5, endMs);
          // Skip overlapping holds on same lane shortly after.
          if (_hasNearbyHold(notes, laneCursor, subT, beatMs)) continue;
          notes.add(ChartNote(
            type: NoteType.hold,
            lane: laneCursor,
            timeMs: subT,
            endTimeMs: end,
            id: 'n${noteIndex++}',
          ));
        } else if (type == NoteType.swipe) {
          notes.add(ChartNote(
            type: NoteType.swipe,
            lane: laneCursor,
            timeMs: subT,
            direction: _swipeForPhrase(phrase, beatInBar),
            id: 'n${noteIndex++}',
          ));
        } else {
          notes.add(ChartNote(
            type: NoteType.tap,
            lane: laneCursor,
            timeMs: subT,
            id: 'n${noteIndex++}',
          ));
          // Optional jump (second tap) on strong beats for harder charts.
          if (profile.allowJumps &&
              isDownbeat &&
              s == 0 &&
              inChorus &&
              _rng.nextDouble() < profile.jumpChance) {
            final other = (laneCursor + 1 + _rng.nextInt(lanes - 1)) % lanes;
            notes.add(ChartNote(
              type: NoteType.tap,
              lane: other,
              timeMs: subT,
              id: 'n${noteIndex++}',
            ));
          }
        }
      }
    }

    notes.sort((a, b) => a.timeMs.compareTo(b.timeMs));
    // Deduplicate exact same lane+time collisions (keep first).
    final cleaned = <ChartNote>[];
    final seen = <String>{};
    for (final n in notes) {
      final key = '${n.lane}:${n.timeMs.round()}';
      if (seen.add(key)) cleaned.add(n);
    }

    return ChartData(
      songId: songId,
      title: title,
      artist: artist,
      bpm: bpm,
      durationMs: durationMs,
      audioAsset: audioPath,
      notes: cleaned,
      offsetMs: offsetMs,
      laneCount: lanes,
      difficulty: difficulty,
    );
  }

  int _subdivisionSteps(_DifficultyProfile p, {required bool inBuild, required bool inChorus}) {
    if (inChorus) return p.chorusSteps;
    if (inBuild) return p.buildSteps;
    return p.verseSteps;
  }

  NoteType _pickType(
    _DifficultyProfile p, {
    required bool isDownbeat,
    required bool isBackbeat,
    required bool inChorus,
  }) {
    final r = _rng.nextDouble();
    if (isDownbeat && r < p.holdChance) return NoteType.hold;
    if ((isBackbeat || inChorus) && r < p.holdChance + p.swipeChance) {
      return NoteType.swipe;
    }
    return NoteType.tap;
  }

  int _nextLane({
    required int lanes,
    required int lastLane,
    required int consecutiveSame,
    required bool preferJump,
    required double streamBias,
  }) {
    if (lastLane < 0) return _rng.nextInt(lanes);
    if (consecutiveSame >= 2) {
      return (lastLane + 1 + _rng.nextInt(lanes - 1)) % lanes;
    }
    if (preferJump) {
      return (lastLane + 2) % lanes;
    }
    // Stream-biased: step ±1 most of the time.
    if (_rng.nextDouble() < streamBias) {
      final dir = _rng.nextBool() ? 1 : -1;
      return (lastLane + dir + lanes) % lanes;
    }
    return _rng.nextInt(lanes);
  }

  bool _hasNearbyHold(List<ChartNote> notes, int lane, double t, double beatMs) {
    for (final n in notes.reversed) {
      if (n.type != NoteType.hold) continue;
      if (n.lane != lane) continue;
      if ((n.endTimeMs ?? n.timeMs) > t - beatMs * 0.25) return true;
      break;
    }
    return false;
  }

  SwipeDirection _swipeForPhrase(int phrase, int beatInBar) {
    // Phrase edges favor up; mid-phrase varies.
    if (phrase == 0 || phrase == 7) return SwipeDirection.up;
    if (beatInBar == 2) return SwipeDirection.down;
    const dirs = SwipeDirection.values;
    return dirs[_rng.nextInt(dirs.length)];
  }
}

class _DifficultyProfile {
  const _DifficultyProfile({
    required this.baseDensity,
    required this.verseSteps,
    required this.buildSteps,
    required this.chorusSteps,
    required this.holdChance,
    required this.swipeChance,
    required this.allowJumps,
    required this.jumpChance,
    required this.streamBias,
    required this.holdBeats,
  });

  final double baseDensity;
  final int verseSteps;
  final int buildSteps;
  final int chorusSteps;
  final double holdChance;
  final double swipeChance;
  final bool allowJumps;
  final double jumpChance;
  final double streamBias;
  final double holdBeats;

  static _DifficultyProfile forName(String name) {
    switch (name.toLowerCase()) {
      case 'easy':
        return const _DifficultyProfile(
          baseDensity: 0.35,
          verseSteps: 1,
          buildSteps: 1,
          chorusSteps: 2,
          holdChance: 0.12,
          swipeChance: 0.06,
          allowJumps: false,
          jumpChance: 0,
          streamBias: 0.75,
          holdBeats: 2,
        );
      case 'hard':
        return const _DifficultyProfile(
          baseDensity: 0.62,
          verseSteps: 2,
          buildSteps: 2,
          chorusSteps: 4,
          holdChance: 0.14,
          swipeChance: 0.12,
          allowJumps: true,
          jumpChance: 0.28,
          streamBias: 0.7,
          holdBeats: 1.5,
        );
      case 'expert':
        return const _DifficultyProfile(
          baseDensity: 0.78,
          verseSteps: 2,
          buildSteps: 4,
          chorusSteps: 4,
          holdChance: 0.16,
          swipeChance: 0.16,
          allowJumps: true,
          jumpChance: 0.4,
          streamBias: 0.65,
          holdBeats: 1,
        );
      case 'normal':
      default:
        return const _DifficultyProfile(
          baseDensity: 0.48,
          verseSteps: 1,
          buildSteps: 2,
          chorusSteps: 2,
          holdChance: 0.13,
          swipeChance: 0.09,
          allowJumps: true,
          jumpChance: 0.15,
          streamBias: 0.72,
          holdBeats: 2,
        );
    }
  }
}
