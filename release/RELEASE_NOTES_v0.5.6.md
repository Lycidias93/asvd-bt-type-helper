# ASVD BT Type Helper v0.5.6

Stable companion release for Audio Safe Volume Disabler / ASVD v1.2.6.

## Highlights

- Adds sanitized shared-state output for ASVD companion detection.
- Writes `/data/adb/asvd/bt-helper.env` after helper actions.
- Keeps package name `org.asvd.bttypehelper`.
- Bumps version to `0.5.6` / versionCode `56`.
- Keeps Bluetooth metadata key 17 API workflow.
- Does not ship GMS-disable/offline-UI helpers.
- Does not patch `/data/misc/bluedroid/bt_config.conf`.
- Does not automate Bluetooth type changes at boot.

## Shared-state fields

```text
helper_present=1
helper_package=org.asvd.bttypehelper
helper_version=0.5.6
helper_versionCode=56
target_name=H222
requested_type=Carkit
last_result=PASS
last_run=<timestamp>
last_error=
target_address_hash=
current_type=Carkit
previous_type=Carkit
method=metadata_api
asvd_apply_now_triggered=0
```

No raw Bluetooth MAC address is written to the shared state.

## Verified

- Pixel 10 Pro XL / Android 16 / SDK 36 / Magisk.
- H222 remains `metadata_17=Carkit`.
- Shared-state file present after confirmed H222/Carkit action.
- ASVD v1.2.6 verify detects BT Helper package, version and shared state.
- ASVD verify result: `RESULT: AUDIO_SAFE_VOLUME_VERIFY_PASS`.
- BT Helper smoke result: `RESULT: ASVD_BT_TYPE_HELPER_V056_SHARED_STATE_SMOKE_DONE`.

## Download

Download `ASVD-BT-Type-Helper-v0.5.6.zip` and flash it in Magisk.
