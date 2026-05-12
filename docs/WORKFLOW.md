# Maintainer workflow

## Working rules

- Prefer AIO checks: one bundled command, one output block, clear `RESULT:` line.
- Use absolute Android command paths in module scripts: `/system/bin/am`, `/system/bin/pm`, `/system/bin/logcat`, `/system/bin/cat`, `/system/bin/rm`.
- Do not use bare `am`, `pm`, `logcat`, or `service` inside Magisk helper scripts.
- Build, parse-test, flash, reboot, verify.
- Do not run SET before GET proves exactly one target.
- Prefer MAC targeting for public instructions when duplicate names are possible.

## Release gate

1. Build ZIP.
2. Verify helper shell syntax.
3. Verify APK signature with `apksigner`.
4. Parse-test APK from `/data/local/tmp`.
5. Remove temporary `/data/app` install or let v0.4.15+ guarded installer remove it.
6. Flash Magisk ZIP.
7. Reboot.
8. Verify package path is `/system/priv-app/...`.
9. Verify privileged Bluetooth permissions.
10. Run `helper-get`.
11. For SET releases, run exactly one confirmed target SET and follow with GET.
12. Commit docs and build script.
13. Publish GitHub pre-release with ZIP + SHA256.

## Public release posture

Until more devices are tested, releases stay pre-release. The verified support statement is limited to the reference Pixel setup and H222 target.
