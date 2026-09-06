# AETHER BEAT

Original neon / cyberpunk rhythm game for tall Android panels (Samsung Galaxy S26 Ultra class).  
Built with **Flutter + Flame**. Offline playable vertical slice + **MP3 import**.

> Completely original IP — not affiliated with Guitar Hero, Beat Saber, or any other rhythm franchise.

## Features

- **Audio-clock timing** — hit detection uses `noteTime - currentAudioTime` only. Rendering FPS is independent.
- Judgment windows: **Perfect ±25ms**, **Great ±50ms**, **Good ±90ms** (configurable).
- Calibration screen for audio / touch latency offsets.
- 4 lanes by default (settings + per-import: **4 / 5 / 6**).
- Note types: **tap**, **hold**, **swipe**.
- Main menu: Play, Songs, **Import MP3**, Practice, Settings, Profile.
- Song select with demo track **Circuit Mirage** plus **user-imported MP3 library** (offline).
- Auto chart generation from BPM + duration (phrase-aware density by difficulty — not random spam).
- Gameplay HUD: score, combo, multiplier, accuracy.
- Results: grade + judgment counts.
- Practice: restart, show timing deltas, speed stub (pitch-preserve TBD).
- Settings: volumes, haptics, performance mode, accessibility stubs.
- Refresh-rate awareness (60 / 90 / 120 bucket detection).

## Architecture (`lib/`)

| Module | Role |
|--------|------|
| `audio/` | Playback + `AudioClock` (primary timing reference); asset, b64, and **device file** sources |
| `rhythm/` | `TimingEngine`, judgment windows |
| `chart/` | Note model, JSON loader, **`ChartGenerator`** for imports |
| `input/` | Lane events stamped with audio time |
| `gameplay/` | Controller: hits, auto-miss, scoring hookup |
| `scoring/` / `combo/` | Score, accuracy, grade, combo multiplier |
| `game/` | Flame render surface (`AetherGame`) |
| `ui/` / `screens/` | Menus, **import**, settings, calibration, results |
| `vfx/` | Neon palette |
| `haptics/` | Impact feedback |
| `settings/` / `save/` | Preferences + light profile |
| `song/` | Catalog + **`ImportedLibrary`** (documents storage) |
| `performance/` | Display refresh detection |

## Timing design

```
deltaMs = noteTimeMs - (rawAudioTimeMs + audioOffset + touchOffset)
```

- **Never** use frame indices or frame counts for hit detection.
- Flame/Flutter may run at 60, 90, or 120 Hz — judgment stays identical for the same audio timestamp.
- Unit tests in `test/timing_engine_test.dart` prove the same press audio time → same judgment at simulated 60 vs 120 FPS.
- Imported MP3s use the same `AudioService` clock via `DeviceFileSource`.

## Import MP3 (device)

1. **IMPORT MP3** from the main menu, or **SONGS → IMPORT MP3**.
2. Pick an `.mp3` with the system file picker (`file_picker` + SAF / scoped storage).
3. Set **title**, **artist**, **BPM**, **difficulty** (Easy/Normal/Hard/Expert), **lanes** (4/5/6), **offset (ms)**.
4. The app copies the file into application documents, estimates/probes duration, and writes a generated chart JSON.
5. The track appears in Songs (magenta **IMPORTED** badge). Play uses the existing audio-clock engine.
6. Long-press an imported song to delete it from the offline library.

Storage layout (on device):

```text
{appDocuments}/aether_beat/library/
  library.json
  {songId}/audio.mp3
  {songId}/chart.json
```

Graceful errors: missing path, non-MP3, copy failure, and audio load failure for imports surface in the UI instead of failing silently.

## Run

Requirements: Flutter 3.22+ (Dart 3.3+), Android toolchain for device/emulator.

```bash
flutter pub get
flutter test
flutter run
```

See **[INSTALL.md](INSTALL.md)** for release APK build + Samsung Galaxy sideload steps.

Android immersive / high-refresh hints live in `android/app/src/main/AndroidManifest.xml` and `MainActivity.kt`.  
App label: **AETHER BEAT** (`applicationId` `com.aetherbeat.aether_beat`).

### Demo audio

- Chart: `assets/charts/circuit_mirage.json`
- Audio: `assets/audio/circuit_mirage.ogg` (preferred) or decode `circuit_mirage.ogg.b64` / `circuit_mirage.wav.b64` at runtime.
- Regenerate: `python3 tools/generate_demo_audio.py` then encode OGG with ffmpeg.

If binary `.ogg` is missing from the checkout, the game loads the `.b64` sidecar into a temp file via `AudioService.loadAssetOrB64`.

## How to add a bundled song (assets)

1. Drop audio under `assets/audio/` (folder already listed in `pubspec.yaml`).
2. Author a chart JSON (see `assets/charts/circuit_mirage.json`).
3. Register metadata in `assets/songs/catalog.json`.

Or skip bundling and **import an MP3 on device** (above).

## Refresh rate notes

- `RefreshRateService` reads `FlutterView.display.refreshRate` when available and buckets to 60 / 90 / 120.
- Performance mode hints a target cadence; **judgment does not change** with FPS.

## Tests

```bash
flutter test test/timing_engine_test.dart
flutter test test/chart_generator_test.dart
flutter test
```

## License

Original project content © repo owner. Demo audio is procedural / original.
