# Changelog

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
