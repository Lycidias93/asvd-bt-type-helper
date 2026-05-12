# Decisions

## Keep this helper separate from ASVD

The Bluetooth type helper is experimental and separate from Audio Safe Volume Disabler runtime behavior.

## Rejected approaches

- No Google Play Services manipulation.
- No offline UI unlock path.
- No direct `/data/misc/bluedroid/bt_config.conf` patching.
- No automatic boot-time changes.
- No Bluetooth reload during active playback.

## Current accepted approach

Use a Magisk-installed privileged helper APK with explicit manual commands.
