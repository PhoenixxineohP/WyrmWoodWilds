#!/usr/bin/env bash
# Copy every mod folder into the installed RuneSchema and write runeschema.txt
# from features.conf, preserving mods from other authors that are already there.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GAME_DIR="${GAME_DIR:-/media/Games/SteamLibrary/steamapps/common/RSDragonwilds}"
RS_ROOT="$GAME_DIR/RSDragonwilds/Binaries/Win64/ue4ss/Mods/RuneSchema"
RS_MODS="$RS_ROOT/mods"
FEATURES="$ROOT/features.conf"

if [[ ! -d "$RS_ROOT" ]]; then
  echo "RuneSchema is not installed at: $RS_ROOT" >&2
  echo "Run tools/install.sh first." >&2
  exit 1
fi
mkdir -p "$RS_MODS"

# Remove our previous copies, leave other authors' mods alone.
shopt -s nullglob
for d in "$RS_MODS"/WW_*; do
  rm -rf "$d"
done
shopt -u nullglob

declare -a names=()
declare -A state=()
while IFS= read -r line; do
  line="${line%%#*}"
  line="$(echo "$line" | tr -d '[:space:]')"
  [[ -z "$line" ]] && continue
  name="${line%%=*}"
  value="${line#*=}"
  [[ "$value" == "on" || "$value" == "off" ]] || { echo "bad toggle: $line" >&2; exit 1; }
  names+=("$name")
  state["$name"]="$value"
  src="$ROOT/mods/$name"
  if [[ -d "$src" ]]; then
    cp -a "$src" "$RS_MODS/$name"
  else
    echo "warning: no folder for $name" >&2
  fi
done < "$FEATURES"

# Preserve other authors' entries.
TMP="$(mktemp)"
if [[ -f "$RS_MODS/runeschema.txt" ]]; then
  grep -viE '^[[:space:]]*WW_' "$RS_MODS/runeschema.txt" | sed '/^[[:space:]]*$/d' > "$TMP" || true
else
  : > "$TMP"
fi

{
  for name in "${names[@]}"; do
    printf '%-28s : %s\n' "$name" "$([[ "${state[$name]}" == "on" ]] && echo 1 || echo 0)"
  done
  cat "$TMP"
} > "$RS_MODS/runeschema.txt"
rm -f "$TMP"

echo "synced ${#names[@]} WyrmWood mods to $RS_MODS"
for name in "${names[@]}"; do
  printf '  %-28s %s\n' "$name" "${state[$name]}"
done
