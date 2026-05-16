# ASVD BT Type Helper v0.6.0

Wizard/Result robustness release.

## Fixed

- Fixed setup Wizard stale result handling where a `GET` result file could be parsed as `LIST` output.
- Prevents false `no_devices_parsed` when Bluetooth access works but the Wizard reads the wrong result.
- Adds request-bound result validation via `request_id`.

## Changed

- `helper-list.sh` and `helper-setup.sh` now poll for a matching result instead of sleeping for a fixed 2 seconds.
- LIST parsing now requires:
  - `action=org.asvd.bttypehelper.LIST`
  - `RESULT: ASVD_BT_TYPE_HELPER_LIST_DONE`
  - at least one `-- device` block
  - matching `request_id`
- `helper-doctor.sh` now includes LIST parse / Wizard smoke.

## Diagnostic output

Wrong/stale result example:

```text
FAIL stale_or_wrong_result action=GET expected=LIST
result_file=/data/user/0/org.asvd.bttypehelper/files/last-result.txt
device_blocks=0
bonded_count_seen=19
```

## Not changed

- No APK root.
- No root broker.
- No automatic Bluetooth metadata writes.
- No change to SET/GET metadata behavior.
- No H222 repair needed when `metadata_17=Carkit` is already present.

## Risk

Low to medium. Metadata write behavior is unchanged; only wrapper/receiver result correlation and Wizard parsing are hardened.
