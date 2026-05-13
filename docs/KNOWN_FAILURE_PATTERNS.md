# Known failure patterns

## 2026-05-12 · GitHub CLI release JSON field compatibility

### Symptom

`gh release view --json isLatest` fails with:

```text
Unknown JSON field: "isLatest"
```

### Root cause

The installed GitHub CLI version does not expose `isLatest` as a valid JSON field for `gh release view`.

### Fix

Do not use `isLatest` in release verification commands. Use this compatible field set instead:

```sh
gh release view "$TAG" \
  --json tagName,name,isPrerelease,isDraft,url,assets \
  --jq '.tagName, .name, "isPrerelease="+(.isPrerelease|tostring), "isDraft="+(.isDraft|tostring), .url, (.assets[]?.name)'
```

### Rule

Release final verification must avoid `isLatest` unless the local `gh release view --json` field list has been checked first.

<!-- v053-dynamic-release-failures-start -->
## 2026-05-12 · Dynamic release failure patterns

### Stale hardcoded workdir in generated build scripts

Symptom:

```text
wrote .../asvd-bt-type-helper-v058/AndroidManifest.xml
ls: cannot access .../asvd-bt-type-helper-v059/AndroidManifest.xml
```

Root cause: copied/generated build script kept a previous workdir literal.

Fix: derive the expected workdir from the build script id and gate against stale previous-version paths before build.

### Pixel post-flash AIO hangs with repeated `tsu`

Symptom: `cgrun` hangs or exits with timeout after `pm path` or during `dumpsys package` when multiple `tsu` calls, command substitutions, or pipelines are used.

Fix: use a minimal check or one simple root shell. Avoid nested `tsu /system/bin/sh -c` quoting and avoid repeated `tsu` in pipelines.
<!-- v053-dynamic-release-failures-end -->

<!-- android-awk-exp-failure-start -->
## Android `/system/bin/awk` compatibility in generated wizard output

### Symptom

The setup wizard fails during list formatting with errors such as:

```text
/system/bin/awk: non-terminated string
/system/bin/awk: syntax error
/system/bin/awk: illegal statement
/system/bin/awk: giving up
```

### Root cause

Generated helper scripts used Android awk-incompatible formatting, including multiline `printf` strings and the variable name `exp`, which can collide with awk functions/built-ins.

### Fix

Use single-line `printf` strings and avoid reserved/conflicting variable names such as `exp`; use explicit names like `expflag` instead. Smoke tests must hard-fail on awk syntax errors.
<!-- android-awk-exp-failure-end -->

## 2026-05-13 · Android awk setup wizard newline regression

### Symptom

`helper-setup.sh --dry-run` fails in the paired-device list with Android `/system/bin/awk` syntax errors, while type dry-runs and final GET checks pass.

### Root cause

The generated setup wizard contained real newlines inside an awk `printf` string instead of escaped `\n` sequences.

### Rule

For Android `/system/bin/awk`, generated scripts must keep `printf` format strings single-line and use escaped `\n`. Smoke tests must hard-fail on `awk:`, `syntax error`, `non-terminated string`, and `giving up`.

<!-- V056_KFP_SHARED_STATE_START -->
## v0.5.6 shared-state failure patterns

Known checks before release:

- State file absent after action means ASVD v1.2.6 can only report package/version, not target state.
- A raw Bluetooth MAC in `/data/adb/asvd/bt-helper.env` is a privacy failure.
- `--asvd-apply-now` must remain explicit; automatic ASVD triggering is not default behavior.
- GMS-disable/offline-UI and `bt_config.conf` patch approaches are rejected and must not be reintroduced.
<!-- V056_KFP_SHARED_STATE_END -->

<!-- kfp-v057-partial-mac-redaction-start -->
## v0.5.7 / partial Bluetooth address redaction

Android dumpsys may emit partially masked Bluetooth addresses such as `XX:XX:XX:XX:47:5C`. Treat those as sensitive and redact them like full MAC addresses. Smoke must scan current, last-device, and Action Button reports for both full and partially masked addresses.
<!-- kfp-v057-partial-mac-redaction-end -->
