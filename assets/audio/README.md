# Audio assets

Built-in tracks (original generated):
- `circuit_mirage.ogg` — demo anthem
- `pulse_drift.ogg` — mid-tempo drift
- `void_step.ogg` — faster punch

Hit SFX (short):
- `hit_perfect.ogg` / `hit_great.ogg` / `hit_good.ogg` / `hit_miss.ogg`

Each `.ogg` has `.b64` / `.b64.0`+`.b64.1` sidecars for text-only fallback via `AudioService.loadAssetOrB64`.

Regenerate: `python3 tools/generate_feel_assets.py`
