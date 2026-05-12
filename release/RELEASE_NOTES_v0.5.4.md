# ASVD BT Type Helper v0.5.4

Stable user-friendly UX and safety release.

## Changes since v0.5.3

- Added `asvd.sh` as the central one-command menu.
- Added `helper-doctor.sh` for diagnostics and support.
- Added `helper-update-info.sh` for online-update metadata checks.
- Added dry-run support for setup, set-type, clear-type, and config apply flows.
- Improved setup wizard output, cancellation flow, duplicate-name hints, and MAC redaction.
- Fixed Android `/system/bin/awk` compatibility issues in the wizard output formatter.
- No Bluetooth Java runtime behavior changed compared with v0.5.3.

## Online update metadata

```json
{
  "version": "0.5.4",
  "versionCode": 54,
  "zipUrl": "https://github.com/Lycidias93/asvd-bt-type-helper/releases/download/v0.5.4/ASVD-BT-Type-Helper-v0.5.4.zip",
  "changelog": "https://github.com/Lycidias93/asvd-bt-type-helper/releases/tag/v0.5.4"
}
```

## Verified reference setup

- Pixel 10 Pro XL
- Android 16 / SDK 36
- Magisk 30700 alpha
- H222 Bluetooth receiver
- H222 remains `metadata_17=Carkit`

## Verified smoke markers

```text
PASS setup_dryrun_mac_redacted
PASS setup_dryrun_cancelled
PASS setup_dryrun_h222_listed
PASS set_type_dry_run
PASS clear_dry_run
PASS h222_still_carkit
RESULT: ASVD_BT_TYPE_HELPER_V054_USER_FRIENDLY_POSTFLASH_SMOKE_V2_DONE
```

## Install

Flash `ASVD-BT-Type-Helper-v0.5.4.zip` in Magisk and reboot.

Recommended first command after reboot:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/asvd.sh
```

## Dry-run examples

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-setup.sh --dry-run
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-set-type.sh --name H222 --type car --dry-run
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-clear-type.sh --name H222 --dry-run
```

Dry-run mode prints the planned action and reports `write_performed=no`.

## Limitations

- Root/Magisk required.
- Non-root installs are unsupported.
- OEM behavior is not guaranteed.
- Speaker/headphones metadata values remain experimental until UI mapping is confirmed on reference devices.
