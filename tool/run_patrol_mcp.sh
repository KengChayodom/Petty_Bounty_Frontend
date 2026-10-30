#!/usr/bin/env bash
set -euo pipefail
petty_mcp_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export PROJECT_ROOT="$petty_mcp_root"
export SHOW_TERMINAL=false
if [[ -f "$petty_mcp_root/.env.ui.local.json" ]]; then
  export PATROL_FLAGS="${PATROL_FLAGS:+$PATROL_FLAGS }--dart-define-from-file=.env.ui.local.json"
fi
cd "$petty_mcp_root"
exec bash tool/ui_env.sh dart --suppress-analytics run patrol_mcp
