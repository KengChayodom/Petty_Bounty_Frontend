#!/usr/bin/env bash
# Run a command with this workspace's automation toolchain. No shell/global settings change.
set -euo pipefail
petty_ui_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
petty_ui_tools="$petty_ui_root/.ui-tools"
export PUB_CACHE="$petty_ui_tools/pub-cache"
export ANDROID_USER_HOME="$petty_ui_tools/android-user"
export ANDROID_AVD_HOME="$ANDROID_USER_HOME/avd"
export ANDROID_EMULATOR_HOME="$ANDROID_USER_HOME"
export PLAYWRIGHT_BROWSERS_PATH="$petty_ui_tools/playwright"
export npm_config_cache="$petty_ui_tools/npm-cache"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
if [[ -d '/Applications/Android Studio.app/Contents/jbr/Contents/Home' ]]; then
  export JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home'
fi
if [[ ! -x "$petty_ui_tools/flutter/bin/flutter" ]]; then
  echo 'Project-local Flutter SDK is missing; see tool/UI_ENVIRONMENT.md.' >&2
  exit 2
fi
export FLUTTER_ROOT="$petty_ui_tools/flutter"
export PATROL_FLUTTER_COMMAND="$FLUTTER_ROOT/bin/flutter"
export PATH="$petty_ui_tools/node/bin:$PUB_CACHE/bin:$FLUTTER_ROOT/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
if [[ $# -eq 0 ]]; then
  echo 'Usage: bash tool/ui_env.sh COMMAND [ARGS...]' >&2
  exit 2
fi
exec "$@"
