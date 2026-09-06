# Install AETHER BEAT on Samsung Galaxy (sideload)

Free local path — no paid CI / Cloud Agents required.

## Requirements

- A computer with **Flutter 3.22+** (Dart 3.3+) and Android SDK
- USB cable + Galaxy phone (S26 Ultra class or any Android 7+)
- USB debugging enabled on the phone

### Enable developer options (Galaxy)

1. **Settings → About phone → Software information**
2. Tap **Build number** seven times
3. Back → **Developer options** → enable **USB debugging**
4. (Optional) Enable **Install via USB**

## Build the APK (on your machine)

```bash
git clone https://github.com/Diddy674176/neon-pulse-rhythm.git
cd neon-pulse-rhythm
git checkout feat/vertical-slice   # or feat/mp3-import-apk if that branch exists
flutter pub get
flutter test
flutter build apk --release
```

APK output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Debug build (faster iterate):

```bash
flutter build apk --debug
```

## Install via USB (`adb`)

```bash
adb devices
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

If you see more than one device, pick with `-s <serial>`.

## Install without cable (wireless / file copy)

1. Copy `app-release.apk` to the phone (Drive, Bluetooth, USB storage, Samsung Flow, etc.)
2. Open the file in **My Files**
3. If blocked: **Settings → Security / Privacy → Install unknown apps** → allow the file manager
4. Tap install → open **AETHER BEAT**

## First run — import an MP3

1. Main menu → **IMPORT MP3** (or **SONGS** → **IMPORT MP3** FAB)
2. Pick an `.mp3` from device storage
3. Set title, artist, BPM, difficulty, lanes (4/5/6), offset
4. Tap **IMPORT & GENERATE** — file is copied into app documents and a beat-grid chart is generated offline
5. Play from **SONGS** — timing still uses the **audio clock** engine

Long-press an imported song on the Songs list to delete it.

## Signing note

Release builds in this repo currently use the **debug keystore** so you can sideload immediately. For Play Store / permanent installs across reinstalls, create your own keystore and point `android/app/build.gradle` `signingConfigs.release` at it.

## Agent / CI note

The shared build agent used for some repo automation may not have the Flutter SDK installed. Prefer building on your PC or laptop with the free Flutter SDK from https://docs.flutter.dev/get-started/install.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `adb` empty | Unlock phone, accept RSA prompt, retry cable / port |
| Install blocked | Allow unknown apps for My Files / adb |
| No sound on import | Confirm file is `.mp3`; re-import; check Settings volumes |
| Chart feels early/late | Use **Settings → Calibration**, or re-import with Offset (ms) |
| Permission denied picking file | Use the system file picker (SAF); grant music/audio access if prompted |
