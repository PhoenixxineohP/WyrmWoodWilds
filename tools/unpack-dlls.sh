#!/usr/bin/env bash
# Unpack UPX-compressed DLLs in place. Wine cannot load UPX-packed Windows DLLs
# (RuneSchema ships them compressed on the normal Windows package).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIR="${1:?usage: unpack-dlls.sh <directory>}"

UPX="$ROOT/vendor/upx/upx"
if [[ ! -x "$UPX" ]]; then
  UPX="$(command -v upx || true)"
fi
if [[ -z "$UPX" ]]; then
  echo "upx not found; run tools/fetch-deps.sh first" >&2
  exit 1
fi

count=0
while IFS= read -r -d '' dll; do
  if strings -n 3 "$dll" 2>/dev/null | grep -q 'UPX'; then
    if "$UPX" -d "$dll" >/dev/null 2>&1; then
      count=$((count + 1))
    else
      echo "warning: could not unpack $dll" >&2
    fi
  fi
done < <(find "$DIR" -name '*.dll' -print0)

echo "unpacked $count UPX DLL(s) in $DIR"
