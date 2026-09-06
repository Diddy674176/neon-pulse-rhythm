#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")" && pwd)"
wrapper_dir="$root/gradle/wrapper"
jar="$wrapper_dir/gradle-wrapper.jar"
b64="$wrapper_dir/gradle-wrapper.jar.b64"

restore_jar_from_b64() {
  if [[ ! -f "$b64" ]]; then
    shopt -s nullglob
    fine=("$wrapper_dir"/gradle-wrapper.jar.b64.p[0-9][0-9])
    if ((${#fine[@]} > 0)); then
      cat $(printf '%s\n' "${fine[@]}" | sort) > "$b64"
    else
      parts=("$wrapper_dir"/gradle-wrapper.jar.b64.[0-9]*)
      # Need all 8 coarse parts; fewer means incomplete MCP upload
      if ((${#parts[@]} >= 8)); then
        cat $(printf '%s\n' "${parts[@]}" | sort -V) | sed 's/M7qqEfOS0O/M7qdEfOS0O/g' > "$b64"
      fi
    fi
  fi
  [[ -f "$b64" ]] || return 1
  base64 -d "$b64" > "$jar"
}

if ! restore_jar_from_b64; then
  echo "Downloading gradle-wrapper.jar from Gradle v9.3.1..."
  curl -fsSL "https://raw.githubusercontent.com/gradle/gradle/v9.3.1/gradle/wrapper/gradle-wrapper.jar" -o "$jar"
fi

for d in mipmap-hdpi mipmap-mdpi mipmap-xhdpi mipmap-xxhdpi mipmap-xxxhdpi; do
  b64png="$root/app/src/main/res/$d/ic_launcher.png.b64"
  out="$root/app/src/main/res/$d/ic_launcher.png"
  if [[ -f "$b64png" ]]; then
    base64 -d "$b64png" > "$out"
  fi
done
echo "Restored android binaries."
