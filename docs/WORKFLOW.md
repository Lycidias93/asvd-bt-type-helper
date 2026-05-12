# Maintainer workflow

## Working rules

- Prefer AIO checks: one bundled command, one output block, clear `RESULT:` line.
- Use absolute Android command paths in module scripts: `/system/bin/am`, `/system/bin/pm`, `/system/bin/logcat`, `/system/bin/cat`, `/system/bin/rm`.
- Do not use bare `am`, `pm`, `logcat`, or `service` inside Magisk helper scripts.
- Build, parse-test, flash, reboot, verify.
- Do not run SET before GET proves exactly one target.
- Prefer MAC targeting for public instructions when duplicate names are possible.
- Redact MAC addresses by default in public docs, reports, and wizard output.
- Keep XDA/GitHub debug reports safe to paste publicly by default.

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
11. Run wizard smoke test with `q` abort.
12. Run `helper-debug` and verify public-safe redaction.
13. For SET releases, run exactly one confirmed target SET and follow with GET.
14. Commit docs and build script.
15. Publish GitHub release with ZIP + SHA256.

## Public release posture

`v0.5.2` is the first stable release. The verified support statement is still limited to the reference Pixel setup and H222 target until more tester reports arrive.

## Known release verification compatibility

- Release verification must not use `gh release view --json isLatest`; use `tagName,name,isPrerelease,isDraft,url,assets` for compatibility.

<!-- dynamic-online-update-release-gate-start -->
## Dynamic build and online update release gate

- Build scripts must derive generated work paths from the current build id, not from copied previous-version literals.
- Before a build/release, gate with a stale workdir check such as `grep -n "asvd-bt-type-helper-v058" build_asvd_bt_type_helper_privapp_v059.sh` when moving from v058 to v059.
- Online-update capable releases must include `updateJson=https://raw.githubusercontent.com/Lycidias93/asvd-bt-type-helper/main/update.json` in `module.prop`.
- Repository root `update.json` must match the stable release assets:
  - `version=0.5.3`
  - `versionCode=53`
  - `zipUrl=https://github.com/Lycidias93/asvd-bt-type-helper/releases/download/v0.5.3/ASVD-BT-Type-Helper-v0.5.3.zip`
  - `changelog=https://github.com/Lycidias93/asvd-bt-type-helper/releases/tag/v0.5.3`
- Final release verification must avoid `gh release view --json isLatest`; use `tagName,name,isPrerelease,isDraft,url,assets`.
- Pixel post-flash AIO checks should avoid repeated `tsu` calls and avoid `tsu` inside command substitutions/pipelines; prefer one simple root shell or minimal direct checks.
<!-- dynamic-online-update-release-gate-end -->
