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

# UPX is needed to strip compression from RuneSchema's DLLs for Wine/Proton.
if [[ ! -x "$VENDOR/upx/upx" ]]; then
  case "$(uname -m)" in
    x86_64|amd64) UPX_URL="https://github.com/upx/upx/releases/download/v5.3.0/upx-5.3.0-amd64_linux.tar.xz" ;;
    aarch64|arm64) UPX_URL="https://github.com/upx/upx/releases/download/v5.3.0/upx-5.3.0-arm64_linux.tar.xz" ;;
    *) UPX_URL="" ;;
  esac
  if [[ -n "$UPX_URL" ]]; then
    fetch "$UPX_URL" "$VENDOR/upx.tar.xz"
    rm -rf "$VENDOR/upx-dir" && mkdir -p "$VENDOR/upx-dir"
    tar xf "$VENDOR/upx.tar.xz" -C "$VENDOR/upx-dir"
    mkdir -p "$VENDOR/upx"
    cp "$(find "$VENDOR/upx-dir" -name upx -type f | head -n1)" "$VENDOR/upx/upx"
    chmod +x "$VENDOR/upx/upx"
  fi
fi

rm -rf "$VENDOR/ue4ss" "$VENDOR/runeschema"
mkdir -p "$VENDOR/ue4ss" "$VENDOR/runeschema"
unzip -q -o "$VENDOR/UE4SS-RSDragonwilds.zip" -d "$VENDOR/ue4ss"
unzip -q -o "$VENDOR/RuneSchema.zip" -d "$VENDOR/runeschema"

test -f "$VENDOR/ue4ss/Binaries/Win64/dwmapi.dll"
test -d "$VENDOR/runeschema/RuneSchema"
echo "deps ready in $VENDOR"
