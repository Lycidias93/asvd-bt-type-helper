# ASVD BT Type Helper

Experimental Magisk/priv-app helper for changing Android Bluetooth device type metadata.

The current verified use case is a Bluetooth receiver that Android classified as headphones, causing headphone-style audio behavior. The helper can set Android Bluetooth metadata key `17` to `Carkit`, which made the device show as **Auto** in Android's Bluetooth device settings on the verified test device.

## Current status

| Area | Status |
|---|---|
| Latest pre-release | `v0.4.15` |
| Runtime model | Magisk `priv-app` helper |
| Normal app support | Not supported |
| Root/Magisk required | Yes |
| Verified phone | Pixel 10 Pro XL / Android 16 / SDK 36 |
| Verified target | `H222` BT receiver |
| GET by name | Verified |
| SET car/Carkit | Verified on the target above |
| Other phones/OEMs | Unknown / tester feedback needed |

## What it does

- Lists paired Bluetooth devices.
- Reads Bluetooth device metadata key `17`.
- Sets metadata key `17` to `Carkit` for one explicitly selected device.
- Supports device selection by unique Bluetooth name or MAC address.
- Uses a guarded `--confirm-set` flow for writes.

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

## Basic usage

List paired devices with redacted MAC addresses:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-list.sh
```

Show full MAC addresses locally:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-list.sh --show-mac
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

Expected verified marker:

```text
metadata_17_before=Carkit
RESULT: ASVD_BT_TYPE_HELPER_GET_DONE
```

## Safety

This is experimental system-level tooling. Use only on devices you can recover. Always verify the target device first with `helper-get.sh`. Do not run SET commands against ambiguous device names. Prefer `--mac` when multiple paired devices may share the same display name.

## Compatibility

See [`docs/COMPATIBILITY.md`](docs/COMPATIBILITY.md).

## Testing and release workflow

See [`docs/TESTING.md`](docs/TESTING.md) and [`docs/WORKFLOW.md`](docs/WORKFLOW.md).
