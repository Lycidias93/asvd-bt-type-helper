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
