# AETHER BEAT

Original piano-tiles-inspired rhythm game for tall Android panels and web.
Built with **Flutter + Flame**. Offline playable + **MP3 import** (native). Clean dark UI.

> Completely original IP — not affiliated with Magic Tiles 3 or any other rhythm franchise.

## Play

**Live web:** https://diddy674176.github.io/neon-pulse-rhythm/

## Highlights

- **Audio-clock timing** — hit detection uses `noteTime - currentAudioTime` only.
- **Piano-tiles layout** — dark tiles scroll down 4 columns to a white hit line.
- **Auto Play** — toggle **AUTO PLAY ON/OFF** on song select or during gameplay; Perfect-timed hits fire automatically (demos / lag testing). Score and judgments still update.
- **Reduced VFX** (default) — pooled paints, cached HUD text, fewer allocations for smoother phone/web FPS.
- Clean UI: deep black, white text, one accent — no neon spam.

## Auto Play how-to

1. Open **SONGS** (or start a run).
2. Tap **AUTO PLAY OFF** so it becomes **AUTO PLAY ON** (also in **SETTINGS**).
3. Start a song — tiles are hit automatically within the Perfect window.
4. Toggle off anytime to play manually.

## Known limits

- Web may skip MP3 import (file picker / storage); built-in demo tracks work.
- Reduced settings surface on web (lanes/note size still available on native/full settings).
- Auto Play is for demos/lag tests — not a substitute for skill calibration.

## Build

```bash
flutter test
flutter build web --release --base-href "/neon-pulse-rhythm/"
```
