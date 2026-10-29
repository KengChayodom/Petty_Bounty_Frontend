#!/usr/bin/env bash
# Prefer a supported standalone Node. Use an existing editor's Node runtime only as fallback.
set -euo pipefail
petty_node_check='const [m,n]=process.versions.node.split(".").map(Number);process.exit((m===22&&n>=18)||(m===24&&n>=12)||m>24?0:1)'
if [[ -n "${UI_NODE_BINARY:-}" ]]; then
  "$UI_NODE_BINARY" -e "$petty_node_check"
  exec "$UI_NODE_BINARY" "$@"
fi
for petty_node_bin in /opt/homebrew/bin/node /usr/local/bin/node /usr/bin/node; do
  if [[ -x "$petty_node_bin" ]] && "$petty_node_bin" -e "$petty_node_check"; then
    exec "$petty_node_bin" "$@"
  fi
done
petty_editor_node='/Applications/Visual Studio Code.app/Contents/MacOS/Code'
if [[ -x "$petty_editor_node" ]] && ELECTRON_RUN_AS_NODE=1 "$petty_editor_node" -e "$petty_node_check"; then
  export ELECTRON_RUN_AS_NODE=1
  exec "$petty_editor_node" "$@"
fi
echo 'A compatible Node (^22.18.0 or >=24.12.0) is required; set UI_NODE_BINARY to its executable.' >&2
exit 2
