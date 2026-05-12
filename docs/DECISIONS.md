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
