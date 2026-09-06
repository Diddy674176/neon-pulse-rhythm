import 'package:flutter/material.dart';
import '../app_state.dart';
import '../settings/game_settings.dart';
import '../ui/neon_widgets.dart';
import '../vfx/neon_palette.dart';
import 'calibration_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late GameSettings s;

  @override
  void initState() {
    super.initState();
    s = AppState.instance.settings;
  }

  Future<void> _save() async {
    AppState.instance.settings = s;
    await AppState.instance.persistSettings();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeNeonScaffold(
      title: 'SETTINGS',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          NeonPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AUDIO', style: TextStyle(color: NeonPalette.cyan, letterSpacing: 2)),
                _slider('Master', s.masterVolume, (v) => s.masterVolume = v),
                _slider('Music', s.musicVolume, (v) => s.musicVolume = v),
                _slider('SFX', s.sfxVolume, (v) => s.sfxVolume = v),
              ],
            ),
          ),
          const SizedBox(height: 12),
          NeonPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('Haptics', style: TextStyle(color: NeonPalette.text)),
                  value: s.hapticsEnabled,
                  activeColor: NeonPalette.magenta,
                  onChanged: (v) {
                    setState(() => s.hapticsEnabled = v);
                    _save();
                  },
                ),
                const Text('Performance mode', style: TextStyle(color: NeonPalette.muted)),
                Wrap(
                  spacing: 8,
                  children: PerformanceMode.values.map((m) {
                    final selected = s.performanceMode == m;
                    return ChoiceChip(
                      label: Text(m.name.toUpperCase()),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => s.performanceMode = m);
                        AppState.instance.refresh.applySchedulerHint(m);
                        _save();
                      },
                      selectedColor: NeonPalette.cyan.withOpacity(0.3),
                      labelStyle: TextStyle(
                        color: selected ? NeonPalette.cyan : NeonPalette.muted,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  'Detected panel ~${AppState.instance.refresh.bucket()} Hz '
                  '(raw ${AppState.instance.refresh.detectedHz.toStringAsFixed(1)})',
                  style: const TextStyle(color: NeonPalette.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          NeonPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('GAMEPLAY', style: TextStyle(color: NeonPalette.cyan, letterSpacing: 2)),
                const Text('Lanes', style: TextStyle(color: NeonPalette.muted)),
                Wrap(
                  spacing: 8,
                  children: [4, 5, 6].map((n) {
                    return ChoiceChip(
                      label: Text('$n'),
                      selected: s.laneCount == n,
                      onSelected: (_) {
                        setState(() => s.laneCount = n);
                        _save();
                      },
                      selectedColor: NeonPalette.violet.withOpacity(0.35),
                      labelStyle: TextStyle(
                        color: s.laneCount == n ? NeonPalette.violet : NeonPalette.muted,
                      ),
                    );
                  }).toList(),
                ),
                _slider('Note speed', s.noteSpeed, (v) => s.noteSpeed = v, min: 0.6, max: 1.8),
                _slider('Note size', s.noteSize, (v) => s.noteSize = v, min: 0.7, max: 1.4),
                SwitchListTile(
                  title: const Text('High contrast', style: TextStyle(color: NeonPalette.text)),
                  value: s.highContrast,
                  onChanged: (v) {
                    setState(() => s.highContrast = v);
                    _save();
                  },
                ),
                ListTile(
                  title: const Text('Handedness', style: TextStyle(color: NeonPalette.text)),
                  subtitle: Text(s.handedness.name, style: const TextStyle(color: NeonPalette.muted)),
                  trailing: IconButton(
                    icon: const Icon(Icons.swap_horiz, color: NeonPalette.cyan),
                    onPressed: () {
                      setState(() {
                        s.handedness = s.handedness == Handedness.right
                            ? Handedness.left
                            : Handedness.right;
                      });
                      _save();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          NeonMenuButton(
            label: 'CALIBRATION',
            accent: NeonPalette.lime,
            icon: Icons.tune,
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CalibrationScreen()),
              );
              setState(() => s = AppState.instance.settings);
            },
          ),
          NeonMenuButton(
            label: 'SAVE',
            onPressed: () async {
              await _save();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings saved')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _slider(
    String label,
    double value,
    ValueChanged<double> onChanged, {
    double min = 0,
    double max = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label  ${value.toStringAsFixed(2)}',
            style: const TextStyle(color: NeonPalette.muted)),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          activeColor: NeonPalette.cyan,
          onChanged: (v) {
            setState(() => onChanged(v));
          },
          onChangeEnd: (_) => _save(),
        ),
      ],
    );
  }
}
