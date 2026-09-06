# AETHER BEAT

Original neon / cyberpunk rhythm game for tall Android panels (Samsung Galaxy S26 Ultra class).  
Built with **Flutter + Flame**. Offline playable vertical slice.

> Completely original IP — not affiliated with Guitar Hero, Beat Saber, or any other rhythm franchise.

## Features (vertical slice)

- **Audio-clock timing** — hit detection uses `noteTime - currentAudioTime` only. Rendering FPS is independent.
- Judgment windows: **Perfect ±25ms**, **Great ±50ms**, **Good ±90ms** (configurable).
- Calibration screen for audio / touch latency offsets.
- 4 lanes by default (settings: **4 / 5 / 6**).
- Note types: **tap**, **hold**, **swipe**.
- Main menu: Play, Songs, Practice, Settings, Profile.
- Song select with demo track **Circuit Mirage** (128 BPM, ~4s procedural synth).
- Gameplay HUD: score, combo, multiplier, accuracy.
- Results: grade + judgment counts.
- Practice: restart, show timing deltas, speed stub (pitch-preserve TBD).
- Settings: volumes, haptics, performance mode, accessibility stubs.
- Refresh-rate awareness (60 / 90 / 120 bucket detection).

## Architecture (`lib/`)

| Module | Role |
|--------|------|
| `audio/` | Playback + `AudioClock` (primary timing reference) |
| `rhythm/` | `TimingEngine`, judgment windows |
| `chart/` | Note model + JSON chart loader |
| `input/` | Lane events stamped with audio time |
| `gameplay/` | Controller: hits, auto-miss, scoring |
| `scoring/` / `combo/` | Score, accuracy, grade, combo |
| `game/` | Flame render surface (`AetherGame`) |
| `ui/` / `screens/` | Menus, settings, calibration, results |
| `vfx/` | Neon palette |
| `haptics/` | Impact feedback |
| `settings/` / `save/` | Preferences + light profile |
| `song/` | Catalog metadata |
| `performance/` | Display refresh detection |

## Timing design

```
deltaMs = noteTimeMs - (rawAudioTimeMs + audioOffset + touchOffset)
```

- **Never** use frame indices for hit detection.
- Unit tests in `test/timing_engine_test.dart` prove same press audio time → same judgment at simulated 60 vs 120 FPS.

## Run

```bash
flutter pub get
flutter test
flutter run
```

Requires Flutter 3.22+ / Dart 3.3+. Android immersive / high-refresh hints in `AndroidManifest.xml` and `MainActivity.kt`.

### Demo audio

- Chart: `assets/charts/circuit_mirage.json`
- Audio: decode `assets/audio/circuit_mirage.ogg.b64` via `AudioService.loadAssetOrB64` (or drop a real `.ogg` beside it).
- Regenerate: `python3 tools/generate_demo_audio.py` then ffmpeg to OGG.

## How to add a song

1. Add audio under `assets/audio/`.
2. Author chart JSON (see `circuit_mirage.json`).
3. Register in `assets/songs/catalog.json`.

## Tests

```bash
flutter test test/timing_engine_test.dart
flutter test
```
