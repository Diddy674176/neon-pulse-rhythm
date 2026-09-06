import 'dart:async';
import 'audio/audio_service.dart';
import 'audio/sfx_service.dart';
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
  final SfxService sfx = SfxService();
  GameSettings settings = GameSettings();
  AudioService? audio;

  bool ready = false;
  bool seenOnboarding = false;

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

    try {
      seenOnboarding = await save.loadSeenOnboarding();
    } catch (_) {
      seenOnboarding = false;
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

    try {
      sfx.setVolumes(master: settings.masterVolume, sfx: settings.sfxVolume);
      await sfx.init().timeout(const Duration(seconds: 4));
    } catch (e) {
      warnings.add('SFX: $e');
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
    sfx.setVolumes(master: settings.masterVolume, sfx: settings.sfxVolume);
  }

  Future<void> markOnboardingSeen() async {
    seenOnboarding = true;
    await save.saveSeenOnboarding(true);
  }
}
