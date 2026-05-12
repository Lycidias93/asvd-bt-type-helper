#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

VER="v0.4.15"
ID="asvd-bt-type-helper"
PKG="org.asvd.bttypehelper"
NAME="ASVD BT Type Helper"

WORK="$HOME/asvd-bt-type-helper-v055"
MOD="$WORK/module"
SRC="$WORK/src/org/asvd/bttypehelper"
STUBSRC="$WORK/stubs"
STUBCLS="$WORK/stub-classes"
APPCLS="$WORK/app-classes"
APKBUILD="$WORK/apkbuild"
UNSIGNED="$WORK/unsigned.apk"
SIGNED="$WORK/AsvdBtTypeHelper.apk"
OUT="/storage/emulated/0/Download/ASVD-BT-Type-Helper-$VER.zip"

ANDROID_STUB_JAR="/data/data/com.termux/files/usr/share/aapt/android.jar"

printf '== ASVD BT Type Helper priv-app build %s ==\n' "$VER"

printf '\n== tools ==\n'
for p in openjdk-17 dx zip python apksigner; do
  if ! dpkg -s "$p" >/dev/null 2>&1; then
    echo "installing=$p"
    pkg install -y "$p"
  fi
done
for b in javac jar keytool apksigner dx zip python; do
  command -v "$b" >/dev/null
  echo "present=$(command -v "$b")"
done

test -s "$ANDROID_STUB_JAR"
echo "android_stub_jar=$ANDROID_STUB_JAR"

rm -rf "$WORK"
mkdir -p "$SRC" \
  "$STUBSRC/android/content" "$STUBSRC/android/bluetooth" "$STUBSRC/android/util" \
  "$STUBCLS" "$APPCLS" "$APKBUILD" \
  "$MOD/system/priv-app/AsvdBtTypeHelper" \
  "$MOD/system/etc/permissions" \
  "$MOD/system/etc/default-permissions"

printf '\n== write compile stubs ==\n'
cat > "$STUBSRC/android/content/Context.java" <<'JAVA'
package android.content;
import java.io.File;
public class Context {
    public File getFilesDir() { return null; }
}
JAVA

cat > "$STUBSRC/android/content/Intent.java" <<'JAVA'
package android.content;
public class Intent {
    public String getAction() { return null; }
    public String getStringExtra(String name) { return null; }
}
JAVA

cat > "$STUBSRC/android/content/BroadcastReceiver.java" <<'JAVA'
package android.content;
public abstract class BroadcastReceiver {
    public abstract void onReceive(Context context, Intent intent);
    public final void setResultCode(int code) {}
    public final void setResultData(String data) {}
    public final void setResult(int code, String data, Object extras) {}
}
JAVA

cat > "$STUBSRC/android/util/Log.java" <<'JAVA'
package android.util;
public class Log {
    public static int i(String tag, String msg) { return 0; }
    public static int w(String tag, String msg) { return 0; }
    public static int e(String tag, String msg) { return 0; }
    public static int e(String tag, String msg, Throwable tr) { return 0; }
}
JAVA

cat > "$STUBSRC/android/bluetooth/BluetoothClass.java" <<'JAVA'
package android.bluetooth;
public class BluetoothClass {
    public int getMajorDeviceClass() { return 0; }
    public int getDeviceClass() { return 0; }
}
JAVA

cat > "$STUBSRC/android/bluetooth/BluetoothDevice.java" <<'JAVA'
package android.bluetooth;
public class BluetoothDevice {
    public String getName() { return null; }
    public String getAddress() { return null; }
    public int getType() { return 0; }
    public BluetoothClass getBluetoothClass() { return null; }
    public byte[] getMetadata(int key) { return null; }
    public boolean setMetadata(int key, byte[] value) { return false; }
}
JAVA

cat > "$STUBSRC/android/bluetooth/BluetoothAdapter.java" <<'JAVA'
package android.bluetooth;
import java.util.Set;
public class BluetoothAdapter {
    public static BluetoothAdapter getDefaultAdapter() { return null; }
    public Set<BluetoothDevice> getBondedDevices() { return null; }
}
JAVA

printf '\n== write receiver ==\n'
cat > "$SRC/BtTypeReceiver.java" <<'JAVA'
package org.asvd.bttypehelper;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothClass;
import android.bluetooth.BluetoothDevice;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import java.io.File;
import java.io.FileWriter;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.Set;

public class BtTypeReceiver extends BroadcastReceiver {
    private static final String TAG = "ASVD-BT-HELPER";
    private static final int METADATA_DEVICE_TYPE = 17;
    private static final String ACTION_GET = "org.asvd.bttypehelper.GET";
    private static final String ACTION_SET_CARKIT = "org.asvd.bttypehelper.SET_CARKIT";
    private static final String ACTION_LIST = "org.asvd.bttypehelper.LIST";

    private static String s(Object o) { return o == null ? "null" : String.valueOf(o); }

    private static String normalizeMac(String v) {
        if (v == null) return null;
        String x = v.trim().toUpperCase(Locale.US);
        if (x.isEmpty()) return null;
        return x;
    }

    private static String sanitizeMac(String v) {
        if (v == null) return "null";
        return v.replaceAll("(?i)([0-9a-f]{2}:){5}[0-9a-f]{2}", "<BT_MAC>");
    }

    private static String maybeAddress(String v, boolean showMac) {
        if (v == null) return "null";
        return showMac ? v : sanitizeMac(v);
    }

    private static String bytesToString(byte[] b) {
        if (b == null) return "null";
        try { return new String(b, StandardCharsets.UTF_8); }
        catch (Throwable t) { return "bytes[" + b.length + "]"; }
    }

    private static byte[] stringBytes(String v) { return v.getBytes(StandardCharsets.UTF_8); }

    private void add(List<String> out, String line) {
        out.add(line);
        try { Log.i(TAG, line); } catch (Throwable ignored) {}
    }

    private String join(List<String> lines) {
        StringBuilder sb = new StringBuilder();
        for (String line : lines) sb.append(line).append('\n');
        return sb.toString();
    }

    private void setBroadcastResultSafe(List<String> lines, int code) {
        try { setResultCode(code); } catch (Throwable t) { try { Log.w(TAG, "setResultCode failed: " + t); } catch (Throwable ignored) {} }
        try { setResultData(join(lines)); } catch (Throwable t) { try { Log.w(TAG, "setResultData failed: " + t); } catch (Throwable ignored) {} }
    }

    private void writePath(File outFile, List<String> lines) {
        try {
            File parent = outFile.getParentFile();
            if (parent != null && !parent.exists()) parent.mkdirs();
            PrintWriter pw = new PrintWriter(new FileWriter(outFile, false));
            for (String line : lines) pw.println(line);
            pw.close();
            Log.i(TAG, "write_ok=" + outFile.getAbsolutePath());
        } catch (Throwable t) {
            try { Log.e(TAG, "write_failed=" + outFile.getAbsolutePath() + " error=" + t.getClass().getName() + ": " + t.getMessage(), t); } catch (Throwable ignored) {}
        }
    }

    private void finish(Context ctx, List<String> lines, int code) {
        try {
            File filesDir = ctx == null ? null : ctx.getFilesDir();
            add(lines, "filesDir=" + s(filesDir));
            if (filesDir != null) {
                writePath(new File(filesDir, "last-result.txt"), lines);
            } else {
                add(lines, "files_write=skipped_no_files_dir");
            }
        } catch (Throwable t) {
            add(lines, "context_files_write_failed=" + t.getClass().getName() + ": " + t.getMessage());
            try { Log.e(TAG, "context_files_write_failed " + t.getClass().getName() + ": " + t.getMessage(), t); } catch (Throwable ignored) {}
        }
        setBroadcastResultSafe(lines, code);
        try { Log.i(TAG, "finish_code=" + code); } catch (Throwable ignored) {}
    }

    private void addDeviceDetails(List<String> out, BluetoothDevice dev, boolean showMac) {
        try { add(out, "name=" + s(dev.getName())); } catch (Throwable t) { add(out, "name_error=" + t); }
        try { add(out, "address=" + maybeAddress(dev.getAddress(), showMac)); } catch (Throwable t) { add(out, "address_error=" + t); }
        try { add(out, "type=" + dev.getType()); } catch (Throwable t) { add(out, "type_error=" + t); }
        try {
            BluetoothClass bc = dev.getBluetoothClass();
            add(out, "bluetoothClass=" + s(bc));
            if (bc != null) {
                add(out, "majorDeviceClass=" + bc.getMajorDeviceClass());
                add(out, "deviceClass=" + bc.getDeviceClass());
            }
        } catch (Throwable t) {
            add(out, "bluetoothClass_error=" + t.getClass().getName() + ": " + t.getMessage());
        }
    }

    private List<BluetoothDevice> findMatches(Set<BluetoothDevice> bonded, String targetName, String targetMac, List<String> out) {
        List<BluetoothDevice> matches = new ArrayList<BluetoothDevice>();
        String macNorm = normalizeMac(targetMac);
        String nameNorm = targetName == null ? null : targetName.trim();
        for (BluetoothDevice d : bonded) {
            String n = null;
            String a = null;
            try { n = d.getName(); } catch (Throwable t) { add(out, "device_name_error=" + t.getClass().getName() + ": " + t.getMessage()); }
            try { a = d.getAddress(); } catch (Throwable t) { add(out, "device_address_error=" + t.getClass().getName() + ": " + t.getMessage()); }
            boolean match = false;
            if (macNorm != null) {
                match = macNorm.equals(normalizeMac(a));
            } else if (nameNorm != null && !nameNorm.isEmpty()) {
                match = nameNorm.equals(n);
            }
            if (match) matches.add(d);
        }
        return matches;
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        List<String> out = new ArrayList<String>();
        add(out, "== ASVD BT Type Helper v0.4.15 ==");
        add(out, "time=" + new Date().toString());
        add(out, "onReceive_enter=yes");

        try {
            String action = intent == null ? "" : s(intent.getAction());
            String targetName = intent == null ? null : intent.getStringExtra("name");
            String targetMac = intent == null ? null : intent.getStringExtra("mac");
            String showMacExtra = intent == null ? null : intent.getStringExtra("show_mac");
            boolean showMac = "1".equals(showMacExtra) || "true".equalsIgnoreCase(s(showMacExtra));
            if ((targetName == null || targetName.trim().isEmpty()) && (targetMac == null || targetMac.trim().isEmpty())) targetName = "H222";

            add(out, "action=" + action);
            add(out, "target_name=" + s(targetName));
            add(out, "target_mac=" + sanitizeMac(targetMac));
            add(out, "show_mac=" + showMac);

            BluetoothAdapter adapter = BluetoothAdapter.getDefaultAdapter();
            add(out, "adapter=" + s(adapter));
            if (adapter == null) {
                add(out, "RESULT: ASVD_BT_TYPE_HELPER_NO_ADAPTER");
                finish(context, out, 10);
                return;
            }

            Set<BluetoothDevice> bonded = adapter.getBondedDevices();
            add(out, "bonded_count=" + bonded.size());

            if (ACTION_LIST.equals(action)) {
                int i = 0;
                add(out, "");
                add(out, "== bonded devices ==");
                for (BluetoothDevice d : bonded) {
                    i++;
                    add(out, "-- device " + i + " --");
                    addDeviceDetails(out, d, showMac);
                    try { add(out, "metadata_17=" + bytesToString(d.getMetadata(METADATA_DEVICE_TYPE))); } catch (Throwable t) { add(out, "metadata_17_error=" + t.getClass().getName() + ": " + t.getMessage()); }
                }
                add(out, "RESULT: ASVD_BT_TYPE_HELPER_LIST_DONE");
                finish(context, out, 0);
                return;
            }

            List<BluetoothDevice> matches = findMatches(bonded, targetName, targetMac, out);
            add(out, "target_matches=" + matches.size());
            if (matches.size() != 1) {
                add(out, "match_mode=" + (normalizeMac(targetMac) != null ? "mac" : "name"));
                add(out, "RESULT: ASVD_BT_TYPE_HELPER_TARGET_NOT_UNIQUE");
                finish(context, out, 11);
                return;
            }

            BluetoothDevice dev = matches.get(0);

            add(out, "");
            add(out, "== target ==");
            addDeviceDetails(out, dev, showMac);

            byte[] before;
            try {
                before = dev.getMetadata(METADATA_DEVICE_TYPE);
            } catch (Throwable t) {
                add(out, "metadata_17_get_error=" + t.getClass().getName() + ": " + t.getMessage());
                add(out, "RESULT: ASVD_BT_TYPE_HELPER_GET_FAILED");
                finish(context, out, 20);
                return;
            }

            add(out, "");
            add(out, "== metadata ==");
            add(out, "metadata_17_before=" + bytesToString(before));

            if (ACTION_GET.equals(action)) {
                add(out, "RESULT: ASVD_BT_TYPE_HELPER_GET_DONE");
                finish(context, out, 0);
                return;
            }

            if (ACTION_SET_CARKIT.equals(action)) {
                boolean ok;
                try {
                    ok = dev.setMetadata(METADATA_DEVICE_TYPE, stringBytes("Carkit"));
                    add(out, "setMetadata_17_Carkit_return=" + ok);
                } catch (Throwable t) {
                    add(out, "metadata_17_set_error=" + t.getClass().getName() + ": " + t.getMessage());
                    add(out, "RESULT: ASVD_BT_TYPE_HELPER_SET_FAILED");
                    finish(context, out, 30);
                    return;
                }

                try {
                    byte[] after = dev.getMetadata(METADATA_DEVICE_TYPE);
                    add(out, "metadata_17_after=" + bytesToString(after));
                } catch (Throwable t) {
                    add(out, "metadata_17_after_error=" + t.getClass().getName() + ": " + t.getMessage());
                }

                add(out, ok ? "RESULT: ASVD_BT_TYPE_HELPER_SET_CARKIT_DONE" : "RESULT: ASVD_BT_TYPE_HELPER_SET_CARKIT_RETURN_FALSE");
                finish(context, out, ok ? 0 : 31);
                return;
            }

            add(out, "RESULT: ASVD_BT_TYPE_HELPER_UNKNOWN_ACTION");
            finish(context, out, 40);
        } catch (Throwable t) {
            add(out, "fatal=" + t.getClass().getName() + ": " + t.getMessage());
            try { Log.e(TAG, "fatal", t); } catch (Throwable ignored) {}
            add(out, "RESULT: ASVD_BT_TYPE_HELPER_FATAL");
            finish(context, out, 50);
        }
    }
}
JAVA

printf '\n== compile stubs ==\n'
javac --release 8 -d "$STUBCLS" $(find "$STUBSRC" -name '*.java' | sort)

printf '\n== compile app ==\n'
javac --release 8 -cp "$STUBCLS" -d "$APPCLS" "$SRC/BtTypeReceiver.java"

printf '\n== ensure no android stubs in app classes ==\n'
if find "$APPCLS" -type f | grep -q '/android/'; then
  echo "FAIL android stubs leaked into app classes"
  find "$APPCLS" -type f
  exit 1
fi
find "$APPCLS" -type f | sort

printf '\n== dex app only ==\n'
dx --dex --output="$WORK/classes.dex" "$APPCLS"

printf '\n== build binary AndroidManifest.xml manually ==\n'
cat > "$WORK/build_manifest_axml.py" <<'PY'
#!/usr/bin/env python3
import struct
from pathlib import Path

OUT = Path('/data/data/com.termux/files/home/asvd-bt-type-helper-v055/AndroidManifest.xml')

UTF8_FLAG = 0x00000100
NO_INDEX = 0xffffffff
TYPE_STRING = 0x03
TYPE_INT_DEC = 0x10
TYPE_BOOLEAN = 0x12

RES_XML_TYPE = 0x0003
RES_STRING_POOL_TYPE = 0x0001
RES_XML_RESOURCE_MAP_TYPE = 0x0180
RES_XML_START_NAMESPACE_TYPE = 0x0100
RES_XML_END_NAMESPACE_TYPE = 0x0101
RES_XML_START_ELEMENT_TYPE = 0x0102
RES_XML_END_ELEMENT_TYPE = 0x0103

ANDROID_URI = 'http://schemas.android.com/apk/res/android'

# Keep attribute names first so resource map indices line up.
strings = [
    'versionCode', 'versionName', 'minSdkVersion', 'targetSdkVersion', 'name', 'label', 'exported',
    'manifest', 'uses-sdk', 'uses-permission', 'application', 'receiver', 'intent-filter', 'action',
    'package', 'android', ANDROID_URI,
    'org.asvd.bttypehelper', '15', '0.4.15', '31', '35',
    'android.permission.BLUETOOTH', 'android.permission.BLUETOOTH_ADMIN', 'android.permission.BLUETOOTH_CONNECT', 'android.permission.BLUETOOTH_PRIVILEGED',
    'ASVD BT Type Helper', '.BtTypeReceiver', 'true',
    'org.asvd.bttypehelper.GET', 'org.asvd.bttypehelper.SET_CARKIT', 'org.asvd.bttypehelper.LIST'
]
idx = {s:i for i,s in enumerate(strings)}

# Resource IDs for strings 0..6. Remainder zero-filled.
resids = [0] * len(strings)
resids[idx['versionCode']] = 0x0101021b
resids[idx['versionName']] = 0x0101021c
resids[idx['minSdkVersion']] = 0x0101020c
resids[idx['targetSdkVersion']] = 0x01010270
resids[idx['name']] = 0x01010003
resids[idx['label']] = 0x01010001
resids[idx['exported']] = 0x01010010


def uleb128(n):
    out = bytearray()
    while True:
        b = n & 0x7f
        n >>= 7
        if n:
            out.append(b | 0x80)
        else:
            out.append(b)
            return bytes(out)


def align4(b):
    return b + b'\x00' * ((4 - (len(b) % 4)) % 4)


def chunk(t, header_size, payload):
    # payload already contains the chunk-specific header fields after ResChunk_header.
    # The chunk size field is therefore 8 + len(payload), not header_size + len(payload).
    return struct.pack('<HHI', t, header_size, 8 + len(payload)) + payload


def string_pool():
    data = bytearray()
    offsets = []
    for s in strings:
        enc = s.encode('utf-8')
        offsets.append(len(data))
        data += uleb128(len(s)) + uleb128(len(enc)) + enc + b'\x00'
    data = align4(bytes(data))
    string_count = len(strings)
    header_size = 0x1c
    strings_start = header_size + 4 * string_count
    payload = struct.pack('<IIIII', string_count, 0, UTF8_FLAG, strings_start, 0)
    payload += b''.join(struct.pack('<I', o) for o in offsets)
    payload += data
    return chunk(RES_STRING_POOL_TYPE, header_size, payload)


def resource_map():
    payload = b''.join(struct.pack('<I', r) for r in resids)
    return chunk(RES_XML_RESOURCE_MAP_TYPE, 8, payload)


def node_header(line=1):
    return struct.pack('<II', line, NO_INDEX)


def start_ns():
    payload = node_header() + struct.pack('<II', idx['android'], idx[ANDROID_URI])
    return chunk(RES_XML_START_NAMESPACE_TYPE, 0x10, payload)


def end_ns():
    payload = node_header() + struct.pack('<II', idx['android'], idx[ANDROID_URI])
    return chunk(RES_XML_END_NAMESPACE_TYPE, 0x10, payload)


def typed_value(dtype, data):
    return struct.pack('<HBBI', 8, 0, dtype, data)


def attr(ns, name, raw, dtype, data):
    return struct.pack('<III', ns, idx[name], raw) + typed_value(dtype, data)


def attr_str(name, value, ns=NO_INDEX):
    return attr(ns, name, idx[value], TYPE_STRING, idx[value])


def attr_android_str(name, value):
    return attr_str(name, value, idx[ANDROID_URI])


def attr_android_int(name, raw_value, value):
    return attr(idx[ANDROID_URI], name, NO_INDEX, TYPE_INT_DEC, int(value))


def attr_android_bool(name, raw_value, value):
    return attr(idx[ANDROID_URI], name, NO_INDEX, TYPE_BOOLEAN, 0xffffffff if value else 0)


def start_elem(name, attrs):
    attr_start = 20
    attr_size = 20
    attr_count = len(attrs)
    ext = struct.pack('<IIHHHHHH', NO_INDEX, idx[name], attr_start, attr_size, attr_count, 0, 0, 0)
    payload = node_header() + ext + b''.join(attrs)
    return chunk(RES_XML_START_ELEMENT_TYPE, 0x10, payload)


def end_elem(name):
    payload = node_header() + struct.pack('<II', NO_INDEX, idx[name])
    return chunk(RES_XML_END_ELEMENT_TYPE, 0x10, payload)

body = bytearray()
body += string_pool()
body += resource_map()
body += start_ns()
body += start_elem('manifest', [
    attr_str('package', 'org.asvd.bttypehelper'),
    attr_android_int('versionCode', '15', 15),
    attr_android_str('versionName', '0.4.15'),
])
body += start_elem('uses-sdk', [
    attr_android_int('minSdkVersion', '31', 31),
    attr_android_int('targetSdkVersion', '35', 35),
])
body += end_elem('uses-sdk')
for perm in ['android.permission.BLUETOOTH', 'android.permission.BLUETOOTH_ADMIN', 'android.permission.BLUETOOTH_CONNECT', 'android.permission.BLUETOOTH_PRIVILEGED']:
    body += start_elem('uses-permission', [attr_android_str('name', perm)])
    body += end_elem('uses-permission')
body += start_elem('application', [attr_android_str('label', 'ASVD BT Type Helper')])
body += start_elem('receiver', [
    attr_android_str('name', '.BtTypeReceiver'),
    attr_android_bool('exported', 'true', True),
])
body += start_elem('intent-filter', [])
for action in ['org.asvd.bttypehelper.GET', 'org.asvd.bttypehelper.SET_CARKIT', 'org.asvd.bttypehelper.LIST']:
    body += start_elem('action', [attr_android_str('name', action)])
    body += end_elem('action')
body += end_elem('intent-filter')
body += end_elem('receiver')
body += end_elem('application')
body += end_elem('manifest')
body += end_ns()

xml = struct.pack('<HHI', RES_XML_TYPE, 8, 8 + len(body)) + bytes(body)
OUT.write_bytes(xml)
print('wrote', OUT, 'size', len(xml))
PY
python "$WORK/build_manifest_axml.py"
ls -l "$WORK/AndroidManifest.xml"

printf '\n== package unsigned apk manually ==\n'
rm -rf "$APKBUILD"
mkdir -p "$APKBUILD"
cp "$WORK/AndroidManifest.xml" "$APKBUILD/AndroidManifest.xml"
cp "$WORK/classes.dex" "$APKBUILD/classes.dex"
(
  cd "$APKBUILD"
  zip -q -r "$UNSIGNED" AndroidManifest.xml classes.dex
)
ls -l "$UNSIGNED"

printf '\n== sign apk ==\n'
KEYSTORE_DIR="$HOME/.asvd-bt-type-helper"
KEYSTORE="$KEYSTORE_DIR/asvd-debug.keystore"
LEGACY_KEYSTORE="$HOME/asvd-bt-type-helper-v050/asvd-debug.keystore"
mkdir -p "$KEYSTORE_DIR"
if [ ! -s "$KEYSTORE" ] && [ -s "$LEGACY_KEYSTORE" ]; then
  echo "reusing_legacy_keystore=$LEGACY_KEYSTORE"
  cp -f "$LEGACY_KEYSTORE" "$KEYSTORE"
fi
if [ ! -s "$KEYSTORE" ]; then
  echo "generating_stable_keystore=$KEYSTORE"
  keytool -genkeypair \
    -keystore "$KEYSTORE" \
    -storepass android \
    -keypass android \
    -alias asvd \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -dname "CN=ASVD BT Type Helper, O=Lycidias93, C=DE" >/dev/null
else
  echo "using_stable_keystore=$KEYSTORE"
fi

apksigner sign \
  --ks "$KEYSTORE" \
  --ks-key-alias asvd \
  --ks-pass pass:android \
  --key-pass pass:android \
  --out "$SIGNED" \
  "$UNSIGNED"
apksigner verify --verbose "$SIGNED"

cp "$SIGNED" "$MOD/system/priv-app/AsvdBtTypeHelper/AsvdBtTypeHelper.apk"
chmod 0644 "$MOD/system/priv-app/AsvdBtTypeHelper/AsvdBtTypeHelper.apk"

printf '\n== write magisk module files ==\n'
cat > "$MOD/system/etc/permissions/privapp-permissions-org.asvd.bttypehelper.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<permissions>
    <privapp-permissions package="org.asvd.bttypehelper">
        <permission name="android.permission.BLUETOOTH_PRIVILEGED" />
        <permission name="android.permission.BLUETOOTH_CONNECT" />
    </privapp-permissions>
</permissions>
XML

cat > "$MOD/system/etc/default-permissions/default-permissions-org.asvd.bttypehelper.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<exceptions>
    <exception package="org.asvd.bttypehelper">
        <permission name="android.permission.BLUETOOTH_CONNECT" fixed="false" />
    </exception>
</exceptions>
XML

cat > "$MOD/module.prop" <<EOFPROP
id=$ID
name=$NAME
version=$VER
versionCode=15
author=Lycidias93
description=Experimental ASVD Bluetooth device type metadata helper. Manual only. No GMS, no boot automation, no bt_config patching.
EOFPROP

cat > "$MOD/customize.sh" <<'EOFCSH'
#!/system/bin/sh
SKIPMOUNT=false
PROPFILE=true
POSTFSDATA=false
LATESTARTSERVICE=false

ui_print "- ASVD BT Type Helper v0.4.15"
ui_print "- Experimental privileged helper APK"
ui_print "- Manual only: get first, set only after get succeeds"
ui_print "- No GMS manipulation"
ui_print "- No Bluetooth reload"
ui_print "- No bt_config.conf patching"
ui_print "- Guarded cleanup: removes temporary /data/app test install only"

PKG="org.asvd.bttypehelper"
ui_print "- Checking for temporary user-app install"
PKG_PATH="$(/system/bin/pm path "$PKG" 2>/dev/null | /system/bin/head -n 1 | /system/bin/sed 's/^package://')"
case "$PKG_PATH" in
  /data/app/*)
    ui_print "- Removing temporary /data/app install: $PKG"
    /system/bin/pm uninstall "$PKG" >/dev/null 2>&1 || true
    ;;
  /system/*|/product/*|/system_ext/*|/vendor/*)
    ui_print "- Existing system/priv-app package detected, keeping it"
    ;;
  "")
    ui_print "- No existing package visible"
    ;;
  *)
    ui_print "- Existing package path not auto-removed: $PKG_PATH"
    ;;
esac

set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/helper-common.sh" 0 0 0755
set_perm "$MODPATH/helper-grant.sh" 0 0 0755
set_perm "$MODPATH/helper-list.sh" 0 0 0755
set_perm "$MODPATH/helper-get.sh" 0 0 0755
set_perm "$MODPATH/helper-set-carkit.sh" 0 0 0755
set_perm "$MODPATH/helper-set-type.sh" 0 0 0755
set_perm "$MODPATH/system/priv-app/AsvdBtTypeHelper/AsvdBtTypeHelper.apk" 0 0 0644
set_perm "$MODPATH/system/etc/permissions/privapp-permissions-org.asvd.bttypehelper.xml" 0 0 0644
set_perm "$MODPATH/system/etc/default-permissions/default-permissions-org.asvd.bttypehelper.xml" 0 0 0644
EOFCSH

cat > "$MOD/helper-grant.sh" <<'EOFG'
#!/system/bin/sh
set -eu
PKG="org.asvd.bttypehelper"
echo "== package =="
/system/bin/pm path "$PKG" || true
echo
echo "== grant runtime permission =="
/system/bin/pm grant "$PKG" android.permission.BLUETOOTH_CONNECT >/dev/null 2>&1 || true
echo
echo "== permission state =="
/system/bin/dumpsys package "$PKG" 2>/dev/null \
  | /system/bin/grep -Ei "BLUETOOTH_CONNECT|BLUETOOTH_PRIVILEGED|granted=true|granted=false" \
  | /system/bin/sed -n "1,160p" || true
echo
echo "RESULT: ASVD_BT_TYPE_HELPER_GRANT_DONE"
EOFG

cat > "$MOD/helper-common.sh" <<'EOFG'
#!/system/bin/sh
set -eu
PKG="org.asvd.bttypehelper"

asvd_target_args() {
  NAME=""
  MAC=""
  SHOW_MAC="0"
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --name)
        shift
        NAME="${1:-}"
        ;;
      --mac)
        shift
        MAC="${1:-}"
        ;;
      --show-mac)
        SHOW_MAC="1"
        ;;
      --help|-h)
        echo "Usage: $0 [NAME] [--name NAME] [--mac AA:BB:CC:DD:EE:FF] [--show-mac]"
        exit 0
        ;;
      --*)
        echo "unknown_arg=$1"
        exit 2
        ;;
      *)
        if [ -z "$NAME" ]; then NAME="$1"; else echo "extra_arg=$1"; exit 2; fi
        ;;
    esac
    shift || true
  done
  if [ -z "$NAME" ] && [ -z "$MAC" ]; then NAME="H222"; fi
}

asvd_clear() {
  OUT1="/data/user/0/$PKG/files/last-result.txt"
  OUT2="/data_mirror/data_ce/null/0/$PKG/files/last-result.txt"
  OUT3="/data_mirror/data_de/null/0/$PKG/files/last-result.txt"
  /system/bin/rm -f "$OUT1" "$OUT2" "$OUT3" 2>/dev/null || true
  /system/bin/logcat -c 2>/dev/null || true
}

asvd_dump_results() {
  OUT1="/data/user/0/$PKG/files/last-result.txt"
  OUT2="/data_mirror/data_ce/null/0/$PKG/files/last-result.txt"
  OUT3="/data_mirror/data_de/null/0/$PKG/files/last-result.txt"
  echo
  echo "== result files =="
  for f in "$OUT1" "$OUT2" "$OUT3"; do
    echo "-- $f --"
    /system/bin/cat "$f" 2>/dev/null || echo "missing"
  done
  echo
  echo "== helper logcat tail =="
  /system/bin/logcat -d -t 500 2>/dev/null \
    | /system/bin/grep -Ei 'ASVD-BT-HELPER|Broadcast completed: result|data="|metadata_17|setMetadata|RESULT: ASVD_BT_TYPE_HELPER|SecurityException|Permission Denial|RuntimeException|FATAL' \
    | /system/bin/tail -180 || true
}

asvd_broadcast() {
  ACTION="$1"
  shift
  CMD="/system/bin/am broadcast --user 0 --include-stopped-packages --receiver-foreground -n $PKG/.BtTypeReceiver -a $ACTION"
  if [ -n "${NAME:-}" ]; then CMD="$CMD --es name \"$NAME\""; fi
  if [ -n "${MAC:-}" ]; then CMD="$CMD --es mac \"$MAC\""; fi
  if [ "${SHOW_MAC:-0}" = "1" ]; then CMD="$CMD --es show_mac 1"; fi
  /system/bin/sh -c "$CMD"
}
EOFG

cat > "$MOD/helper-list.sh" <<'EOFG'
#!/system/bin/sh
set -eu
. /data/adb/modules/asvd-bt-type-helper/helper-common.sh
SHOW_MAC="0"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --show-mac) SHOW_MAC="1" ;;
    --help|-h)
      echo "Usage: $0 [--show-mac]"
      echo "Default redacts MAC addresses. Use --show-mac locally, do not paste raw MACs publicly."
      exit 0
      ;;
    *) echo "unknown_arg=$1"; exit 2 ;;
  esac
  shift
 done

echo "== preflight =="
/system/bin/pm path "$PKG" || true

echo
echo "== clear old result/log =="
asvd_clear

echo
echo "== broadcast list =="
NAME=""
MAC=""
asvd_broadcast "$PKG.LIST" || true

echo
echo "== wait =="
/system/bin/sleep 2
asvd_dump_results

echo
echo "RESULT: ASVD_BT_TYPE_HELPER_LIST_WRAPPER_DONE"
EOFG

cat > "$MOD/helper-get.sh" <<'EOFG'
#!/system/bin/sh
set -eu
. /data/adb/modules/asvd-bt-type-helper/helper-common.sh
asvd_target_args "$@"

echo "== preflight =="
/system/bin/pm path "$PKG" || true

echo
echo "== target =="
echo "name=${NAME:-}"
if [ -n "${MAC:-}" ]; then echo "mac=<provided>"; else echo "mac="; fi

echo
echo "== clear old result/log =="
asvd_clear

echo
echo "== broadcast get =="
asvd_broadcast "$PKG.GET" || true

echo
echo "== wait =="
/system/bin/sleep 2
asvd_dump_results

echo
echo "RESULT: ASVD_BT_TYPE_HELPER_GET_WRAPPER_DONE"
EOFG

cat > "$MOD/helper-set-carkit.sh" <<'EOFG'
#!/system/bin/sh
set -eu
. /data/adb/modules/asvd-bt-type-helper/helper-common.sh
CONFIRM=""
ARGS=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --confirm-set) CONFIRM="--confirm-set" ;;
    *) ARGS="$ARGS '$1'" ;;
  esac
  shift
 done
# shellcheck disable=SC2086
eval "asvd_target_args $ARGS"
if [ "$CONFIRM" != "--confirm-set" ]; then
  echo "Refusing to set without explicit confirmation."
  echo "Use: $0 [H222|--name NAME|--mac MAC] --confirm-set"
  echo "RESULT: ASVD_BT_TYPE_HELPER_SET_CARKIT_CONFIRM_REQUIRED"
  exit 2
fi

echo "== preflight =="
/system/bin/pm path "$PKG" || true

echo
echo "== target =="
echo "name=${NAME:-}"
if [ -n "${MAC:-}" ]; then echo "mac=<provided>"; else echo "mac="; fi

echo
echo "== clear old result/log =="
asvd_clear

echo
echo "== broadcast set carkit =="
asvd_broadcast "$PKG.SET_CARKIT" || true

echo
echo "== wait =="
/system/bin/sleep 2
asvd_dump_results

echo
echo "RESULT: ASVD_BT_TYPE_HELPER_SET_CARKIT_WRAPPER_DONE"
EOFG

cat > "$MOD/helper-set-type.sh" <<'EOFG'
#!/system/bin/sh
set -eu
TYPE=""
CONFIRM=""
PASS_ARGS=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --type)
      shift
      TYPE="${1:-}"
      ;;
    --confirm-set)
      CONFIRM="--confirm-set"
      ;;
    *)
      PASS_ARGS="$PASS_ARGS '$1'"
      ;;
  esac
  shift
 done
case "$TYPE" in
  car|carkit|auto|Carkit) ;;
  "") echo "missing --type car"; echo "RESULT: ASVD_BT_TYPE_HELPER_SET_TYPE_MISSING_TYPE"; exit 2 ;;
  *) echo "unsupported_type=$TYPE"; echo "Only car/carkit/auto is supported in v0.4.15."; echo "RESULT: ASVD_BT_TYPE_HELPER_SET_TYPE_UNSUPPORTED"; exit 2 ;;
esac
# shellcheck disable=SC2086
eval "exec /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-set-carkit.sh $PASS_ARGS $CONFIRM"
EOFG

chmod 0755 "$MOD"/helper-*.sh "$MOD/customize.sh"

cat > "$MOD/README.md" <<'EOFREADME'
# ASVD BT Type Helper v0.4.15

Experimental privileged Bluetooth metadata helper.

Scope:
- Manual only
- No boot automation
- No GMS manipulation
- No Bluetooth reload
- No direct `/data/misc/bluedroid/bt_config.conf` patching
- Verified on Pixel 10 Pro XL / Android 16 with H222 BT2MP3 receiver
- Installer removes only temporary `/data/app` test installs; existing system/priv-app package is kept

After flashing and reboot:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-grant.sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-list.sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-get.sh --name H222
```

Optional local MAC listing:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-list.sh --show-mac
```

Safer targeting by MAC:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-get.sh --mac AA:BB:CC:DD:EE:FF
```

Only after read-only succeeds:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-set-type.sh --name H222 --type car --confirm-set
# or
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-set-carkit.sh --mac AA:BB:CC:DD:EE:FF --confirm-set
```
EOFREADME

printf '\n== syntax ==\n'
for f in customize.sh helper-common.sh helper-grant.sh helper-list.sh helper-get.sh helper-set-carkit.sh helper-set-type.sh; do
  sh -n "$MOD/$f"
  echo "PASS $f"
done

printf '\n== package magisk zip ==\n'
rm -f "$OUT" "$OUT.sha256"
(
  cd "$MOD"
  zip -q -r "$OUT" .
)
sha256sum "$OUT" > "$OUT.sha256"
sha256sum -c "$OUT.sha256"

printf '\n== artifacts ==\n'
ls -lh "$OUT" "$OUT.sha256"

printf '\nRESULT: ASVD_BT_TYPE_HELPER_PRIVAPP_V055_BUILD_DONE\n'
