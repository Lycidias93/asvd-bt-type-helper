# Changelog

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
