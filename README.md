# ASVD BT Type Helper

## v0.6.0 Wizard/Result robustness

`v0.6.0` fixes the setup Wizard race/stale-result failure mode.

Before this release, the Wizard could request `LIST` but still consume an existing `last-result.txt` from a previous `GET`, producing a false `no_devices_parsed` even though Bluetooth and metadata access were working.

The Wizard now validates result provenance before parsing devices:

```text
action=org.asvd.bttypehelper.LIST
RESULT: ASVD_BT_TYPE_HELPER_LIST_DONE
request_id=<matching request>
```

If it sees a wrong or stale result, it fails explicitly:

```text
FAIL stale_or_wrong_result action=GET expected=LIST
```

This release does not add APK root, a root broker, automatic Bluetooth changes, or new metadata write behavior.


ASVD BT Type Helper is a Magisk/priv-app helper for changing Android Bluetooth device type metadata.

The verified use case is a Bluetooth receiver that Android classified as headphones while the Pixel Bluetooth device type setting was visible but greyed out and not manually changeable. The helper can set Android Bluetooth metadata key `17` to `Carkit`, which made the receiver show as **Car/Auto** in Android Bluetooth settings on the verified reference device.

## Current status

| Area | Status |
|---|---|
| Latest release | `v0.6.1` |
| Runtime model | Magisk `priv-app` helper |
| Package | `org.asvd.bttypehelper` |
| Version / versionCode | `0.6.1` / `61` |
| Normal app support | Not supported |
| Root/Magisk required | Yes |
| Verified phone | Pixel 10 Pro XL / Android 16 / SDK 36 |
| Verified target | `H222` Bluetooth receiver |
| Verified connected-car state | Yes, `metadata_17=Carkit` while H222 is connected |
| ASVD companion state | Writes `/data/adb/asvd/bt-helper.env`; v0.6.0 adds LIST health fields |
| Online update support | Enabled via Magisk `updateJson` |
| Non-Carkit metadata values | Implemented, experimental until UI mapping is verified |
| Other phones/OEMs | Unknown / tester feedback needed |

## What it does

- Lists paired Bluetooth devices.
- Reads Bluetooth device metadata key `17`.
- Sets metadata key `17` for one explicitly selected device.
- Supports device selection by unique Bluetooth name or MAC address.
- Provides an interactive setup wizard.
- Provides real dry-run mode.
- Provides a redacted debug report for GitHub/XDA support.
- Uses guarded `--confirm-set` and `--confirm-clear` flows for writes.
- Writes a sanitized shared-state file for ASVD companion reporting.
- Provides backup/restore helpers for confirmed writes.

## What it does not do

- No Google Play Services manipulation.
- No Bluetooth service reload.
- No direct patching of `/data/misc/bluedroid/bt_config.conf`.
- No background daemon.
- No automatic boot-time Bluetooth metadata changes.
- No automatic ASVD apply-now trigger by default.
- No support for non-root / non-Magisk devices.

## Install

Flash the ZIP in Magisk, reboot, then run:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-grant.sh
```

## Recommended first run

Use the wizard:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-setup.sh
```

The wizard redacts MAC addresses by default. Use `--show-mac` only locally when exact MAC targeting is needed.

## Main menu

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/asvd.sh
```

## Supported type names

| CLI type | Metadata value | Status |
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

## Safe dry-run

Dry-run resolves the target and prints the planned action, but does not write Bluetooth metadata.

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-set-type.sh --name H222 --type car --dry-run
```

Expected marker:

```text
DRY_RUN=yes
write_performed=no
RESULT: ASVD_BT_TYPE_HELPER_SET_TYPE_DRY_RUN_DONE
```

## Apply car/Carkit

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-set-type.sh --name H222 --type car --confirm-set
```

If a display name is duplicated, use MAC targeting locally:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-set-type.sh --mac <BT_MAC> --type car --confirm-set
```

Do not post real MAC addresses publicly.

## Verify

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-get.sh --name H222
```

Expected verified marker for the H222 reference target:

```text
metadata_17_before=Carkit
RESULT: ASVD_BT_TYPE_HELPER_GET_DONE
```

## ASVD companion shared state

The helper writes sanitized shared state for ASVD v1.2.6+:

```text
/data/adb/asvd/bt-helper.env
```

Example state:

```text
helper_present=1
helper_package=org.asvd.bttypehelper
helper_version=0.6.0
helper_versionCode=60
target_name=H222
requested_type=Carkit
last_result=PASS
last_run=2026-05-13T09:38:00+0200
last_error=
target_address_hash=
current_type=Carkit
previous_type=Carkit
method=metadata_api
asvd_apply_now_triggered=0
```

The shared-state file must not contain a raw Bluetooth MAC address.

## Optional ASVD apply-now

The helper does not trigger ASVD by default. To run ASVD apply-now after a confirmed type set, use the explicit opt-in flag:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-set-type.sh --name H222 --type car --confirm-set --asvd-apply-now
```

## Compare current paired device types

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-compare-types.sh
```

## Restore last saved backup

Confirmed SET/CLEAR actions create a backup before writing. Restore is explicit and guarded:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-restore-last.sh --dry-run
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-restore-last.sh --confirm-restore
```

## Debug report for GitHub/XDA

Generate a public-safe debug report:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-debug.sh --name H222
```

The report redacts Bluetooth MAC addresses by default and writes a file to the Download folder.

## Doctor / health check

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-doctor.sh
```

Expected marker:

```text
RESULT: ASVD_BT_TYPE_HELPER_DOCTOR_PASS
```

## Online updates

The Magisk module contains:

```text
updateJson=https://raw.githubusercontent.com/Lycidias93/asvd-bt-type-helper/main/update.json
```

The repository root contains `update.json`, which points Magisk to the latest stable release ZIP and changelog. Magisk compares `versionCode`; `v0.6.0` uses `versionCode: 60`.

## Safety

This is system-level tooling. Use only on devices you can recover. Always verify the target first with `helper-get.sh`. Do not run SET commands against ambiguous device names. Prefer `--mac` locally when multiple paired devices share the same display name.

`Carkit` remains the verified reference type. Other metadata values are experimental until confirmed on more devices and OEM ROMs.

## Compatibility

See [`docs/COMPATIBILITY.md`](docs/COMPATIBILITY.md).

## Testing and release workflow

See [`docs/TESTING.md`](docs/TESTING.md) and [`docs/WORKFLOW.md`](docs/WORKFLOW.md).

<!-- v057-action-current-last-devices-start -->
## v0.5.7 Action Button and Bluetooth device views

`v0.5.7` adds read-only diagnostics and support helpers:

- Magisk Action Button support via `action.sh`.
- Action Button report written to the Download folder.
- Currently connected Bluetooth device hints.
- Last connected Bluetooth hints.
- Last devices summary.
- Improved redaction for raw and partially masked Bluetooth addresses.

Run from a root shell:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-connected-devices.sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-last-devices.sh --last-connected
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-last-devices.sh --last-devices
```

The Action Button is read-only. It does not set metadata, clear metadata, restart Bluetooth, or trigger ASVD apply-now by default.
<!-- v057-action-current-last-devices-end -->

<!-- ASVD_BT_HELPER_CURRENT_RELEASE_START -->
## Current stable release

Current stable release: **v0.6.1** (`versionCode=61`).

v0.6.0 is a Wizard/Result robustness release. It fixes stale/wrong result handling where a setup LIST request could accidentally parse an older GET result and report a false `no_devices_parsed`.

Key runtime changes:

- Adds `request_id` to helper broadcasts and result files.
- Setup Wizard accepts only matching LIST results.
- LIST validation requires:
  - `action=org.asvd.bttypehelper.LIST`
  - `RESULT: ASVD_BT_TYPE_HELPER_LIST_DONE`
  - at least one `-- device` block
- Replaces fixed 2-second LIST waits with short polling.
- Adds explicit failure output such as `FAIL stale_or_wrong_result action=GET expected=LIST`.
- Extends `helper-doctor.sh` with LIST parse / Wizard smoke.

H222 does not need another metadata write when it already shows:

```text
metadata_17=Carkit
```
<!-- ASVD_BT_HELPER_CURRENT_RELEASE_END -->

<!-- ASVD_BT_HELPER_V061_START -->
## v0.6.1 FD-detach and GET hardening

`v0.6.1` fixes the Pixel/Termux root-shell broadcast path observed with Magisk/Android 16 where `am broadcast` can fail before the receiver is invoked because `system_server` is denied access to the Termux PTY (`/dev/pts/0`).

Changes:

- `am broadcast` is now run detached from the Termux PTY (`stdin/stdout/stderr` redirected away from devpts).
- `pm path` preflight output in helper wrappers is captured before printing, avoiding direct framework writes to the Termux PTY.
- `helper-get.sh` now uses `request_id` polling and strict GET result validation.
- `helper-get.sh` returns failure if no fresh GET result exists; it no longer reports success with missing result files.
- `helper-doctor.sh` treats GET wrapper failures as real failures.

No Bluetooth metadata is written by LIST/GET/Doctor flows.
<!-- ASVD_BT_HELPER_V061_END -->
