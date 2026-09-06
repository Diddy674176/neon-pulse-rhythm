# Install AETHER BEAT on Samsung Galaxy (no PC required)

## Easiest path — download the free CI APK

GitHub Actions builds a release APK for you (free):

1. Open **Actions**: https://github.com/Diddy674176/neon-pulse-rhythm/actions
2. Open the latest **Build APK** run (branch `feat/vertical-slice`)
3. Wait until it shows green / success (first run can take several minutes)
4. Scroll to **Artifacts** → download **aether-beat-apk**
5. Unzip — inside is `app-release.apk`
6. Send that file to your Galaxy (Drive, Messages, cable, Samsung Flow, etc.)
7. On the phone: open it in **My Files** → allow **Install unknown apps** for that app if asked → Install → open **AETHER BEAT**

You can also start a build manually: **Actions → Build APK → Run workflow** (choose `feat/vertical-slice`).

> Artifacts expire after **14 days**. Re-run the workflow anytime for a fresh APK.

## First run — play & import MP3

1. Open **AETHER BEAT**
2. **Play** / **Songs** → built-in **Circuit Mirage**, or **IMPORT MP3** for your own tracks
3. Set title, artist, BPM, difficulty, lanes (4/5/6), offset → **IMPORT & GENERATE**
4. Play from **Songs** — timing uses the audio clock
5. Long-press an imported song to delete it
6. If hits feel early/late: **Settings → Calibration**

## Optional — build on a PC

Only needed if you want to compile locally:

```bash
git clone https://github.com/Diddy674176/neon-pulse-rhythm.git
cd neon-pulse-rhythm
git checkout feat/vertical-slice
flutter pub get
flutter test
flutter build apk --release
```

APK: `build/app/outputs/flutter-apk/app-release.apk`

USB install: `adb install -r build/app/outputs/flutter-apk/app-release.apk`

### Enable USB debugging (Galaxy)

1. **Settings → About phone → Software information**
2. Tap **Build number** seven times
3. **Developer options** → **USB debugging**

## Signing note

Release builds use the **debug keystore** so you can sideload immediately. For Play Store / permanent signing across reinstalls, add your own keystore later.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| No Artifacts on Actions run | Wait for green success; failed runs have no APK |
| Install blocked | **Settings → Security → Install unknown apps** → allow My Files / Chrome |
| No sound on import | Confirm `.mp3`; check Settings volumes |
| Chart early/late | Calibration, or re-import with Offset (ms) |
| Permission denied picking file | Use system picker; grant music/audio access if prompted |
