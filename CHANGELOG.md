# Changelog

## Unreleased

- Fixed `update.json` changelog metadata to use raw Markdown instead of a GitHub HTML release page.

## v0.6.1 - 2026-05-16

- Fixed Pixel/Termux root-shell broadcast failures by detaching `am broadcast` from the Termux PTY.
- Avoided direct framework command output to `/dev/pts/0` in helper preflights where helper-common is available.
- Hardened `helper-get.sh` with `request_id` polling and strict GET result validation.
- Fixed false-positive GET wrapper success when no fresh result file exists.
- Hardened `helper-doctor.sh` so GET smoke failures count as failures.
- No Bluetooth metadata write behavior changed.

## v0.6.0 - 2026-05-16

- Fixed setup wizard stale result handling where a `GET` result file could be parsed as `LIST` output, causing false `no_devices_parsed`.
- Added `request_id` to helper broadcasts and result files.
- Added strict LIST result validation for Wizard/List flows:
  - expected action is `org.asvd.bttypehelper.LIST`
  - expected marker is `RESULT: ASVD_BT_TYPE_HELPER_LIST_DONE`
  - at least one `-- device` block must be present
- Replaced fixed 2-second LIST sleeps with short polling for the matching result file.
- Added clearer failure output with `action`, `expected`, `device_blocks`, and `bonded_count_seen`.
- Extended `helper-doctor.sh` with LIST parse / Wizard smoke.
- Kept metadata write behavior unchanged; H222 remains correct when `metadata_17=Carkit`.
- Kept root out of the APK; no root broker or automatic Bluetooth metadata writes were added.


## v0.5.9 - 2026-05-14

- Added improved duplicate-safe picker UX.
- Added `candidate_id`, `source_index`, `last_connected`, `dev_type`, `dev_class`, and `likely_current_media` display fields.
- Stored duplicate-picker metadata in `picked-device.env`.
- Updated picked-device dry-run output to show selected candidate context before writing.
- Preserved MAC redaction by default.
- Kept duplicate-name writes guarded and non-guessing.
- Skipped unreleased v0.5.8 as an internal test build.

## v0.5.9 - 2026-05-14

- Added improved duplicate-safe picker UX.
- Added `candidate_id`, `source_index`, `last_connected`, `dev_type`, `dev_class`, and `likely_current_media` display fields.
- Stored duplicate-picker metadata in `picked-device.env`.
- Updated picked-device dry-run output to show selected candidate context before writing.
- Preserved MAC redaction by default.
- Kept duplicate-name writes guarded and non-guessing.
- Skipped unreleased v0.5.8 as an internal test build.

## v0.5.9 - 2026-05-14

- Added improved duplicate-safe picker UX.
- Added `candidate_id`, `source_index`, `last_connected`, `dev_type`, `dev_class`, and `likely_current_media` display fields.
- Stored duplicate-picker metadata in `picked-device.env`.
- Updated picked-device dry-run output to show selected candidate context before writing.
- Preserved MAC redaction by default.
- Kept duplicate-name writes guarded and non-guessing.
- Skipped unreleased v0.5.8 as an internal test build.

## v0.5.9 - 2026-05-14

- Added improved duplicate-safe picker UX.
- Added `candidate_id`, `source_index`, `last_connected`, `dev_type`, `dev_class`, and `likely_current_media` display fields.
- Stored duplicate-picker metadata in `picked-device.env`.
- Updated picked-device dry-run output to show selected candidate context before writing.
- Preserved MAC redaction by default.
- Kept duplicate-name writes guarded and non-guessing.
- Skipped unreleased v0.5.8 as an internal test build.

## v0.5.6 - 2026-05-13

- Added sanitized ASVD companion shared-state file at `/data/adb/asvd/bt-helper.env`.
- Added atomic state writes via temporary file and rename.
- Added helper version/package/target/requested type/last result fields for ASVD v1.2.6 verify reports.
- Kept raw Bluetooth MAC addresses out of shared state and public output.
- Added explicit opt-in `--asvd-apply-now`; no automatic ASVD run by default.
- Kept Bluetooth metadata/API workflow only; no GMS-disable/offline-UI mode and no `bt_config.conf` patching.
- Verified H222 remains `metadata_17=Carkit` and ASVD v1.2.6 verify reports companion state.

## v0.5.5 - 2026-05-13

Stable release: Type Expansion + Restore Safety.

- Added all known Android Bluetooth metadata key 17 device type values.
- Added aliases for car, speaker, headset/headphones, untethered headset/TWS/earbuds, watch, stylus, hearing aid, default and clear.
- Corrected `headphones` alias to write `Headset`.
- Added backup-before-write support for confirmed SET/CLEAR flows.
- Added `helper-restore-last.sh`.
- Added `helper-compare-types.sh`.
- Expanded setup wizard type menu.
- Verified v0.5.5 postflash smoke v2 with H222 still `metadata_17=Carkit`.


## v0.5.4 - 2026-05-12

User-friendly UX and safety release.

- Added `asvd.sh` as the central one-command menu.
- Added `helper-doctor.sh` for support diagnostics.
- Added `helper-update-info.sh` for local online-update metadata checks.
- Added real dry-run support for setup, set-type, clear-type, and config apply flows.
- Improved setup wizard wording, cancellation, duplicate-name hints, and redacted output.
- Kept Bluetooth Java runtime behavior unchanged compared with v0.5.3.
- Verified v0.5.4 post-flash smoke on the reference Pixel setup:
  - wizard dry-run lists H222 and redacts MACs
  - set-type dry-run reports `write_performed=no`
  - clear dry-run reports `write_performed=no`
  - H222 remains `metadata_17=Carkit`
- Fixed Android `/system/bin/awk` compatibility issues in the setup wizard:
  - multiline `printf` string issue
  - reserved/conflicting variable name `exp`

## v0.5.3 - 2026-05-12

Stable release adding Magisk online update metadata.

- Added `updateJson=https://raw.githubusercontent.com/Lycidias93/asvd-bt-type-helper/main/update.json` to `module.prop`.
- Added repository `update.json` for Magisk online update checks.
- Verified `update.json` schema and release asset SHA256.
- No Bluetooth runtime behavior changes compared with v0.5.2.
- H222 remains verified as `metadata_17=Carkit` on the reference Pixel setup.
- Documented two build/workflow failure patterns:
  - stale hardcoded workdir paths in generated build scripts
  - Pixel post-flash checks hanging when repeatedly invoking `tsu` / `dumpsys` from `cgrun`


<!-- since-prerelease-start -->
## Changes since v0.4.15 pre-release

This stable release includes all changes made after the v0.4.15 pre-release:

### v0.5.0

- Added the first user-friendly interactive setup wizard.
- Added `helper-report.sh` for redacted support reports.
- Added `/data/adb/asvd-bt-type-helper.conf` support.
- Added `helper-apply-config.sh` for config-based application.
- Added `helper-clear-type.sh` with guarded `--confirm-clear`.
- Kept the safety model: no SET without explicit confirmation.
- Known issue in v0.5.0: APK `versionName` still reported `0.4.15` although runtime/build output was v0.5.0.

### v0.5.1

- Fixed APK manifest version reporting: `versionCode=51`, `versionName=0.5.1`.
- Added generic `SET_TYPE` handling.
- Added guarded type mappings:
  - `car` / `carkit` / `auto` -> `Carkit`
  - `speaker` -> `Speaker` experimental
  - `headphones` -> `Headphones` experimental
  - `clear` -> metadata clear flow
- Updated setup/config helpers for the expanded type model.
- Verified H222 remained `metadata_17=Carkit` after upgrade.

### v0.5.2

- Promoted the project from pre-release to stable release.
- Fixed setup wizard privacy: MAC addresses are redacted by default.
- Added `helper-debug.sh` for public-safe GitHub/XDA reports.
- Added `safe_to_paste_publicly=yes` guidance in debug output.
- Verified v0.5.2 post-flash state:
  - `versionCode=52`
  - `versionName=0.5.2`
  - package path `/system/priv-app/AsvdBtTypeHelper/AsvdBtTypeHelper.apk`
  - H222 connected-car state remains `metadata_17=Carkit`
- Kept speaker/headphones support experimental until UI mapping is verified on reference devices.

<!-- since-prerelease-end -->

## v0.5.2 - 2026-05-12

Stable release.

- Fixed public wizard UX: MAC addresses are redacted by default.
- Added `helper-debug.sh` for public-safe GitHub/XDA reports.
- Added `safe_to_paste_publicly` guidance in debug output.
- Verified post-flash package state: `versionCode=52`, `versionName=0.5.2`.
- Verified H222 connected-car state remains `metadata_17=Carkit`.
- Kept write safety: no SET without `--confirm-set`, no CLEAR without `--confirm-clear`.
- Speaker/headphones type values are available but remain experimental until UI mapping is confirmed on reference devices.


## v0.4.15 - pre-release

- Added guarded Magisk installer cleanup for temporary `/data/app` parse-test installs.
- Kept existing `/system` / `priv-app` package paths intact during install.
- Kept helper scripts on absolute `/system/bin/...` command paths.
- Kept `helper-set-type.sh` guarded by `--confirm-set`.
- Verified H222 metadata remains `Carkit` after reboot on the reference Pixel setup.

## v0.4.14

- Added `helper-list.sh`.
- Added name and MAC target selection support.
- Added `helper-set-type.sh` with `--type car` / `auto` / `carkit` mapping to `Carkit`.
- Added redacted default MAC output and local `--show-mac` mode.

## v0.4.13

- Fixed helper wrappers to use absolute `/system/bin/...` commands.
- Verified GET wrapper path with H222.
- Verified Carkit metadata persisted for H222.

## v0.4.12

- Removed `/data/local/tmp` write fallback to avoid SELinux EACCES noise.
- Improved broadcast result-data and logcat diagnostics.

## v0.4.11

- Added diagnostic logcat tag `ASVD-BT-HELPER`.
- Added broadcast result-data output.
- Verified privileged GET path for H222.

## v0.4.10

- First APK-valid Magisk priv-app build with APK Signature Scheme v3.

## v0.4.x earlier

- Research builds for on-device APK packaging, manual binary AndroidManifest generation, privileged permission allowlist, and Bluetooth metadata access.

## v0.5.7 - Action Button and current/last Bluetooth device views

- Added Magisk Action Button support via `action.sh`.
- Added read-only Action Button report to Download.
- Added `helper-connected-devices.sh`.
- Added `helper-last-devices.sh` for last connected and last devices summaries.
- Added main-menu entries for currently connected devices, last connected hints, and last devices summary.
- Improved MAC and partial-MAC redaction for Android dumpsys output.
- Confirmed H222 remains `metadata_17=Carkit` after smoke.

<!-- CHANGELOG_ASVD_BT_HELPER_V064_ROOT_BRIDGE_START -->
## 0.6.4 - Android 17 root bridge

- Added root-side Binder bridge for Bluetooth metadata key `17` GET/SET.
- Added root bridge helpers for get/list/set/carkit/clear/doctor.
- Removed APK dependency from the v0.6.4 module payload.
- Verified on Pixel Android 17 with temporary type mutation and restore: `Carkit -> Speaker -> Carkit`.
- Kept Bluetooth MAC addresses out of release notes and repo docs.
<!-- CHANGELOG_ASVD_BT_HELPER_V064_ROOT_BRIDGE_END -->
