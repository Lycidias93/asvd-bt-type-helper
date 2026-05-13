# Decisions

## v0.5.2 stable release posture

`v0.5.2` is promoted to stable release because the core user-friendly flow is verified on the reference setup:

- Magisk priv-app install works.
- `versionCode=52` and `versionName=0.5.2` are correct.
- H222 remains `metadata_17=Carkit` while connected in the car.
- Wizard starts and aborts safely.
- Debug report is redacted and suitable for public GitHub/XDA support.

## Safety decisions

- No SET without `--confirm-set`.
- No CLEAR without `--confirm-clear`.
- MAC addresses are redacted by default.
- Debug mode refuses intentional public MAC exposure.
- Speaker/headphones values remain experimental until verified against UI behavior.

<!-- v053-online-update-decision-start -->
## 2026-05-12 · Add Magisk online update support

Decision: add `updateJson=https://raw.githubusercontent.com/Lycidias93/asvd-bt-type-helper/main/update.json` to `module.prop` and maintain repository `update.json` from `v0.5.3` onward. Reason: enable Magisk online updates without changing Bluetooth runtime behavior.
<!-- v053-online-update-decision-end -->


## v0.5.3 online update posture

- `v0.5.3` is the first Magisk online-update capable release.
- `updateJson` points to the repository root `update.json` on `main`.
- Bluetooth runtime behavior remains unchanged from `v0.5.2`; H222 `Carkit` remains the verified reference state.

<!-- decision-v054-ux-start -->
## 2026-05-12 · v0.5.4 user-friendly UX release

Decision: publish v0.5.4 as a stable UX/safety release with `asvd.sh`, doctor, update info, and dry-run flows. Bluetooth Java runtime behavior remains unchanged from v0.5.3; H222 remains the verified Carkit reference target.
<!-- decision-v054-ux-end -->

## 2026-05-13 · v0.5.5 Type Expansion + Restore Safety

Decision: add all known Android metadata key 17 type values and aliases, but keep only Carkit marked as verified. Non-Carkit values are experimental until external UI mapping is confirmed.

<!-- V056_DECISION_SHARED_STATE_START -->
## 2026-05-13 · Ship shared-state companion integration, reject UI/GMS paths

Decision for `v0.5.6`:

- ship ASVD companion shared-state file `/data/adb/asvd/bt-helper.env`
- keep Bluetooth metadata/API approach
- reject GMS-disable/offline-UI helper path
- reject direct `/data/misc/bluedroid/bt_config.conf` patching
- reject boot automation for Bluetooth type changes
- keep ASVD apply-now opt-in only

Reason: previous UI unlock/offline tests caused unwanted Google account / billing context side effects and did not reliably unlock the Pixel Bluetooth type UI.
<!-- V056_DECISION_SHARED_STATE_END -->
