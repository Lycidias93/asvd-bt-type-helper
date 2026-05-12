# ASVD BT Type Helper v0.4.15 pre-release

Experimental Magisk/priv-app helper for Android Bluetooth device type metadata.

## Status

This is a pre-release. It is verified on one reference setup only:

- Pixel 10 Pro XL
- Android 16 / SDK 36
- Magisk rooted
- H222 Bluetooth receiver

## Highlights

- Verified `GET` path for H222.
- Verified H222 metadata key `17` set to `Carkit`.
- Android Bluetooth UI shows the target as Auto on the verified setup.
- Added `helper-list.sh`.
- Added targeting by unique name or MAC address.
- Added guarded `helper-set-type.sh --type car --confirm-set`.
- Added guarded Magisk install cleanup for temporary `/data/app` parse-test installs.
- Helper scripts use absolute `/system/bin/...` commands.

## Install

Flash `ASVD-BT-Type-Helper-v0.4.15.zip` in Magisk and reboot.

After reboot:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-grant.sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-list.sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-get.sh --name H222
```

## Set car type

Only after GET identifies exactly one target:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-set-type.sh --name H222 --type car --confirm-set
```

## Limitations

- Root/Magisk required.
- Non-root installs are unsupported.
- OEM behavior is not guaranteed.
- Other devices and Android versions need tester feedback.
