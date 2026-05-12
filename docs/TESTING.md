# Testing

## Release candidate gate

Run in this order:

```sh
cd /storage/emulated/0/Download
bash ./build_asvd_bt_type_helper_privapp_v055.sh
```

Expected:

```text
RESULT: ASVD_BT_TYPE_HELPER_PRIVAPP_V055_BUILD_DONE
```

## APK parse/update test

Before flashing, test the APK as a temporary user app:

```sh
SRC="$HOME/asvd-bt-type-helper-v055/AsvdBtTypeHelper.apk"
DST="/data/local/tmp/AsvdBtTypeHelper-v0.4.15.apk"
PKG="org.asvd.bttypehelper"

tsu /system/bin/cp "$SRC" "$DST"
tsu /system/bin/chmod 0644 "$DST"
tsu /system/bin/pm install -r -d "$DST"
tsu /system/bin/pm path "$PKG"
```

Expected:

```text
Success
package:/data/app/...
```

The Magisk installer for v0.4.15 removes this temporary `/data/app` install automatically when flashing. Manual cleanup remains safe:

```sh
tsu /system/bin/pm uninstall org.asvd.bttypehelper || true
```

## After flashing and reboot

```sh
tsu /system/bin/pm path org.asvd.bttypehelper
tsu /system/bin/dumpsys package org.asvd.bttypehelper | /system/bin/grep -Ei 'versionName|versionCode|PRIVILEGED|BLUETOOTH|granted'
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-get.sh --name H222
```

Expected for the verified reference target:

```text
package:/system/priv-app/AsvdBtTypeHelper/AsvdBtTypeHelper.apk
versionCode=15
versionName=0.4.15
android.permission.BLUETOOTH_PRIVILEGED: granted=true
metadata_17_before=Carkit
RESULT: ASVD_BT_TYPE_HELPER_GET_DONE
RESULT: ASVD_BT_TYPE_HELPER_GET_WRAPPER_DONE
```

## AIO maintainer check

The maintainer workflow prefers one bundled check with clear `RESULT:` markers. In Termux setups that provide `cgrun`:

```sh
cgrun 'set -euo pipefail
PKG="org.asvd.bttypehelper"
MOD="/data/adb/modules/asvd-bt-type-helper"

echo "== package =="
tsu /system/bin/pm path "$PKG"

echo "== package details =="
tsu /system/bin/dumpsys package "$PKG" | /system/bin/grep -Ei "versionName|versionCode|PRIVILEGED|BLUETOOTH|granted"

echo "== helper get =="
tsu /system/bin/sh "$MOD/helper-get.sh" --name H222

echo "RESULT: ASVD_BT_TYPE_HELPER_AIO_CHECK_DONE"
'
```

## SET test

Only run after GET is clean and the target is unambiguous:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-set-type.sh --name H222 --type car --confirm-set
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-get.sh --name H222
```

Expected:

```text
metadata_17_before=Carkit
RESULT: ASVD_BT_TYPE_HELPER_GET_DONE
```
