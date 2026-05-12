# Testing

## Reference setup

- Pixel 10 Pro XL
- Android 16 / SDK 36
- Magisk 30700 alpha
- Target: H222 Bluetooth receiver

## Verified release: v0.5.3

Post-flash online-update/runtime verification passed on 2026-05-12.

Verified markers:

```text
versionCode=53
versionName=0.5.3
package:/system/priv-app/AsvdBtTypeHelper/AsvdBtTypeHelper.apk
metadata_17_before=Carkit
RESULT: ASVD_BT_TYPE_HELPER_GET_DONE
updateJson=https://raw.githubusercontent.com/Lycidias93/asvd-bt-type-helper/main/update.json
RESULT: ASVD_BT_TYPE_HELPER_DEBUG_DONE
RESULT: ASVD_BT_TYPE_HELPER_DEBUG_FILE_WRITTEN
RESULT: ASVD_BT_TYPE_HELPER_V053_POSTFLASH_AIO_DONE
```

## Build and parse-test gate

```sh
cgrun 'set -euo pipefail
cd /storage/emulated/0/Download
sha256sum -c build_asvd_bt_type_helper_privapp_v059.sh.sha256
bash -n ./build_asvd_bt_type_helper_privapp_v059.sh
chmod +x ./build_asvd_bt_type_helper_privapp_v059.sh
bash ./build_asvd_bt_type_helper_privapp_v059.sh
SRC="$HOME/asvd-bt-type-helper-v059/AsvdBtTypeHelper.apk"
DST="/data/local/tmp/AsvdBtTypeHelper-v0.5.3.apk"
tsu /system/bin/cp "$SRC" "$DST"
tsu /system/bin/chmod 0644 "$DST"
tsu /system/bin/pm install -r -d "$DST"
echo RESULT: ASVD_BT_TYPE_HELPER_V053_BUILD_PARSE_AIO_DONE
'
```

## Post-flash debug gate

```sh
cgrun 'set -euo pipefail
MOD="/data/adb/modules/asvd-bt-type-helper"
PKG="org.asvd.bttypehelper"
tsu /system/bin/pm path "$PKG"
tsu /system/bin/dumpsys package "$PKG" | /system/bin/grep -Ei "versionCode|versionName|PRIVILEGED|BLUETOOTH|granted"
printf "q
" | tsu /system/bin/sh "$MOD/helper-setup.sh"
tsu /system/bin/sh "$MOD/helper-debug.sh" --name H222
tsu /system/bin/sh "$MOD/helper-get.sh" --name H222
echo RESULT: ASVD_BT_TYPE_HELPER_V053_POSTFLASH_AIO_DONE
'
```

## Safety notes

- Do not test `speaker`, `headphones`, or `clear` on H222 while the car profile is needed.
- Test speaker/headphones mapping later on non-critical reference devices.
- `helper-debug.sh` output is designed to be safe for public GitHub/XDA reports.

<!-- v053-online-update-test-start -->
## v0.5.3 online update test

Verified local release asset metadata for `v0.5.3`:

```text
version=0.5.3
versionCode=53
zipUrl=https://github.com/Lycidias93/asvd-bt-type-helper/releases/download/v0.5.3/ASVD-BT-Type-Helper-v0.5.3.zip
changelog=https://github.com/Lycidias93/asvd-bt-type-helper/releases/tag/v0.5.3
```

Post-flash runtime remained healthy on the reference device with H222 `metadata_17=Carkit`.
<!-- v053-online-update-test-end -->
