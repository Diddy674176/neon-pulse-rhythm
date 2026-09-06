import 'dart:async';
import 'audio/audio_service.dart';
import 'haptics/haptics_service.dart';
import 'performance/refresh_rate.dart';
import 'save/save_store.dart';
import 'settings/game_settings.dart';
import 'song/song_catalog.dart';

class AppState {
  AppState._();
  static final AppState instance = AppState._();

  final SaveStore save = SaveStore();
  final SongCatalog catalog = SongCatalog();
  final RefreshRateService refresh = RefreshRateService();
  final HapticsService haptics = HapticsService();
  GameSettings settings = GameSettings();
  AudioService? audio;

  bool ready = false;

  /// Non-fatal subsystem warnings (menu still opens).
  final List<String> warnings = [];

  Future<void> init() async {
    warnings.clear();

    try {
      settings = await save.loadSettings();
    } catch (e) {
      warnings.add('Settings: $e');
      settings = GameSettings();
    }

    haptics.enabled = settings.hapticsEnabled;
    try {
      refresh.detect();
      refresh.applySchedulerHint(settings.performanceMode);
    } catch (e) {
      warnings.add('Refresh rate: $e');
    }

    try {
      await catalog.load();
    } catch (e) {
      warnings.add('Catalog: $e');
      // Keep whatever songs we already have (may be empty).
    }

    try {
      audio = AudioService(
        masterVolume: settings.masterVolume,
        musicVolume: settings.musicVolume,
      );
      await audio!.init().timeout(const Duration(seconds: 8));
    } catch (e) {
      warnings.add('Audio: $e');
      try {
        await audio?.dispose();
      } catch (_) {}
      audio = null;
    }

    ready = true;
  }

  Future<void> persistSettings() async {
    haptics.enabled = settings.hapticsEnabled;
    await save.saveSettings(settings);
    await audio?.setVolumes(
      master: settings.masterVolume,
      music: settings.musicVolume,
    );
  }
}
