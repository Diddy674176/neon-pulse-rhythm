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

  Future<void> init() async {
    settings = await save.loadSettings();
    haptics.enabled = settings.hapticsEnabled;
    refresh.detect();
    refresh.applySchedulerHint(settings.performanceMode);
    await catalog.load();
    audio = AudioService(
      masterVolume: settings.masterVolume,
      musicVolume: settings.musicVolume,
    );
    await audio!.init();
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
