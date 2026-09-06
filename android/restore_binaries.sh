#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")" && pwd)"
wrapper_dir="$root/gradle/wrapper"
b64="$wrapper_dir/gradle-wrapper.jar.b64"
if [[ ! -f "$b64" ]]; then
  # Reassemble from MCP-sized parts if present
  shopt -s nullglob
  parts=("$wrapper_dir"/gradle-wrapper.jar.b64.[0-9]*)
  if ((${#parts[@]})); then
    # sort -V for numeric order; sed fixes a known one-char MCP transcription typo in part 3
    cat $(printf '%s\n' "${parts[@]}" | sort -V) | sed 's/M7qqEfOS0O/M7qdEfOS0O/g' > "$b64"
  fi
fi
base64 -d "$b64" > "$wrapper_dir/gradle-wrapper.jar"
for d in mipmap-hdpi mipmap-mdpi mipmap-xhdpi mipmap-xxhdpi mipmap-xxxhdpi; do
  b64png="$root/app/src/main/res/$d/ic_launcher.png.b64"
  out="$root/app/src/main/res/$d/ic_launcher.png"
  if [[ -f "$b64png" ]]; then
    base64 -d "$b64png" > "$out"
  fi
done
echo "Restored android binaries."
