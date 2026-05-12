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
