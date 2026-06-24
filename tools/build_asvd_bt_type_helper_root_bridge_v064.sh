#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VER="0.6.4"
VCODE="64"
MODID="asvd-bt-type-helper"
PKG="org.asvd.bttypehelper"
OUT_DIR="${OUT_DIR:-/storage/emulated/0/Download}"
BUILD="$ROOT/.work/asvd-bt-helper-v064-root-bridge-build"
MOD="$BUILD/module"
SRC="$ROOT/src/root-bridge/org/asvd/bttypehelper/RootBridge.java"
ZIP="$OUT_DIR/ASVD-BT-Type-Helper-v${VER}.zip"

need(){ command -v "$1" >/dev/null 2>&1 || { echo "FAIL missing_tool=$1"; exit 1; }; }
for t in javac jar dx zip; do need "$t"; done

echo "== context =="
date -Iseconds
echo "builder=build_asvd_bt_type_helper_root_bridge_v064"
echo "version=$VER"
echo "versionCode=$VCODE"
echo "module_id=$MODID"
echo "package=$PKG"

echo
rm -rf "$BUILD"
mkdir -p "$BUILD/classes" "$BUILD/jar-in" "$BUILD/dex" "$MOD/root-bridge"

test -s "$SRC"
echo "== compile root bridge =="
javac -source 8 -target 8 -d "$BUILD/classes" "$SRC"
(
  cd "$BUILD/classes"
  jar cf "$BUILD/jar-in/asvd-bt-root-bridge-classes.jar" .
)
dx --dex --output="$BUILD/dex/classes.dex" "$BUILD/jar-in/asvd-bt-root-bridge-classes.jar"
(
  cd "$BUILD/dex"
  jar cf "$MOD/root-bridge/asvd-bt-root-bridge.jar" classes.dex
)
ls -l "$MOD/root-bridge/asvd-bt-root-bridge.jar"
sha256sum "$MOD/root-bridge/asvd-bt-root-bridge.jar"

echo "== write module files =="
cat > "$MOD/module.prop" <<EOF
id=$MODID
name=ASVD BT Type Helper
version=$VER
versionCode=$VCODE
author=Lycidias93
description=ASVD Bluetooth device type helper root-binder bridge for Android 17 metadata_17 GET/SET.
updateJson=https://raw.githubusercontent.com/Lycidias93/asvd-bt-type-helper/main/update.json
EOF
cat > "$MOD/helper-root-bridge.sh" <<'EOF'
#!/system/bin/sh
set -eu
MOD="${ASVD_BT_HELPER_MOD:-/data/adb/modules/asvd-bt-type-helper}"
JAR="$MOD/root-bridge/asvd-bt-root-bridge.jar"
APP_PROCESS=/system/bin/app_process
[ -x /system/bin/app_process64 ] && APP_PROCESS=/system/bin/app_process64
if [ "$(id -u)" != "0" ]; then
  echo "FAIL needs_root"
  echo "RESULT: ASVD_BT_ROOT_BRIDGE_WRAPPER_FAIL_NO_ROOT"
  exit 1
fi
test -s "$JAR"
export CLASSPATH="$JAR"
exec "$APP_PROCESS" /system/bin org.asvd.bttypehelper.RootBridge "$@"
EOF
cat > "$MOD/helper-get.sh" <<'EOF'
#!/system/bin/sh
set -eu
DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
exec sh "$DIR/helper-root-bridge.sh" get "$@"
EOF
cat > "$MOD/helper-list.sh" <<'EOF'
#!/system/bin/sh
set -eu
DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
exec sh "$DIR/helper-root-bridge.sh" list "$@"
EOF
cat > "$MOD/helper-set-type.sh" <<'EOF'
#!/system/bin/sh
set -eu
DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
exec sh "$DIR/helper-root-bridge.sh" set "$@"
EOF
cat > "$MOD/helper-set-carkit.sh" <<'EOF'
#!/system/bin/sh
set -eu
DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
exec sh "$DIR/helper-root-bridge.sh" set --type Carkit "$@"
EOF
cat > "$MOD/helper-clear-type.sh" <<'EOF'
#!/system/bin/sh
set -eu
DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
exec sh "$DIR/helper-root-bridge.sh" set --type Default "$@"
EOF
cat > "$MOD/helper-doctor.sh" <<'EOF'
#!/system/bin/sh
set -eu
DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
echo "android_release=$(getprop ro.build.version.release 2>/dev/null || true)"
echo "android_sdk=$(getprop ro.build.version.sdk 2>/dev/null || true)"
echo "contract_version=bt-helper-root-bridge-v1"
test -s "$DIR/module.prop" && echo "PASS module_prop_present" || echo "FAIL module_prop_missing"
test -s "$DIR/root-bridge/asvd-bt-root-bridge.jar" && echo "PASS root_bridge_jar_present" || echo "FAIL root_bridge_jar_missing"
if [ "$(id -u)" = "0" ]; then echo "PASS running_as_root"; else echo "WARN not_running_as_root"; fi
if [ -n "${ASVD_BT_TEST_NAME:-}" ]; then
  sh "$DIR/helper-get.sh" --name "$ASVD_BT_TEST_NAME" | sed -n '1,160p'
else
  echo "WARN ASVD_BT_TEST_NAME_not_set_skip_get_smoke"
fi
echo "RESULT: ASVD_BT_TYPE_HELPER_DOCTOR_DONE"
EOF
cat > "$MOD/action.sh" <<'EOF'
#!/system/bin/sh
set -eu
DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
exec sh "$DIR/helper-doctor.sh"
EOF
cat > "$MOD/asvd.sh" <<'EOF'
#!/system/bin/sh
set -eu
DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
exec sh "$DIR/helper-doctor.sh"
EOF
cat > "$MOD/customize.sh" <<'EOF'
#!/system/bin/sh
ui_print "- ASVD BT Type Helper v0.6.4 root bridge"
ui_print "- Reboot required"
EOF

echo "== verify module tree =="
find "$MOD" -type d -exec chmod 0755 {} +
find "$MOD" -type f -exec chmod 0644 {} +
find "$MOD" -maxdepth 1 -type f -name "*.sh" -exec chmod 0755 {} +
chmod 0755 "$MOD/helper-root-bridge.sh"
while IFS= read -r f; do
  if grep -q "$(printf '\r')" "$f"; then echo "FAIL crlf=$f"; exit 1; fi
  sh -n "$f"
  echo "PASS script=$(basename "$f")"
done < <(find "$MOD" -maxdepth 2 -type f -name "*.sh" | sort)

test "$(find "$MOD" -type f -name '*.apk' | wc -l | tr -d ' ')" = "0"
test -s "$MOD/root-bridge/asvd-bt-root-bridge.jar"

echo "== package zip =="
rm -f "$ZIP" "$ZIP.sha256"
(
  cd "$MOD"
  zip -qr "$ZIP" .
)
sha256sum "$ZIP" | tee "$ZIP.sha256"
ls -l "$ZIP" "$ZIP.sha256"
zipinfo -1 "$ZIP" | sed -n '1,120p'
python - "$ZIP" <<'PY'
import sys, zipfile
required = [
    "module.prop", "customize.sh", "action.sh", "asvd.sh",
    "helper-root-bridge.sh", "helper-get.sh", "helper-list.sh",
    "helper-set-type.sh", "helper-set-carkit.sh", "helper-clear-type.sh", "helper-doctor.sh",
    "root-bridge/asvd-bt-root-bridge.jar",
]
with zipfile.ZipFile(sys.argv[1]) as z:
    names=set(z.namelist())
    missing=[x for x in required if x not in names]
    print("zip_entries=%d" % len(names))
    print("missing_count=%d" % len(missing))
    for m in missing:
        print("MISS", m)
    if missing:
        raise SystemExit(1)
print("PASS zip_required_content")
PY

echo "RESULT: ASVD_BT_HELPER_V064_ROOT_BRIDGE_BUILD_DONE"
