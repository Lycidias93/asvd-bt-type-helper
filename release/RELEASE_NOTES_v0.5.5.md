# ASVD BT Type Helper v0.5.5

Stable release: Type Expansion + Restore Safety.

## Highlights

- Adds all known Android Bluetooth metadata key 17 device type values:
  - Default
  - Watch
  - Untethered Headset
  - Stylus
  - Speaker
  - Headset
  - Carkit
  - HearingAid
- Adds aliases for easier use:
  - car / auto / carkit -> Carkit
  - speaker -> Speaker
  - headset / headphones -> Headset
  - untethered-headset / earbuds / tws -> Untethered Headset
  - watch -> Watch
  - stylus / pen -> Stylus
  - hearingaid / hearing-aid -> HearingAid
  - default -> Default
  - clear -> clear metadata key 17
- Fixes headphones alias to write `Headset` instead of a non-reference `Headphones` value.
- Adds backup-before-write behavior for confirmed set/clear flows.
- Adds `helper-restore-last.sh`.
- Adds `helper-compare-types.sh` for read-only grouping of paired devices by metadata type.
- Keeps Carkit as the only verified reference type; other types remain experimental feedback targets.

## Verified reference state

- Pixel 10 Pro XL / Android 16 / Magisk alpha reference setup.
- H222 remains `metadata_17=Carkit` after the v0.5.5 smoke.
- v0.5.5 postflash smoke v2 passed with `failures=0`.

## Safety

Writes remain guarded:

- set requires `--confirm-set`
- clear requires `--confirm-clear`
- dry-run performs no metadata writes

## Assets

- `ASVD-BT-Type-Helper-v0.5.5.zip`
- `ASVD-BT-Type-Helper-v0.5.5.zip.sha256`
