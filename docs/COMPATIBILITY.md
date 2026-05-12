# Compatibility

## Verified

| Phone | Android | Root | Module | Target | GET | SET car | UI/connected proof | Status |
|---|---:|---|---|---|---|---|---|---|
| Pixel 10 Pro XL | 16 / SDK 36 | Magisk 30700 alpha | v0.5.3 | H222 | PASS | PASS | `metadata_17=Carkit` while connected in car | Verified |

## Observed UI references

| Device | Android UI type | Metadata verified by this tool |
|---|---|---|
| H222 | Auto | `Carkit` verified |
| KILBURN II | Speaker/Lautsprecher observed in UI | Not yet verified as `Speaker` metadata |
| Nothing Headphone (1) | Headphones/Kopfhörer observed in UI | Not yet verified as `Headphones` metadata |

## Unknown / tester feedback needed

- Samsung One UI
- Xiaomi / HyperOS
- OnePlus / OxygenOS
- LineageOS and other custom ROMs
- Android 12-15 behavior
- Non-Pixel Bluetooth Settings UI behavior

## Unsupported

- Non-root devices
- Non-Magisk installs
- Devices where priv-app permission allowlisting fails
- Devices where OEM Bluetooth UI ignores metadata key `17`

<!-- v053-online-update-compat-start -->
## v0.5.3 compatibility note

No Bluetooth runtime behavior changed compared with v0.5.2; v0.5.3 adds Magisk online-update metadata. Verified reference remains Pixel 10 Pro XL / Android 16 / Magisk alpha / H222 with `metadata_17=Carkit`.
<!-- v053-online-update-compat-end -->
