# Compatibility

## Verified

| Device | Android | Root | Helper | GET | SET car/Carkit | UI result | Notes |
|---|---:|---|---|---|---|---|---|
| Pixel 10 Pro XL | 16 / SDK 36 | Magisk | v0.4.15 | PASS | PASS | Shows Auto | H222 BT receiver |

## Expected but unverified

| Platform | Expected status |
|---|---|
| Other Pixel devices with Android 12+ and Magisk | Likely, needs testing |
| AOSP-based ROMs with working priv-app permission allowlist | Possible, needs testing |
| Samsung / One UI | Unknown |
| Xiaomi / HyperOS | Unknown |
| OnePlus / OxygenOS | Unknown |

## Unsupported

- Non-root devices.
- Non-Magisk installs.
- Devices where privileged app permission allowlisting is blocked.
- Devices where OEM Bluetooth settings ignore metadata key `17`.
