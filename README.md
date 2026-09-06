# AETHER BEAT

Original neon / cyberpunk rhythm game for tall Android panels (Samsung Galaxy S26 Ultra class).  
Built with **Flutter + Flame**. Offline playable vertical slice + **MP3 import**.

> Completely original IP — not affiliated with Guitar Hero, Beat Saber, or any other rhythm franchise.

## Play in browser (free)

**Live:** [https://diddy674176.github.io/neon-pulse-rhythm/](https://diddy674176.github.io/neon-pulse-rhythm/)  
(GitHub Pages from the `gh-pages` branch — enable under **Settings → Pages → Deploy from branch → `gh-pages` / root** if the URL 404s.)

### Keyboard controls (web / desktop)

| Lanes | Keys |
|-------|------|
| 4 | `D` `F` `J` `K` — or `1`–`4` |
| 5 | `D` `F` `Space` `J` `K` — or `1`–`5` |
| 6 | `S` `D` `F` `J` `K` `L` — or `1`–`6` |

Touch / mouse: tap (or click) each lane. Swipe on a lane for swipe notes.

### Local web preview (no Pages)

```bash
flutter build web --release --base-href "/"
cd build/web && python3 -m http.server 8080
# open http://localhost:8080/
```

CI also deploys web via `.github/workflows/deploy-web.yml` (Flutter build → `gh-pages`).

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

## Run

Requirements: Flutter 3.22+ (Dart 3.3+), Android toolchain for device/emulator.

```bash
flutter pub get
flutter test
flutter run
```

See **[INSTALL.md](INSTALL.md)** for APK sideload + browser play.

App label: **AETHER BEAT** (`applicationId` `com.aetherbeat.aether_beat`).

## License

Original project content © repo owner. Demo audio is procedural / original.
