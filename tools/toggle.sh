#!/usr/bin/env bash
# Toggle one feature on/off and re-sync the installed mod list.
#   ./tools/toggle.sh list
#   ./tools/toggle.sh WW_Storage off
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FEATURES="$ROOT/features.conf"

if [[ "${1:-}" == "list" || $# -eq 0 ]]; then
  grep -vE '^[[:space:]]*(#|$)' "$FEATURES" | sed -E 's/^([^=]+)=(.*)$/\1  \2/'
  exit 0
fi

NAME="$1"
STATE="${2:-}"
if [[ "$STATE" != "on" && "$STATE" != "off" ]]; then
  echo "usage: $0 <feature> on|off" >&2
  exit 1
fi
if ! grep -qE "^${NAME}=" "$FEATURES"; then
  echo "unknown feature: $NAME (use '$0 list')" >&2
  exit 1
fi

sed -i -E "s/^(${NAME}=).*/\1${STATE}/" "$FEATURES"
bash "$ROOT/tools/sync-mods.sh"
