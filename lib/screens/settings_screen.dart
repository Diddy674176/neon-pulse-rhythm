import 'package:flutter/material.dart';
import '../app_state.dart';
import '../settings/game_settings.dart';
import '../ui/neon_widgets.dart';
import '../ui/page_routes.dart';
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

  Widget _slider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: NeonPalette.muted, fontSize: 12)),
        Slider(
          value: value.clamp(0.0, 1.5),
          min: 0,
          max: label.contains('Speed') || label.contains('Size') ? 1.5 : 1.0,
          activeColor: NeonPalette.accent,
          inactiveColor: NeonPalette.tileEdge,
          onChanged: (v) {
            setState(() => onChanged(v));
            _save();
          },
        ),
      ],
    );
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
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto Play', style: TextStyle(color: NeonPalette.text)),
                  subtitle: Text(
                    s.autoPlay ? 'AUTO PLAY ON' : 'AUTO PLAY OFF',
                    style: TextStyle(color: s.autoPlay ? NeonPalette.accent : NeonPalette.muted, fontSize: 12),
                  ),
                  value: s.autoPlay,
                  activeThumbColor: NeonPalette.accent,
                  onChanged: (v) { setState(() => s.autoPlay = v); _save(); },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reduced VFX', style: TextStyle(color: NeonPalette.text)),
                  subtitle: const Text('Smoother on phone / web (default)', style: TextStyle(color: NeonPalette.muted, fontSize: 12)),
                  value: s.reducedVfx,
                  activeThumbColor: NeonPalette.accent,
                  onChanged: (v) { setState(() => s.reducedVfx = v); _save(); },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('High contrast lanes', style: TextStyle(color: NeonPalette.text)),
                  subtitle: const Text('Brighter lane backgrounds', style: TextStyle(color: NeonPalette.muted, fontSize: 12)),
                  value: s.highContrast,
                  activeThumbColor: NeonPalette.accent,
                  onChanged: (v) { setState(() => s.highContrast = v); _save(); },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Haptics', style: TextStyle(color: NeonPalette.text)),
                  value: s.hapticsEnabled,
                  activeThumbColor: NeonPalette.accent,
                  onChanged: (v) { setState(() => s.hapticsEnabled = v); _save(); },
                ),
                const SizedBox(height: 8),
                _slider('Master volume', s.masterVolume, (v) => s.masterVolume = v),
                _slider('Music volume', s.musicVolume, (v) => s.musicVolume = v),
                _slider('SFX volume', s.sfxVolume, (v) => s.sfxVolume = v),
                _slider('Note speed', s.noteSpeed, (v) => s.noteSpeed = v.clamp(0.5, 1.5)),
                _slider('Note size', s.noteSize, (v) => s.noteSize = v.clamp(0.7, 1.4)),
                const SizedBox(height: 8),
                const Text('Performance', style: TextStyle(color: NeonPalette.muted)),
                const SizedBox(height: 6),
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
                      selectedColor: NeonPalette.surface,
                      labelStyle: TextStyle(color: selected ? NeonPalette.text : NeonPalette.muted, fontSize: 12),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          NeonMenuButton(
            label: 'CALIBRATION',
            icon: Icons.tune,
            onPressed: () async {
              await Navigator.of(context).push(aetherRoute(const CalibrationScreen()));
              setState(() => s = AppState.instance.settings);
            },
          ),
          NeonMenuButton(label: 'SAVE', filled: true, onPressed: _save),
        ],
      ),
    );
  }
}
