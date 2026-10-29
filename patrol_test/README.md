# Real-device UI tests

22 STC suites / 31 selected scenarios. Shared UI driver, page objects and account/profile fixtures are under `support/`. Android runner is configured; iOS has a `RunnerUITests` target and platform-aware navigation. Patrol MCP can build/run the Flutter test bundle on iOS Simulator. STC-02 login form/empty validation passed on iOS Simulator; native Xcode XCTest execution still needs verification.

Setup, fixture contract, selected coverage and current NOT RUN results:
`../../Petty_Bounty_Brain/wiki/final_progress/automated_ui.md`
`../../Petty_Bounty_Brain/wiki/final_progress/automated_ui_record.md`

From the Flutter root, fill ignored `.env.ui.local.json`, then:

```sh
python3 tool/run_ui.py --platform ios --device YOUR_IOS_SIMULATOR_ID --suite STC-02
python3 tool/run_ui.py --platform ios --device YOUR_IOS_SIMULATOR_ID
# Android is also supported:
python3 tool/run_ui.py --platform android --device YOUR_ANDROID_SERIAL
```

Requires the real backend, native device and patrol_cli 4.8.0. Missing fixture values are explicit skips, never passing coverage. Do not run these as widget tests or replace app services with fakes.
