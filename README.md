# ASVD BT Type Helper

ASVD BT Type Helper is a Magisk/priv-app helper for changing Android Bluetooth device type metadata.

The verified use case is a Bluetooth receiver that Android classified as headphones, causing headphone-style audio behavior. The helper can set Android Bluetooth metadata key `17` to `Carkit`, which made the receiver show as **Auto** in Android Bluetooth settings on the verified reference device.

## Current status

| Area | Status |
|---|---|
| Latest release | `v0.5.4` |
| Runtime model | Magisk `priv-app` helper |
| Normal app support | Not supported |
| Root/Magisk required | Yes |
| Verified phone | Pixel 10 Pro XL / Android 16 / SDK 36 |
| Verified target | `H222` Bluetooth receiver |
| Verified connected-car state | Yes, `metadata_17=Carkit` while H222 is connected |
| GET by name | Verified |
| SET car/Carkit | Verified on the target above |
| Wizard | Available, MAC-redacted by default |
| Debug report | Available, safe for public GitHub/XDA paste by default |
| Online update support | Enabled from `v0.5.3` via Magisk `updateJson` |
| Speaker/headphones metadata | Implemented, still experimental until UI mapping is verified |
| Other phones/OEMs | Unknown / tester feedback needed |

## What it does

- Lists paired Bluetooth devices.
- Reads Bluetooth device metadata key `17`.
- Sets metadata key `17` for one explicitly selected device.
- Supports device selection by unique Bluetooth name or MAC address.
- Provides an interactive setup wizard.
- Provides a redacted debug report for GitHub/XDA support.
- Uses guarded `--confirm-set` and `--confirm-clear` flows for writes.

## What it does not do

- No Google Play Services manipulation.
- No Bluetooth service reload.
- No direct patching of `/data/misc/bluedroid/bt_config.conf`.
- No background daemon.
- No automatic boot-time changes.
- No support for non-root / non-Magisk devices.

## Install

Flash the ZIP in Magisk, reboot, then run:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-grant.sh
```

## Recommended first run

Use the wizard:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-setup.sh
```

The wizard redacts MAC addresses by default. Use `--show-mac` only locally when you need exact MAC targeting.

## Basic commands

List paired devices with redacted MAC addresses:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-list.sh
```

Read a device by name:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-get.sh --name H222
```

Read a device by MAC address:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-get.sh --mac AA:BB:CC:DD:EE:FF
```

Set a device to car/Carkit mode:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-set-type.sh --name H222 --type car --confirm-set
```

Verify after setting:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-get.sh --name H222
```

Expected verified marker for the H222 reference target:

```text
metadata_17_before=Carkit
RESULT: ASVD_BT_TYPE_HELPER_GET_DONE
```

## Debug report for GitHub/XDA

Generate a public-safe debug report:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-debug.sh --name H222
```

The report redacts Bluetooth MAC addresses by default and writes a file to the Download folder.

## Supported type names

| CLI type | Metadata value | Status |
|---|---|---|
| `car`, `auto`, `carkit` | `Carkit` | Verified on H222 |
| `speaker` | `Speaker` | Experimental |
| `headphones` | `Headphones` | Experimental |
| `clear`, `reset`, `null` | clear metadata key 17 | Implemented, use carefully |

## Safety

This is system-level tooling. Use only on devices you can recover. Always verify the target first with `helper-get.sh`. Do not run SET commands against ambiguous device names. Prefer `--mac` when multiple paired devices share the same display name.

## Compatibility

See [`docs/COMPATIBILITY.md`](docs/COMPATIBILITY.md).

## Testing and release workflow

See [`docs/TESTING.md`](docs/TESTING.md) and [`docs/WORKFLOW.md`](docs/WORKFLOW.md).

<!-- online-update-support-start -->
## Online updates

Online update support starts with `v0.5.3`; latest stable release is `v0.5.4`.

The Magisk module contains:

```text
updateJson=https://raw.githubusercontent.com/Lycidias93/asvd-bt-type-helper/main/update.json
```

The repository root contains `update.json`, which points Magisk to the latest stable release ZIP and changelog. Magisk compares `versionCode`; `v0.5.3` uses `versionCode=53`.
<!-- online-update-support-end -->

<!-- v054-user-friendly-ux-start -->
## User-friendly UX in v0.5.4

`v0.5.4` adds a one-command entry point and safe dry-run checks:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/asvd.sh
```

Useful support commands:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-doctor.sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-update-info.sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-setup.sh --dry-run
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-set-type.sh --name H222 --type car --dry-run
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-clear-type.sh --name H222 --dry-run
```

Dry-run mode resolves the target and prints the planned action, but reports `write_performed=no` and does not change Bluetooth metadata.
<!-- v054-user-friendly-ux-end -->
