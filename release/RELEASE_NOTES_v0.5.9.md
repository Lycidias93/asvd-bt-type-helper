# ASVD BT Type Helper v0.5.9

Stable release focused on duplicate-safe Bluetooth device selection UX.

## Highlights

- Improves the duplicate-safe picker for devices with identical backend names.
- Adds candidate details to make duplicate devices easier to distinguish:
  - `candidate_id`
  - `source_index`
  - `last_connected`
  - `dev_type`
  - `dev_class`
  - `likely_current_media`
- Stores the same candidate metadata in `picked-device.env`.
- Shows picked-device metadata before dry-run or confirmed actions.
- Keeps MAC addresses redacted by default.
- Keeps metadata writes guarded behind dry-run and explicit confirmation.
- Keeps H222 / Carkit behavior unchanged.

## Safety notes

- Do not set duplicate devices by backend name.
- Use the duplicate-safe picker before writing.
- If two candidates still look identical, do not confirm blindly.
- Android UI names may differ from Bluetooth backend names.

## Verified

- Pixel / Android 16 / Magisk.
- Package `org.asvd.bttypehelper`.
- Version `0.5.9`, versionCode `59`.
- Duplicate picker UX smoke: PASS.
- Picked speaker dry-run: PASS.
- H222 remains `metadata_17=Carkit`: PASS.
