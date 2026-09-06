import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../song/song_catalog.dart';
import '../ui/neon_widgets.dart';
import '../vfx/neon_palette.dart';
import 'gameplay_screen.dart';
import 'import_song_screen.dart';

part 'song_select_screen_state.dart';

class SongSelectScreen extends StatefulWidget {
  const SongSelectScreen({super.key, required this.practice});
  final bool practice;

  @override
  State<SongSelectScreen> createState() => _SongSelectScreenState();
}
