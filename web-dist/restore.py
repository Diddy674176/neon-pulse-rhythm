#!/usr/bin/env python3
"""Restore web-dist/files (+ *.b64 sidecars / parts) into web-dist/out for GitHub Pages."""
import base64, json, shutil
from pathlib import Path

root = Path(__file__).resolve().parent
files = root / "files"
out = root / "out"
if out.exists():
    shutil.rmtree(out)
out.mkdir(parents=True)
manifest = json.loads((root / "manifest.json").read_text())
for entry in manifest:
    dest = out / entry["path"]
    dest.parent.mkdir(parents=True, exist_ok=True)
    enc = entry["encoding"]
    if enc == "utf-8":
        dest.write_bytes((files / entry["path"]).read_bytes())
    elif enc == "base64":
        dest.write_bytes(base64.b64decode((files / entry["sidecar"]).read_text()))
    elif enc == "parts":
        data = "".join((files / p).read_text() for p in entry["parts"])
        dest.write_text(data)
    else:
        raise SystemExit(f"unknown encoding {enc}")
print(f"Restored {len(manifest)} files -> {out}")
