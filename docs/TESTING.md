# Testing notes

## Known good read-only test

```sh
tsu /system/bin/am broadcast \
  --user 0 \
  --include-stopped-packages \
  --receiver-foreground \
  -n org.asvd.bttypehelper/.BtTypeReceiver \
  -a org.asvd.bttypehelper.GET \
  --es name H222
```

Successful output is visible as broadcast result data in ActivityManager/logcat.

## Do not run yet

Do not run `helper-set-carkit.sh` until the repository contains a version that surfaces write result data reliably and confirms `SET_CARKIT` registration.

## Useful checks

```sh
tsu /system/bin/pm path org.asvd.bttypehelper
tsu /system/bin/dumpsys package org.asvd.bttypehelper | grep -Ei 'versionName|versionCode|PRIVILEGED|BLUETOOTH|granted'
tsu /system/bin/dumpsys package org.asvd.bttypehelper | grep -Ei 'SET_CARKIT|GET|BtTypeReceiver' | sed -n '1,120p'
```
