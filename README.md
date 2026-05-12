# ASVD BT Type Helper

Experimental Bluetooth device type metadata helper for Android/Magisk.

This project is a separate research/prototype repository for the Audio Safe Volume Disabler ecosystem. It is intentionally separate from the main ASVD module until the helper is proven safe and reproducible.

## Current status

Verified baseline so far:

- Device: Google Pixel 10 Pro XL
- Android: 16 / SDK 36
- Root: Magisk
- Helper prototype: v0.4.11
- Install mode: Magisk priv-app
- Permissions: `BLUETOOTH_CONNECT` and `BLUETOOTH_PRIVILEGED` granted
- Read-only H222 lookup: works
- `BluetoothDevice.getMetadata(17)` for H222: works and currently returns `null`
- `setMetadata(17, "Carkit")`: not yet verified

## Scope

The helper is manual and experimental.

It does:

- install a small privileged helper APK through Magisk
- expose a manual broadcast receiver
- read Bluetooth device metadata for a named bonded device
- later test writing device type metadata, only after read-only checks pass

It does **not**:

- disable or manipulate Google Play Services
- reload Bluetooth automatically
- run a boot service
- patch `/data/misc/bluedroid/bt_config.conf`
- modify ASVD runtime audio behavior

## Safety rules

Use read-only mode first. Do not run the set command until the read-only output is confirmed.

Rejected paths:

- Google Play Services disable/offline UI unlock path
- direct `bt_config.conf` editing
- automatic boot fixes
- Bluetooth reload during active playback

## Build

From Termux on the device:

```sh
cd /storage/emulated/0/Download
chmod +x ./build_asvd_bt_type_helper_privapp_v051.sh
bash ./build_asvd_bt_type_helper_privapp_v051.sh
```

Expected artifact:

```text
/storage/emulated/0/Download/ASVD-BT-Type-Helper-v0.4.11.zip
```

## Install

Flash the ZIP in Magisk, then reboot.

After reboot:

```sh
tsu /system/bin/pm path org.asvd.bttypehelper
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-grant.sh
```

## Read-only check

```sh
tsu /system/bin/am broadcast \
  --user 0 \
  --include-stopped-packages \
  --receiver-foreground \
  -n org.asvd.bttypehelper/.BtTypeReceiver \
  -a org.asvd.bttypehelper.GET \
  --es name H222
```

Known successful read-only result includes:

```text
onReceive_enter=yes
target_name=H222
bonded_count=20
target_matches=1
name=H222
type=1
majorDeviceClass=1024
deviceClass=1028
metadata_17_before=null
RESULT: ASVD_BT_TYPE_HELPER_GET_DONE
```

## Roadmap

- v0.4.12: improve wrapper output by reading broadcast result data/logcat reliably
- v0.4.12: remove noisy fallback write to `/data/local/tmp`
- v0.4.12: confirm `SET_CARKIT` action visibility before any write test
- v0.5.0: first controlled `setMetadata(17, "Carkit")` test if read-only remains stable

## Rollback

Remove the module in Magisk and reboot.

CLI fallback:

```sh
tsu touch /data/adb/modules/asvd-bt-type-helper/remove
reboot
```
