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
                  subtitle: const Text('Smoother on phone / web', style: TextStyle(color: NeonPalette.muted, fontSize: 12)),
                  value: s.reducedVfx,
                  activeThumbColor: NeonPalette.accent,
                  onChanged: (v) { setState(() => s.reducedVfx = v); _save(); },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Haptics', style: TextStyle(color: NeonPalette.text)),
                  value: s.hapticsEnabled,
                  activeThumbColor: NeonPalette.accent,
                  onChanged: (v) { setState(() => s.hapticsEnabled = v); _save(); },
                ),
                const Text('Performance', style: TextStyle(color: NeonPalette.muted)),
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
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CalibrationScreen()));
              setState(() => s = AppState.instance.settings);
            },
          ),
          NeonMenuButton(label: 'SAVE', filled: true, onPressed: _save),
        ],
      ),
    );
  }
}
