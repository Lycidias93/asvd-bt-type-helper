# ASVD BT Type Helper v0.5.7

Stable release for Action Button support and current/last Bluetooth device views.

## Highlights

- Added Magisk Action Button support via `action.sh`.
- Added read-only Action Button report written to the Download folder.
- Added `helper-connected-devices.sh` for currently connected Bluetooth device hints.
- Added `helper-last-devices.sh` for last connected / last device summaries.
- Added current/last device views to `asvd.sh` main menu.
- Action report includes shared ASVD state, doctor output, currently connected devices, last connected hints, last devices summary, and metadata type overview.
- Improved MAC redaction for raw and partially masked Android dumpsys addresses.
- No metadata write is performed by the Action Button.
- No Bluetooth reload, no GMS/offline-UI path, no `bt_config.conf` patching.

## Verified reference setup

- Pixel 10 Pro XL / Android 16 / Magisk
- Package: `org.asvd.bttypehelper`
- Version: `0.5.7` / versionCode `57`
- H222 remains `metadata_17=Carkit`
- Currently connected devices smoke: PASS
- Last connected BT hints smoke: PASS
- Last devices summary smoke: PASS
- Action report smoke: PASS
- MAC / partial-MAC redaction smoke: PASS

## Install

Flash `ASVD-BT-Type-Helper-v0.5.7.zip` in Magisk and reboot.
