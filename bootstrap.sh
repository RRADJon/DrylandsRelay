#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${1:-$ROOT/project}"
UPSTREAM=https://github.com/godotengine/tps-demo.git
COMMIT=90f2e38d7b5cf9e6fd0b788d0da1df4b84d49269

if [ ! -d "$DEST/.git" ]; then
  git clone "$UPSTREAM" "$DEST"
fi
git -C "$DEST" fetch --all --tags --prune
git -C "$DEST" checkout --detach "$COMMIT"
git -C "$DEST" reset --hard "$COMMIT"
git -C "$DEST" clean -fdx
python3 "$ROOT/tools/install_overlay.py" "$DEST" --overlay "$ROOT"
printf '\nReady: %s\nOpen that folder in Godot 4.5.2 and press Play.\n' "$DEST"
