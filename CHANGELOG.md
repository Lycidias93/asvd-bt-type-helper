# Changelog

## v0.4.11

- First working privileged APK install on Pixel Android 16.
- APK is parseable and v3 signed.
- Priv-app install path works through Magisk.
- `BLUETOOTH_CONNECT` and `BLUETOOTH_PRIVILEGED` are granted.
- Read-only `GET` broadcast works.
- H222 is uniquely found among bonded devices.
- `getMetadata(17)` works and returns `null` for H222.
- Known issue: helper wrapper does not yet surface result data cleanly; result is visible through broadcast/logcat.

## v0.4.10

- First APK-valid manual binary manifest build.
- Parse/install test passed.
- Priv-app Magisk install succeeded.

## v0.4.7 - v0.4.9

- Fixed multiple manual binary manifest builder issues.
- v0.4.7 fixed corrupt XML but lacked APK v2/v3 signing.
- v0.4.8 added `apksigner` path.
- v0.4.9 still had version string-pool bugs.

## v0.4.5 - v0.4.6

- Manual APK packaging path introduced after Termux `aapt/aapt2` failed.
- v0.4.5 produced corrupt binary XML.
- v0.4.6 fixed chunk sizing but still had string-pool issues.

## v0.4.1 - v0.4.4

- Termux `android.jar` and `aapt/aapt2` packaging path rejected.
- Compile stubs worked for `javac`.
- `aapt`/`aapt2` could not produce a valid APK on-device with available framework resources.

## v0.3.x

- `app_process`/`dalvikvm` helper path rejected.
- Raw dex and jar/classes.dex did not execute the helper main method reliably.
- Packaged-class and file-marker tests failed.

## Earlier rejected paths

- Google Play Services disable/offline UI path failed to unlock H222 type UI and caused Google Play Billing account-context side effects.
- Direct Bluetooth config patching remains rejected.
