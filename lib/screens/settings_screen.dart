import 'package:flutter/material.dart';
import '../app_state.dart';
import '../settings/game_settings.dart';
import '../ui/neon_widgets.dart';
import '../vfx/neon_palette.dart';
import 'calibration_screen.dart';

part 'settings_screen_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}
