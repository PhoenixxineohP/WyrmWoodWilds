#!/usr/bin/env bash
# Download the pinned UE4SS + RuneSchema packages into ./vendor.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR="$ROOT/vendor"
mkdir -p "$VENDOR"

UE4SS_URL="https://github.com/MichaelRyan2319/RSDragonwilds-UE4SS/releases/download/v3.0.1-1217-r2/UE4SS-RSDragonwilds.zip"
RS_URL="https://github.com/gh0sted5456-us/RuneSchema/releases/download/0.9.0.1-pre.20261117.1/RuneSchema-0.9.0.1-preview-20261117.1.zip"

fetch() {
  local url="$1" out="$2"
  if [[ -f "$out" ]]; then
    echo "have $(basename "$out")"
    return
  fi
  echo "downloading $(basename "$out")"
  curl -fL --retry 3 --retry-delay 2 -o "$out" "$url"
}

fetch "$UE4SS_URL" "$VENDOR/UE4SS-RSDragonwilds.zip"
fetch "$RS_URL" "$VENDOR/RuneSchema.zip"

rm -rf "$VENDOR/ue4ss" "$VENDOR/runeschema"
mkdir -p "$VENDOR/ue4ss" "$VENDOR/runeschema"
unzip -q -o "$VENDOR/UE4SS-RSDragonwilds.zip" -d "$VENDOR/ue4ss"
unzip -q -o "$VENDOR/RuneSchema.zip" -d "$VENDOR/runeschema"

test -f "$VENDOR/ue4ss/Binaries/Win64/dwmapi.dll"
test -d "$VENDOR/runeschema/RuneSchema"
echo "deps ready in $VENDOR"
