import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import '../app_state.dart';
import '../audio/audio_clock.dart';
import '../chart/chart_loader.dart';
import '../chart/note.dart';
import '../input/keyboard_lanes.dart';
import '../game/aether_game.dart';
import '../rhythm/timing_engine.dart';
import '../song/song_catalog.dart';
import '../vfx/neon_palette.dart';
import 'results_screen.dart';

part 'gameplay_screen_state.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key, required this.song, required this.practice});
  final SongMeta song;
  final bool practice;
  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}
