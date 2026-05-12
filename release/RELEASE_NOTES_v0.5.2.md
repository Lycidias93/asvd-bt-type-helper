# ASVD BT Type Helper v0.5.2

<!-- since-prerelease-start -->
## Changes since v0.4.15 pre-release

- v0.5.0 added the interactive setup wizard, redacted report flow, config support, guarded clear/reset support, and config apply helper.
- v0.5.1 fixed the APK manifest versionName and added generic guarded type handling for `car`, `speaker`, `headphones`, and `clear`.
- v0.5.2 fixes public wizard privacy, adds `helper-debug.sh` for GitHub/XDA support, and is the first stable release.
- Verified stable reference state: Pixel 10 Pro XL / Android 16 / Magisk alpha / H222 connected in car / `metadata_17=Carkit`.
- `car` / `Carkit` is verified on H222. `speaker` and `headphones` remain experimental until UI mapping is confirmed on reference devices.

<!-- since-prerelease-end -->

Stable release of the ASVD BT Type Helper Magisk/priv-app module.

## Verified reference setup

- Pixel 10 Pro XL
- Android 16 / SDK 36
- Magisk 30700 alpha
- H222 Bluetooth receiver

## Highlights

- Interactive setup wizard.
- MAC addresses redacted by default in wizard/debug output.
- Public-safe GitHub/XDA debug report via `helper-debug.sh`.
- Verified H222 connected-car state: `metadata_17=Carkit`.
- Corrected package version: `versionCode=52`, `versionName=0.5.2`.
- Supports targeting by unique name or MAC address.
- Supports guarded type operations:
  - `car` / `carkit` / `auto` -> `Carkit` verified on H222
  - `speaker` -> experimental
  - `headphones` -> experimental
  - `clear` -> implemented, use carefully

## Install

Flash `ASVD-BT-Type-Helper-v0.5.2.zip` in Magisk and reboot.

After reboot:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-grant.sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-setup.sh
```

## Debug report

For GitHub/XDA support:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-debug.sh --name H222
```

The debug report redacts MAC addresses by default.

## Limitations

- Root/Magisk required.
- Non-root installs are unsupported.
- OEM behavior is not guaranteed.
- Other phones and Android versions need tester feedback.
- Speaker/headphones metadata values are included but not yet UI-verified.
