#!/usr/bin/env bash
# Install UE4SS + RuneSchema + this pack into the game folder.
# Backs up anything it replaces. Safe to re-run (updates the pack in place).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GAME_DIR="${GAME_DIR:-/media/Games/SteamLibrary/steamapps/common/RSDragonwilds}"
WIN64="$GAME_DIR/RSDragonwilds/Binaries/Win64"

if [[ ! -f "$WIN64/RSDragonwilds-Win64-Shipping.exe" ]]; then
  echo "Game not found at: $GAME_DIR" >&2
  echo "Set GAME_DIR=/path/to/steamapps/common/RSDragonwilds" >&2
  exit 1
fi

if [[ ! -f "$ROOT/vendor/ue4ss/Binaries/Win64/dwmapi.dll" || ! -d "$ROOT/vendor/runeschema/RuneSchema" ]]; then
  "$ROOT/tools/fetch-deps.sh"
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
BK="$GAME_DIR/.wyrmwood-backups/$STAMP"
mkdir -p "$BK"
for item in dwmapi.dll ue4ss; do
  if [[ -e "$WIN64/$item" ]]; then
    cp -a "$WIN64/$item" "$BK/"
    echo "backed up $item"
  fi
done
echo "installing UE4SS"
cp -a "$ROOT/vendor/ue4ss/Binaries/Win64/." "$WIN64/"

echo "installing RuneSchema"
RS_TARGET="$WIN64/ue4ss/Mods/RuneSchema"
if [[ -d "$RS_TARGET" ]]; then
  rm -rf "$RS_TARGET"
fi
cp -a "$ROOT/vendor/runeschema/RuneSchema" "$RS_TARGET"
mkdir -p "$RS_TARGET/mods"

# Enable RuneSchema in UE4SS mods.txt without touching other entries.
MODS_TXT="$WIN64/ue4ss/Mods/mods.txt"
touch "$MODS_TXT"
if grep -qiE '^[[:space:]]*RuneSchema[[:space:]]*:' "$MODS_TXT"; then
  sed -i -E 's/^([[:space:]]*RuneSchema[[:space:]]*:).*/\1 1/' "$MODS_TXT"
else
  printf '\nRuneSchema : 1\n' >> "$MODS_TXT"
fi

GAME_DIR="$GAME_DIR" bash "$ROOT/tools/sync-mods.sh"

echo
echo "installed to $GAME_DIR"
echo "backup: $BK"
echo "next: start the game, then check $WIN64/ue4ss/UE4SS.log and RuneSchema.log"
