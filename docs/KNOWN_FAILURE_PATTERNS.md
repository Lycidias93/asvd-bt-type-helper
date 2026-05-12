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
