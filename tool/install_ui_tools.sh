#!/usr/bin/env bash
# Run after DNS/network access is available. All tool caches stay project-local.
set -euo pipefail
petty_setup_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
petty_setup_admin="$(cd -- "$petty_setup_root/../PettyBounty_Admin" && pwd)"
petty_setup_env="$petty_setup_root/tool/ui_env.sh"
bash "$petty_setup_env" node -p '"Automation Node: " + process.versions.node'
bash "$petty_setup_env" dart --suppress-analytics pub get
bash "$petty_setup_env" dart --suppress-analytics pub global activate patrol_cli 4.8.0
bash "$petty_setup_env" dart --suppress-analytics pub global activate patrol_mcp 0.2.1
bash "$petty_setup_env" pod install --project-directory="$petty_setup_root/ios"
bash "$petty_setup_env" npm --prefix "$petty_setup_admin" install
bash "$petty_setup_env" "$petty_setup_admin/node_modules/.bin/playwright" install chromium
bash "$petty_setup_env" patrol doctor
bash "$petty_setup_env" patrol build ios --target patrol_test/stc_01_registration_test.dart --debug
bash "$petty_setup_env" "$petty_setup_admin/node_modules/.bin/playwright" --version
