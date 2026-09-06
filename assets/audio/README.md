# Audio assets

- `circuit_mirage.ogg` — preferred binary (generate via tools + ffmpeg)
- `circuit_mirage.ogg.b64` — base64 sidecar for text-only pushes / fallback loader

`AudioService.loadAssetOrB64` tries the binary asset first, then decodes `.b64`.
