# ASVD BT Type Helper v0.5.3

Stable release adding Magisk online update support.

## Changes since v0.5.2

- Added `updateJson=https://raw.githubusercontent.com/Lycidias93/asvd-bt-type-helper/main/update.json` to `module.prop`.
- Added repository `update.json` for Magisk online update checks.
- Build output includes `update.json` next to ZIP/SHA assets.
- No Bluetooth runtime behavior changed compared with v0.5.2.
- H222 remains verified as connected car with `metadata_17=Carkit` on the reference Pixel setup.

## Online update metadata

```json
{
  "version": "0.5.3",
  "versionCode": 53,
  "zipUrl": "https://github.com/Lycidias93/asvd-bt-type-helper/releases/download/v0.5.3/ASVD-BT-Type-Helper-v0.5.3.zip",
  "changelog": "https://github.com/Lycidias93/asvd-bt-type-helper/releases/tag/v0.5.3"
}
```

## Verified reference setup

- Pixel 10 Pro XL
- Android 16 / SDK 36
- Magisk 30700 alpha
- H222 Bluetooth receiver

## Install

Flash `ASVD-BT-Type-Helper-v0.5.3.zip` in Magisk and reboot.

After reboot:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-grant.sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-setup.sh
```

## Debug report

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-debug.sh --name H222
```

MAC addresses are redacted by default.

## Limitations

- Root/Magisk required.
- Non-root installs are unsupported.
- OEM behavior is not guaranteed.
- Speaker/headphones metadata values remain experimental until UI mapping is confirmed on reference devices.
