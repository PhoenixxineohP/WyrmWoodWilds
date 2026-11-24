#!/usr/bin/env bash
# Show what is installed and what the last RuneSchema/UE4SS logs said.
set -euo pipefail

GAME_DIR="${GAME_DIR:-/media/Games/SteamLibrary/steamapps/common/RSDragonwilds}"
WIN64="$GAME_DIR/RSDragonwilds/Binaries/Win64"
UE="$WIN64/ue4ss"

echo "game: $GAME_DIR"
[[ -f "$WIN64/dwmapi.dll" ]] && echo "UE4SS: installed" || echo "UE4SS: missing"
[[ -f "$UE/Mods/RuneSchema/dlls/main.dll" ]] && echo "RuneSchema: installed" || echo "RuneSchema: missing"

if [[ -f "$UE/Mods/RuneSchema/mods/runeschema.txt" ]]; then
  echo
  echo "enabled mods:"
  sed 's/^/  /' "$UE/Mods/RuneSchema/mods/runeschema.txt"
fi

for log in "$UE/UE4SS.log" "$UE/Mods/RuneSchema/RuneSchema.log"; do
  if [[ -f "$log" ]]; then
    echo
    echo "== $(basename "$log") (errors) =="
    grep -iE "error|failed|rejected|not found" "$log" | tail -n 15 || true
  fi
done
