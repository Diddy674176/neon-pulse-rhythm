#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")" && pwd)"
base64 -d "$root/gradle/wrapper/gradle-wrapper.jar.b64" > "$root/gradle/wrapper/gradle-wrapper.jar"
for d in mipmap-hdpi mipmap-mdpi mipmap-xhdpi mipmap-xxhdpi mipmap-xxxhdpi; do
  b64="$root/app/src/main/res/$d/ic_launcher.png.b64"
  out="$root/app/src/main/res/$d/ic_launcher.png"
  if [[ -f "$b64" ]]; then
    base64 -d "$b64" > "$out"
  fi
done
echo "Restored android binaries."
