# ASVD BT Type Helper

<!-- ASVD_BT_HELPER_ORIGIN_COMPANION_START -->
## Origin / companion module

ASVD BT Type Helper started as a companion idea for my [Audio Safe Volume Disabler / ASVD](https://github.com/Lycidias93/audio-safe-volume-battery-aware) module.

ASVD handles safe-volume / Sound Dose behavior. While working on that, I needed a reliable way to mark my Bluetooth receiver as a car device on Android, because the normal Bluetooth device type setting was visible but greyed out on my Pixel.

That Bluetooth device-type part became this separate helper module: ASVD BT Type Helper.
<!-- ASVD_BT_HELPER_ORIGIN_COMPANION_END -->

## What this module is

ASVD BT Type Helper is a **Magisk / priv-app helper** for changing Android Bluetooth device type metadata.

It can list paired Bluetooth devices, read Android Bluetooth metadata key `17`, and set that metadata value for one explicitly selected Bluetooth device. The main verified use case is setting a Bluetooth receiver to `Carkit`, so Android treats it as a car / auto device instead of a headphone-like device.

## Why I made it

My Pixel detected a Bluetooth receiver as a headphone-like device. Android Settings showed the Bluetooth device type option, but it was greyed out and could not be changed manually.

On my reference setup, setting metadata key `17` to `Carkit` made the receiver show up as **Car / Auto** in Android Bluetooth settings.

## Current status

| Area | Status |
|---|---|
| Current stable release | `v0.6.1` |
| Version / versionCode | `0.6.1` / `61` |
| Runtime model | Magisk module with privileged helper APK |
| Package | `org.asvd.bttypehelper` |
| Normal APK install | Not supported |
| Root / Magisk required | Yes |
| Verified phone | Pixel 10 Pro XL / Android 16 / SDK 36 |
| Verified target | `H222` Bluetooth receiver |
| Verified result | `metadata_17=Carkit` |
| Online updates | Enabled via Magisk `updateJson` |
| Non-Carkit types | Implemented, experimental until more UI mappings are confirmed |
| Other phones / OEM ROMs | Unknown, tester feedback needed |

## Download

All releases:

<https://github.com/Lycidias93/asvd-bt-type-helper/releases>

Latest release:

<https://github.com/Lycidias93/asvd-bt-type-helper/releases/tag/v0.6.1>

Download the Magisk ZIP from the newest stable release:

```text
ASVD-BT-Type-Helper-vX.X.X.zip
```

Do **not** install this as a normal APK. Flash the ZIP in Magisk.

## Install

1. Flash the ZIP in Magisk.
2. Reboot.
3. Grant/check permissions:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-grant.sh
```

4. Start the main menu:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/asvd.sh
```

## Recommended first run

Use the setup wizard first:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-setup.sh
```

The wizard lists paired Bluetooth devices, reads the selected target, and asks before writing.

MAC addresses are redacted by default. Use `--show-mac` only locally when exact MAC targeting is needed. Do not post raw Bluetooth MAC addresses publicly.

## Safe flow

1. List or pick the target device.
2. Run dry-run first.
3. Confirm exactly one target match.
4. Apply the wanted type with an explicit confirmation flag.
5. Verify with GET.
6. Run Doctor if something looks wrong.

Dry-run example:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-set-type.sh --name H222 --type car --dry-run
```

Expected dry-run markers:

```text
DRY_RUN=yes
write_performed=no
RESULT: ASVD_BT_TYPE_HELPER_SET_TYPE_DRY_RUN_DONE
```

Apply car / Carkit after a successful dry-run:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-set-type.sh --name H222 --type car --confirm-set
```

Verify the target:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-get.sh --name H222
```

Expected marker for the verified reference target:

```text
metadata_17_before=Carkit
RESULT: ASVD_BT_TYPE_HELPER_GET_WRAPPER_DONE
```

## Supported type names

| CLI type / alias | Metadata value | Status |
|---|---|---|
| `car`, `auto`, `carkit` | `Carkit` | Verified on H222 |
| `speaker` | `Speaker` | Experimental |
| `headset`, `headphones` | `Headset` | Experimental |
| `untethered-headset`, `earbuds`, `tws` | `Untethered Headset` | Experimental |
| `watch` | `Watch` | Experimental |
| `stylus`, `pen` | `Stylus` | Experimental |
| `hearingaid`, `hearing-aid` | `HearingAid` | Experimental |
| `default` | `Default` | Experimental |
| `clear`, `reset`, `null` | clear metadata key 17 | Implemented, use carefully |

`Carkit` is the verified reference type. Other metadata values are implemented but still need feedback from more devices, ROMs, and OEM Bluetooth settings UIs.

## Duplicate-safe picker

Use the duplicate-safe picker when Android shows a custom Bluetooth name, but the backend device name is duplicated.

Example:

- Android UI name: `Sauna`
- Backend name: `Tribit XSound Go`
- Two devices have the same backend name

Interactive path:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/asvd.sh
```

Then use:

```text
[5] Pick duplicate-safe device
[6] Set picked device dry-run
[7] Set picked device confirmed
```

Direct helper path:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-pick-device.sh --filter "Tribit XSound Go"
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-pick-device.sh --filter "Tribit XSound Go" --select 1
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-set-picked.sh --type speaker --dry-run
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-set-picked.sh --type speaker --confirm-set
```

The picker shows non-secret hints such as `candidate_id`, `source_index`, `backend_name`, `metadata_17`, `duplicate_name`, `last_connected`, `dev_type`, `dev_class`, and `likely_current_media`.

No raw Bluetooth MAC address is shown by default.

## Read-only views and reports

Currently connected devices:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-connected-devices.sh
```

Last connected Bluetooth hints:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-last-devices.sh --last-connected
```

Last devices summary:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-last-devices.sh
```

Magisk Action Button report:

```text
/storage/emulated/0/Download/ASVD-BT-Type-Helper-action-latest.txt
```

The Action Button report is read-only and includes module version, shared ASVD state, Doctor summary, current/last device hints, metadata overview, and recommended commands.

## ASVD companion state

The helper writes sanitized shared state for Audio Safe Volume Disabler / ASVD v1.2.6+:

```text
/data/adb/asvd/bt-helper.env
```

Example fields:

```text
helper_present=1
helper_package=org.asvd.bttypehelper
helper_version=0.6.1
helper_versionCode=61
target_name=H222
requested_type=Carkit
last_result=PASS
current_type=Carkit
previous_type=Carkit
method=metadata_api
asvd_apply_now_triggered=0
```

The shared-state file must not contain a raw Bluetooth MAC address.

ASVD remains independent. BT Helper is optional and does not force ASVD actions by default.

Optional ASVD apply-now after a confirmed metadata write:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-set-type.sh --name H222 --type car --confirm-set --asvd-apply-now
```

## Backup, restore and compare

Confirmed SET/CLEAR actions create a backup before writing.

Compare currently paired device types:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-compare-types.sh
```

Restore last saved metadata backup:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-restore-last.sh --dry-run
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-restore-last.sh --confirm-restore
```

## Doctor / health check

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-doctor.sh
```

Successful result:

```text
RESULT: ASVD_BT_TYPE_HELPER_DOCTOR_PASS
```

## Debug report for GitHub / XDA

Generate a public-safe debug report:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-debug.sh --name H222
```

MAC addresses are redacted by default. Do not post output generated with `--show-mac` publicly.

## Reliability notes

### v0.6.1

`v0.6.1` fixes a Pixel/Termux root-shell broadcast path where `am broadcast` can fail before the receiver is invoked because `system_server` is denied access to the Termux PTY (`/dev/pts/0`).

Changes:

- `am broadcast` runs detached from the Termux PTY.
- Package preflight output is captured before printing where `helper-common.sh` is used.
- `helper-get.sh` uses `request_id` polling and strict GET result validation.
- `helper-get.sh` fails if no fresh GET result exists.
- `helper-doctor.sh` treats GET wrapper failures as real failures.

### v0.6.0

`v0.6.0` fixes the setup Wizard stale-result failure mode.

Before v0.6.0, the wizard could request `LIST` but consume an existing `last-result.txt` from a previous `GET`, causing a false `no_devices_parsed` even though Bluetooth access worked.

The wizard now validates result provenance before parsing devices:

```text
action=org.asvd.bttypehelper.LIST
RESULT: ASVD_BT_TYPE_HELPER_LIST_DONE
request_id=<matching request>
```

Wrong or stale results fail explicitly:

```text
FAIL stale_or_wrong_result action=GET expected=LIST
```

## What this module does not do

- No Google Play Services manipulation.
- No Bluetooth service reload.
- No direct patching of `/data/misc/bluedroid/bt_config.conf`.
- No background daemon.
- No automatic boot-time Bluetooth metadata changes.
- No automatic ASVD apply-now trigger by default.
- No support for non-root / non-Magisk devices.
- No normal APK install support.

## Online updates

The module contains:

```text
updateJson=https://raw.githubusercontent.com/Lycidias93/asvd-bt-type-helper/main/update.json
```

Magisk uses `versionCode` for update comparison. `v0.6.1` uses `versionCode: 61`.

## Changelog and docs

Full changelog:

- [`CHANGELOG.md`](CHANGELOG.md)

Additional docs:

- [`docs/COMPATIBILITY.md`](docs/COMPATIBILITY.md)
- [`docs/TESTING.md`](docs/TESTING.md)
- [`docs/WORKFLOW.md`](docs/WORKFLOW.md)

Related module:

- Audio Safe Volume Disabler / ASVD: <https://github.com/Lycidias93/audio-safe-volume-battery-aware>
