#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

VER="0.5.6"
TAG="v$VER"
VERSION_CODE="56"
ID="asvd-bt-type-helper"
PKG="org.asvd.bttypehelper"
NAME="ASVD BT Type Helper"

WORK="$HOME/asvd-bt-type-helper-v065"
MOD="$WORK/module"
SRC="$WORK/src/org/asvd/bttypehelper"
STUBSRC="$WORK/stubs"
STUBCLS="$WORK/stub-classes"
APPCLS="$WORK/app-classes"
APKBUILD="$WORK/apkbuild"
UNSIGNED="$WORK/unsigned.apk"
SIGNED="$WORK/AsvdBtTypeHelper.apk"
OUT="/storage/emulated/0/Download/ASVD-BT-Type-Helper-$TAG.zip"

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
    private static final String ACTION_SET_TYPE = "org.asvd.bttypehelper.SET_TYPE";
    private static final String ACTION_CLEAR = "org.asvd.bttypehelper.CLEAR";
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

    private static String normalizeTypeValue(String v) {
        if (v == null) return null;
        String x = v.trim().toLowerCase(Locale.US);
        x = x.replace('_', '-');
        if (x.equals("car") || x.equals("auto") || x.equals("carkit") || x.equals("car-kit")) return "Carkit";
        if (x.equals("speaker") || x.equals("lautsprecher")) return "Speaker";
        if (x.equals("headset") || x.equals("headsets") || x.equals("headphones") || x.equals("headphone") || x.equals("kopfhörer") || x.equals("kopfhoerer")) return "Headset";
        if (x.equals("untethered-headset") || x.equals("untethered") || x.equals("earbuds") || x.equals("earbud") || x.equals("buds") || x.equals("tws") || x.equals("true-wireless")) return "Untethered Headset";
        if (x.equals("watch") || x.equals("smartwatch") || x.equals("wearable")) return "Watch";
        if (x.equals("stylus") || x.equals("pen") || x.equals("stift")) return "Stylus";
        if (x.equals("hearingaid") || x.equals("hearing-aid") || x.equals("hearing-aids") || x.equals("hearing_aid")) return "HearingAid";
        if (x.equals("default") || x.equals("android-default") || x.equals("reset-default")) return "Default";
        return null;
    }

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
        add(out, "== ASVD BT Type Helper v0.5.6 ==");
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

            if (ACTION_SET_TYPE.equals(action)) {
                String requestedType = intent == null ? null : intent.getStringExtra("type_value");
                String value = normalizeTypeValue(requestedType);
                add(out, "requested_type=" + s(requestedType));
                add(out, "metadata_17_requested_value=" + s(value));
                if (value == null) {
                    add(out, "RESULT: ASVD_BT_TYPE_HELPER_SET_TYPE_UNSUPPORTED");
                    finish(context, out, 34);
                    return;
                }

                boolean ok;
                try {
                    ok = dev.setMetadata(METADATA_DEVICE_TYPE, stringBytes(value));
                    add(out, "setMetadata_17_" + value + "_return=" + ok);
                } catch (Throwable t) {
                    add(out, "metadata_17_set_type_error=" + t.getClass().getName() + ": " + t.getMessage());
                    add(out, "RESULT: ASVD_BT_TYPE_HELPER_SET_TYPE_FAILED");
                    finish(context, out, 35);
                    return;
                }

                try {
                    byte[] after = dev.getMetadata(METADATA_DEVICE_TYPE);
                    add(out, "metadata_17_after=" + bytesToString(after));
                } catch (Throwable t) {
                    add(out, "metadata_17_after_error=" + t.getClass().getName() + ": " + t.getMessage());
                }

                add(out, ok ? "RESULT: ASVD_BT_TYPE_HELPER_SET_TYPE_DONE" : "RESULT: ASVD_BT_TYPE_HELPER_SET_TYPE_RETURN_FALSE");
                finish(context, out, ok ? 0 : 36);
                return;
            }

            if (ACTION_CLEAR.equals(action)) {
                boolean ok;
                try {
                    ok = dev.setMetadata(METADATA_DEVICE_TYPE, null);
                    add(out, "clearMetadata_17_return=" + ok);
                } catch (Throwable t) {
                    add(out, "metadata_17_clear_error=" + t.getClass().getName() + ": " + t.getMessage());
                    add(out, "RESULT: ASVD_BT_TYPE_HELPER_CLEAR_FAILED");
                    finish(context, out, 32);
                    return;
                }

                try {
                    byte[] after = dev.getMetadata(METADATA_DEVICE_TYPE);
                    add(out, "metadata_17_after=" + bytesToString(after));
                } catch (Throwable t) {
                    add(out, "metadata_17_after_error=" + t.getClass().getName() + ": " + t.getMessage());
                }

                add(out, ok ? "RESULT: ASVD_BT_TYPE_HELPER_CLEAR_DONE" : "RESULT: ASVD_BT_TYPE_HELPER_CLEAR_RETURN_FALSE");
                finish(context, out, ok ? 0 : 33);
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

OUT = Path('/data/data/com.termux/files/home/asvd-bt-type-helper-v065/AndroidManifest.xml')

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
    'org.asvd.bttypehelper', '56', '0.5.6', '31', '35',
    'android.permission.BLUETOOTH', 'android.permission.BLUETOOTH_ADMIN', 'android.permission.BLUETOOTH_CONNECT', 'android.permission.BLUETOOTH_PRIVILEGED',
    'ASVD BT Type Helper', '.BtTypeReceiver', 'true',
    'org.asvd.bttypehelper.GET', 'org.asvd.bttypehelper.SET_CARKIT', 'org.asvd.bttypehelper.SET_TYPE', 'org.asvd.bttypehelper.CLEAR', 'org.asvd.bttypehelper.LIST'
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
    attr_android_int('versionCode', '56', 56),
    attr_android_str('versionName', '0.5.6'),
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
for action in ['org.asvd.bttypehelper.GET', 'org.asvd.bttypehelper.SET_CARKIT', 'org.asvd.bttypehelper.SET_TYPE', 'org.asvd.bttypehelper.CLEAR', 'org.asvd.bttypehelper.LIST']:
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
versionCode=$VERSION_CODE
author=Lycidias93
description=User-friendly ASVD Bluetooth device type metadata helper with dry-run, main menu, doctor, debug report, online update, config, clear, and guarded car/speaker/headphones type changes.
updateJson=https://raw.githubusercontent.com/Lycidias93/asvd-bt-type-helper/main/update.json
EOFPROP

cat > "$MOD/customize.sh" <<'EOFCSH'
#!/system/bin/sh
SKIPMOUNT=false
PROPFILE=true
POSTFSDATA=false
LATESTARTSERVICE=false

ui_print "- ASVD BT Type Helper v0.5.6"
ui_print "- Experimental privileged helper APK"
ui_print "- v0.5.6: all known metadata types, dry-run, backup/restore, compare-types, doctor, wizard"
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
set_perm "$MODPATH/helper-clear-type.sh" 0 0 0755
set_perm "$MODPATH/helper-report.sh" 0 0 0755
set_perm "$MODPATH/helper-debug.sh" 0 0 0755
set_perm "$MODPATH/helper-setup.sh" 0 0 0755
set_perm "$MODPATH/helper-apply-config.sh" 0 0 0755
set_perm "$MODPATH/helper-doctor.sh" 0 0 0755
set_perm "$MODPATH/helper-update-info.sh" 0 0 0755
set_perm "$MODPATH/helper-restore-last.sh" 0 0 0755
set_perm "$MODPATH/helper-compare-types.sh" 0 0 0755
set_perm "$MODPATH/asvd.sh" 0 0 0755
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
  shift || true
  set -- \
    --user 0 \
    --include-stopped-packages \
    --receiver-foreground \
    -n "$PKG/.BtTypeReceiver" \
    -a "$ACTION"
  if [ -n "${NAME:-}" ]; then set -- "$@" --es name "$NAME"; fi
  if [ -n "${MAC:-}" ]; then set -- "$@" --es mac "$MAC"; fi
  if [ "${SHOW_MAC:-0}" = "1" ]; then set -- "$@" --es show_mac 1; fi
  if [ -n "${TYPE_VALUE:-}" ]; then set -- "$@" --es type_value "$TYPE_VALUE"; fi
  /system/bin/am broadcast "$@"
}

BT_HELPER_VERSION="0.5.6"
BT_HELPER_VERSION_CODE="56"
ASVD_STATE_DIR="/data/adb/asvd"
ASVD_STATE_FILE="$ASVD_STATE_DIR/bt-helper.env"

asvd_state_clean() {
  /system/bin/printf '%s' "${1:-}" | /system/bin/tr '

' '  ' | /system/bin/sed "s/'/'\\''/g"
}

asvd_state_line() {
  key="$1"
  val="$(asvd_state_clean "${2:-}")"
  if [ -z "$val" ]; then
    echo "$key="
    return 0
  fi
  case "$val" in
    *[!A-Za-z0-9_./:@+-]* ) /system/bin/printf "%s='%s'
" "$key" "$val" ;;
    * ) /system/bin/printf "%s=%s
" "$key" "$val" ;;
  esac
}

asvd_state_existing() {
  key="$1"
  [ -s "$ASVD_STATE_FILE" ] || return 0
  # shellcheck disable=SC1090
  . "$ASVD_STATE_FILE" 2>/dev/null || true
  case "$key" in
    helper_present) /system/bin/printf '%s' "${helper_present:-}" ;;
    helper_package) /system/bin/printf '%s' "${helper_package:-}" ;;
    helper_version) /system/bin/printf '%s' "${helper_version:-}" ;;
    helper_versionCode) /system/bin/printf '%s' "${helper_versionCode:-}" ;;
    target_name) /system/bin/printf '%s' "${target_name:-}" ;;
    requested_type) /system/bin/printf '%s' "${requested_type:-}" ;;
    last_result) /system/bin/printf '%s' "${last_result:-}" ;;
    last_run) /system/bin/printf '%s' "${last_run:-}" ;;
    last_error) /system/bin/printf '%s' "${last_error:-}" ;;
    target_address_hash) /system/bin/printf '%s' "${target_address_hash:-}" ;;
    current_type) /system/bin/printf '%s' "${current_type:-}" ;;
    previous_type) /system/bin/printf '%s' "${previous_type:-}" ;;
    method) /system/bin/printf '%s' "${method:-}" ;;
    asvd_apply_now_triggered) /system/bin/printf '%s' "${asvd_apply_now_triggered:-}" ;;
  esac
}

asvd_state_write() {
  state_target_name="${1:-unknown}"
  state_requested_type="${2:-unknown}"
  state_last_result="${3:-UNKNOWN}"
  state_last_error="${4:-}"
  state_current_type="${5:-unknown}"
  state_previous_type="${6:-unknown}"
  state_method="${7:-metadata_api}"
  state_apply_now="${8:-0}"
  state_ts="$(/system/bin/date +%Y-%m-%dT%H:%M:%S%z 2>/dev/null || /system/bin/date 2>/dev/null || echo unknown)"

  /system/bin/mkdir -p "$ASVD_STATE_DIR"
  /system/bin/chmod 0755 "$ASVD_STATE_DIR" 2>/dev/null || true
  tmp="$ASVD_STATE_FILE.tmp.$$"
  {
    echo "helper_present=1"
    asvd_state_line helper_package "$PKG"
    asvd_state_line helper_version "$BT_HELPER_VERSION"
    echo "helper_versionCode=$BT_HELPER_VERSION_CODE"
    asvd_state_line target_name "$state_target_name"
    asvd_state_line requested_type "$state_requested_type"
    asvd_state_line last_result "$state_last_result"
    asvd_state_line last_run "$state_ts"
    asvd_state_line last_error "$state_last_error"
    asvd_state_line target_address_hash ""
    asvd_state_line current_type "$state_current_type"
    asvd_state_line previous_type "$state_previous_type"
    asvd_state_line method "$state_method"
    echo "asvd_apply_now_triggered=$state_apply_now"
  } > "$tmp"
  /system/bin/chmod 0644 "$tmp" 2>/dev/null || true
  /system/bin/mv -f "$tmp" "$ASVD_STATE_FILE"
  /system/bin/chmod 0644 "$ASVD_STATE_FILE" 2>/dev/null || true
  echo "shared_state_written=$ASVD_STATE_FILE"
}

asvd_result_value() {
  key="$1"
  for f in "/data/user/0/$PKG/files/last-result.txt" "/data_mirror/data_ce/null/0/$PKG/files/last-result.txt" "/data_mirror/data_de/null/0/$PKG/files/last-result.txt"; do
    [ -s "$f" ] || continue
    /system/bin/grep -m1 "^$key=" "$f" 2>/dev/null | /system/bin/sed "s/^$key=//" && return 0
  done
  return 0
}

asvd_result_has() {
  pat="$1"
  for f in "/data/user/0/$PKG/files/last-result.txt" "/data_mirror/data_ce/null/0/$PKG/files/last-result.txt" "/data_mirror/data_de/null/0/$PKG/files/last-result.txt"; do
    [ -s "$f" ] || continue
    /system/bin/grep -q "$pat" "$f" 2>/dev/null && return 0
  done
  return 1
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
CURRENT_TYPE="$(asvd_result_value metadata_17_before || true)"
[ -n "$CURRENT_TYPE" ] || CURRENT_TYPE="unknown"
REQ="$(asvd_state_existing requested_type || true)"
[ -n "$REQ" ] || REQ="GET"
STATE_RESULT="FAIL"
STATE_ERROR="get_failed_or_unverified"
if asvd_result_has "RESULT: ASVD_BT_TYPE_HELPER_GET_DONE"; then
  STATE_RESULT="PASS"
  STATE_ERROR=""
fi
asvd_state_write "${NAME:-H222}" "$REQ" "$STATE_RESULT" "$STATE_ERROR" "$CURRENT_TYPE" "$(asvd_state_existing previous_type || true)" "metadata_api" "$(asvd_state_existing asvd_apply_now_triggered || echo 0)"

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
. /data/adb/modules/asvd-bt-type-helper/helper-common.sh
TYPE=""
CONFIRM=""
DRY_RUN="0"
APPLY_NOW="0"
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
    --dry-run)
      DRY_RUN="1"
      ;;
    --asvd-apply-now)
      APPLY_NOW="1"
      ;;
    --help|-h)
      echo "Usage: $0 [H222|--name NAME|--mac MAC] --type TYPE [--confirm-set] [--dry-run] [--asvd-apply-now]"
      echo "Types: car, speaker, headset/headphones, untethered-headset/earbuds/tws, watch, stylus, hearingaid, default, clear"
      echo "Dry-run resolves the target and planned metadata but does not write. --asvd-apply-now is never default."
      exit 0
      ;;
    *)
      PASS_ARGS="$PASS_ARGS '$1'"
      ;;
  esac
  shift
done
normalize_type_shell() {
  t="$(echo "${1:-}" | /system/bin/tr '[:upper:]_' '[:lower:]-')"
  case "$t" in
    car|carkit|auto|car-kit) echo "Carkit" ;;
    speaker|lautsprecher) echo "Speaker" ;;
    headset|headsets|headphones|headphone|kopfhoerer|kopfhörer) echo "Headset" ;;
    untethered-headset|untethered|earbuds|earbud|buds|tws|true-wireless) echo "Untethered Headset" ;;
    watch|smartwatch|wearable) echo "Watch" ;;
    stylus|pen|stift) echo "Stylus" ;;
    hearingaid|hearing-aid|hearing-aids|hearing_aid) echo "HearingAid" ;;
    default|android-default|reset-default) echo "Default" ;;
    clear|reset|null) echo "__CLEAR__" ;;
    "") echo "__MISSING__" ;;
    *) echo "__UNSUPPORTED__" ;;
  esac
}
TYPE_VALUE="$(normalize_type_shell "$TYPE")"
case "$TYPE_VALUE" in
  __CLEAR__)
    if [ "$DRY_RUN" = "1" ]; then
      # shellcheck disable=SC2086
      eval "exec /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-clear-type.sh $PASS_ARGS --dry-run"
    else
      # shellcheck disable=SC2086
      eval "exec /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-clear-type.sh $PASS_ARGS --confirm-clear"
    fi
    ;;
  __MISSING__)
    echo "missing --type TYPE"
    echo "Supported: car, speaker, headset/headphones, untethered-headset/earbuds/tws, watch, stylus, hearingaid, default, clear"
    echo "RESULT: ASVD_BT_TYPE_HELPER_SET_TYPE_MISSING_TYPE"
    exit 2
    ;;
  __UNSUPPORTED__)
    echo "unsupported_type=$TYPE"
    echo "Supported: car, speaker, headset/headphones, untethered-headset/earbuds/tws, watch, stylus, hearingaid, default, clear"
    echo "RESULT: ASVD_BT_TYPE_HELPER_SET_TYPE_UNSUPPORTED"
    exit 2
    ;;
esac
# shellcheck disable=SC2086
eval "asvd_target_args $PASS_ARGS"

save_backup() {
  BACKUP_DIR="/data/adb/modules/asvd-bt-type-helper/backups"
  /system/bin/mkdir -p "$BACKUP_DIR"
  /system/bin/chmod 0700 "$BACKUP_DIR" 2>/dev/null || true
  TS="$(/system/bin/date +%Y%m%d_%H%M%S 2>/dev/null || echo unknown)"
  BACKUP_FILE="$BACKUP_DIR/metadata17-before-set-$TS.txt"
  {
    echo "backup_format=asvd-bt-type-helper-metadata17-v1"
    echo "action=set"
    echo "planned_metadata_17=$TYPE_VALUE"
    echo "target_name=${NAME:-}"
    if [ -n "${MAC:-}" ]; then echo "target_mac=<redacted>"; else echo "target_mac="; fi
    echo "created_at=$TS"
    echo
    echo "== before =="
    if [ -n "${MAC:-}" ]; then
      /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-get.sh --mac "$MAC" 2>/dev/null || true
    else
      /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-get.sh --name "${NAME:-H222}" 2>/dev/null || true
    fi
  } > "$BACKUP_FILE"
  /system/bin/chmod 0600 "$BACKUP_FILE" 2>/dev/null || true
  echo "backup_saved=$BACKUP_FILE"
}

target_display_name() {
  if [ -n "${NAME:-}" ]; then echo "$NAME"; else echo "unknown"; fi
}

if [ "$DRY_RUN" = "1" ]; then
  echo "== dry-run set type =="
  echo "DRY_RUN=yes"
  echo "planned_action=SET_TYPE"
  echo "planned_metadata_17=$TYPE_VALUE"
  case "$TYPE_VALUE" in Carkit) echo "support_status=verified_reference" ;; *) echo "support_status=experimental_feedback_needed" ;; esac
  echo "write_performed=no"
  echo
  echo "== target =="
  echo "target_selector=$( [ -n "${MAC:-}" ] && echo mac || echo name )"
  echo "name=${NAME:-}"
  if [ -n "${MAC:-}" ]; then echo "mac=<provided>"; else echo "mac="; fi
  echo
  echo "== current target state =="
  DRY_TMP="/data/local/tmp/asvd-bt-type-helper-set-dryrun-get.txt"
  if [ -n "${MAC:-}" ]; then
    /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-get.sh --mac "$MAC" > "$DRY_TMP" 2>/dev/null || true
  else
    /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-get.sh --name "${NAME:-H222}" > "$DRY_TMP" 2>/dev/null || true
  fi
  /system/bin/grep -E "target_matches=|name=|metadata_17_before=|RESULT: ASVD_BT_TYPE_HELPER_GET_DONE|RESULT: ASVD_BT_TYPE_HELPER_GET_WRAPPER_DONE" "$DRY_TMP" || true
  PREVIOUS_TYPE="$(/system/bin/grep -m1 '^metadata_17_before=' "$DRY_TMP" 2>/dev/null | /system/bin/sed 's/^metadata_17_before=//' || true)"
  [ -n "$PREVIOUS_TYPE" ] || PREVIOUS_TYPE="unknown"
  echo
  asvd_state_write "$(target_display_name)" "$TYPE_VALUE" "DRY_RUN" "" "$PREVIOUS_TYPE" "$PREVIOUS_TYPE" "metadata_api" "0"
  echo "RESULT: ASVD_BT_TYPE_HELPER_SET_TYPE_DRY_RUN_DONE"
  exit 0
fi

if [ "$CONFIRM" != "--confirm-set" ]; then
  echo "Refusing to set without explicit confirmation."
  echo "Use: $0 [H222|--name NAME|--mac MAC] --type TYPE --confirm-set"
  echo "Dry-run: $0 [H222|--name NAME|--mac MAC] --type TYPE --dry-run"
  echo "RESULT: ASVD_BT_TYPE_HELPER_SET_TYPE_CONFIRM_REQUIRED"
  exit 2
fi

echo "== preflight =="
/system/bin/pm path "$PKG" || true

echo
echo "== target =="
echo "target_selector=$( [ -n "${MAC:-}" ] && echo mac || echo name )"
echo "name=${NAME:-}"
if [ -n "${MAC:-}" ]; then echo "mac=<provided>"; else echo "mac="; fi
echo "type_value=$TYPE_VALUE"
case "$TYPE_VALUE" in Carkit) echo "support_status=verified_reference" ;; *) echo "support_status=experimental_feedback_needed" ;; esac

echo
echo "== backup before write =="
save_backup
PREVIOUS_TYPE="$(/system/bin/grep -m1 '^metadata_17_before=' "$BACKUP_FILE" 2>/dev/null | /system/bin/sed 's/^metadata_17_before=//' || true)"
[ -n "$PREVIOUS_TYPE" ] || PREVIOUS_TYPE="unknown"

echo
echo "== clear old result/log =="
asvd_clear

echo
echo "== broadcast set type =="
asvd_broadcast "$PKG.SET_TYPE" || true

echo
echo "== wait =="
/system/bin/sleep 2
asvd_dump_results

CURRENT_TYPE="$(asvd_result_value metadata_17_after || true)"
[ -n "$CURRENT_TYPE" ] || CURRENT_TYPE="$TYPE_VALUE"
STATE_RESULT="FAIL"
STATE_ERROR="set_type_failed_or_unverified"
if asvd_result_has "RESULT: ASVD_BT_TYPE_HELPER_SET_TYPE_DONE"; then
  STATE_RESULT="PASS"
  STATE_ERROR=""
fi
ASVD_APPLY_TRIGGERED="0"
if [ "$STATE_RESULT" = "PASS" ] && [ "$APPLY_NOW" = "1" ]; then
  APPLY_NOW_SCRIPT="/data/adb/modules/audio-safe-volume-battery-aware/apply-now.sh"
  if [ -x "$APPLY_NOW_SCRIPT" ] || [ -s "$APPLY_NOW_SCRIPT" ]; then
    echo
    echo "== optional ASVD apply-now =="
    /system/bin/sh "$APPLY_NOW_SCRIPT" || true
    ASVD_APPLY_TRIGGERED="1"
  else
    echo "asvd_apply_now_skipped=missing_apply_now_script"
  fi
fi
asvd_state_write "$(target_display_name)" "$TYPE_VALUE" "$STATE_RESULT" "$STATE_ERROR" "$CURRENT_TYPE" "$PREVIOUS_TYPE" "metadata_api" "$ASVD_APPLY_TRIGGERED"

echo
echo "RESULT: ASVD_BT_TYPE_HELPER_SET_TYPE_WRAPPER_DONE"
EOFG

cat > "$MOD/helper-clear-type.sh" <<'EOFG'
#!/system/bin/sh
set -eu
. /data/adb/modules/asvd-bt-type-helper/helper-common.sh
CONFIRM=""
DRY_RUN="0"
ARGS=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --confirm-clear) CONFIRM="--confirm-clear" ;;
    --dry-run) DRY_RUN="1" ;;
    --help|-h)
      echo "Usage: $0 [H222|--name NAME|--mac MAC] [--confirm-clear] [--dry-run]"
      echo "Dry-run resolves the target but does not clear metadata."
      exit 0
      ;;
    *) ARGS="$ARGS '$1'" ;;
  esac
  shift
done
# shellcheck disable=SC2086
eval "asvd_target_args $ARGS"

target_display_name() {
  if [ -n "${NAME:-}" ]; then echo "$NAME"; else echo "unknown"; fi
}

save_backup() {
  BACKUP_DIR="/data/adb/modules/asvd-bt-type-helper/backups"
  /system/bin/mkdir -p "$BACKUP_DIR"
  /system/bin/chmod 0700 "$BACKUP_DIR" 2>/dev/null || true
  TS="$(/system/bin/date +%Y%m%d_%H%M%S 2>/dev/null || echo unknown)"
  BACKUP_FILE="$BACKUP_DIR/metadata17-before-clear-$TS.txt"
  {
    echo "backup_format=asvd-bt-type-helper-metadata17-v1"
    echo "action=clear"
    echo "planned_metadata_17=null"
    echo "target_name=${NAME:-}"
    if [ -n "${MAC:-}" ]; then echo "target_mac=<redacted>"; else echo "target_mac="; fi
    echo "created_at=$TS"
    echo
    echo "== before =="
    if [ -n "${MAC:-}" ]; then
      /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-get.sh --mac "$MAC" 2>/dev/null || true
    else
      /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-get.sh --name "${NAME:-H222}" 2>/dev/null || true
    fi
  } > "$BACKUP_FILE"
  /system/bin/chmod 0600 "$BACKUP_FILE" 2>/dev/null || true
  echo "backup_saved=$BACKUP_FILE"
}

if [ "$DRY_RUN" = "1" ]; then
  echo "== dry-run clear type =="
  echo "DRY_RUN=yes"
  echo "planned_action=CLEAR_METADATA_17"
  echo "planned_metadata_17=null"
  echo "write_performed=no"
  echo
  echo "== target =="
  echo "target_selector=$( [ -n "${MAC:-}" ] && echo mac || echo name )"
  echo "name=${NAME:-}"
  if [ -n "${MAC:-}" ]; then echo "mac=<provided>"; else echo "mac="; fi
  echo
  echo "== current target state =="
  DRY_TMP="/data/local/tmp/asvd-bt-type-helper-clear-dryrun-get.txt"
  if [ -n "${MAC:-}" ]; then
    /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-get.sh --mac "$MAC" > "$DRY_TMP" 2>/dev/null || true
  else
    /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-get.sh --name "${NAME:-H222}" > "$DRY_TMP" 2>/dev/null || true
  fi
  /system/bin/grep -E "target_matches=|name=|metadata_17_before=|RESULT: ASVD_BT_TYPE_HELPER_GET_DONE|RESULT: ASVD_BT_TYPE_HELPER_GET_WRAPPER_DONE" "$DRY_TMP" || true
  PREVIOUS_TYPE="$(/system/bin/grep -m1 '^metadata_17_before=' "$DRY_TMP" 2>/dev/null | /system/bin/sed 's/^metadata_17_before=//' || true)"
  [ -n "$PREVIOUS_TYPE" ] || PREVIOUS_TYPE="unknown"
  echo
  asvd_state_write "$(target_display_name)" "clear" "DRY_RUN" "" "$PREVIOUS_TYPE" "$PREVIOUS_TYPE" "metadata_api" "0"
  echo "RESULT: ASVD_BT_TYPE_HELPER_CLEAR_DRY_RUN_DONE"
  exit 0
fi

if [ "$CONFIRM" != "--confirm-clear" ]; then
  echo "Refusing to clear without explicit confirmation."
  echo "Use: $0 [H222|--name NAME|--mac MAC] --confirm-clear"
  echo "Dry-run: $0 [H222|--name NAME|--mac MAC] --dry-run"
  echo "RESULT: ASVD_BT_TYPE_HELPER_CLEAR_CONFIRM_REQUIRED"
  exit 2
fi

echo "== preflight =="
/system/bin/pm path "$PKG" || true

echo
echo "== target =="
echo "target_selector=$( [ -n "${MAC:-}" ] && echo mac || echo name )"
echo "name=${NAME:-}"
if [ -n "${MAC:-}" ]; then echo "mac=<provided>"; else echo "mac="; fi

echo
echo "== backup before clear =="
save_backup
PREVIOUS_TYPE="$(/system/bin/grep -m1 '^metadata_17_before=' "$BACKUP_FILE" 2>/dev/null | /system/bin/sed 's/^metadata_17_before=//' || true)"
[ -n "$PREVIOUS_TYPE" ] || PREVIOUS_TYPE="unknown"

echo
echo "== clear old result/log =="
asvd_clear

echo
echo "== broadcast clear =="
asvd_broadcast "$PKG.CLEAR" || true

echo
echo "== wait =="
/system/bin/sleep 2
asvd_dump_results

CURRENT_TYPE="$(asvd_result_value metadata_17_after || true)"
[ -n "$CURRENT_TYPE" ] || CURRENT_TYPE="null"
STATE_RESULT="FAIL"
STATE_ERROR="clear_failed_or_unverified"
if asvd_result_has "RESULT: ASVD_BT_TYPE_HELPER_CLEAR_DONE"; then
  STATE_RESULT="PASS"
  STATE_ERROR=""
fi
asvd_state_write "$(target_display_name)" "clear" "$STATE_RESULT" "$STATE_ERROR" "$CURRENT_TYPE" "$PREVIOUS_TYPE" "metadata_api" "0"

echo
echo "RESULT: ASVD_BT_TYPE_HELPER_CLEAR_WRAPPER_DONE"
EOFG

cat > "$MOD/helper-report.sh" <<'EOFG'
#!/system/bin/sh
set -eu
. /data/adb/modules/asvd-bt-type-helper/helper-common.sh
asvd_target_args "$@"

echo "== ASVD BT Type Helper report =="
/system/bin/date

echo
echo "== device =="
echo "manufacturer=$(/system/bin/getprop ro.product.manufacturer 2>/dev/null || true)"
echo "brand=$(/system/bin/getprop ro.product.brand 2>/dev/null || true)"
echo "model=$(/system/bin/getprop ro.product.model 2>/dev/null || true)"
echo "device=$(/system/bin/getprop ro.product.device 2>/dev/null || true)"
echo "android_release=$(/system/bin/getprop ro.build.version.release 2>/dev/null || true)"
echo "android_sdk=$(/system/bin/getprop ro.build.version.sdk 2>/dev/null || true)"

echo
echo "== magisk =="
if [ -x /debug_ramdisk/magisk ]; then /debug_ramdisk/magisk -V 2>/dev/null || true; /debug_ramdisk/magisk -v 2>/dev/null || true; else echo "magisk_bin=not_found"; fi

echo
echo "== package =="
/system/bin/pm path "$PKG" || true
/system/bin/dumpsys package "$PKG" 2>/dev/null \
  | /system/bin/grep -Ei "versionName|versionCode|PRIVILEGED|BLUETOOTH|granted|User 0" \
  | /system/bin/sed -n "1,180p" || true

echo
echo "== helper target get =="
if [ -n "${MAC:-}" ]; then
  /data/adb/modules/asvd-bt-type-helper/helper-get.sh --mac "$MAC" 2>/dev/null \
    | /system/bin/grep -E "target_name=|target_mac=|target_matches=|name=|address=|metadata_17_before=|RESULT: ASVD_BT_TYPE_HELPER" || true
elif [ -n "${NAME:-}" ]; then
  /data/adb/modules/asvd-bt-type-helper/helper-get.sh --name "$NAME" 2>/dev/null \
    | /system/bin/grep -E "target_name=|target_mac=|target_matches=|name=|address=|metadata_17_before=|RESULT: ASVD_BT_TYPE_HELPER" || true
else
  /data/adb/modules/asvd-bt-type-helper/helper-get.sh 2>/dev/null \
    | /system/bin/grep -E "target_name=|target_mac=|target_matches=|name=|address=|metadata_17_before=|RESULT: ASVD_BT_TYPE_HELPER" || true
fi

echo
echo "RESULT: ASVD_BT_TYPE_HELPER_REPORT_DONE"
EOFG

cat > "$MOD/helper-debug.sh" <<'EOFG'
#!/system/bin/sh
set -eu

case " $* " in
  *" --show-mac "*)
    echo "Refusing --show-mac for public debug output."
    echo "Use helper-list.sh --show-mac only locally."
    echo "RESULT: ASVD_BT_TYPE_HELPER_DEBUG_REFUSED_RAW_MAC"
    exit 2
    ;;
esac

OUT_DIR="/storage/emulated/0/Download"
STAMP="$(/system/bin/date +%Y%m%d_%H%M%S 2>/dev/null || echo now)"
OUT="$OUT_DIR/ASVD-BT-Type-Helper-debug-$STAMP.txt"
MOD="/data/adb/modules/asvd-bt-type-helper"
PKG="org.asvd.bttypehelper"

redact_stream() {
  /system/bin/sed -E 's/([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}/<BT_MAC>/g'
}

{
  echo "== ASVD BT Type Helper GitHub/XDA debug =="
  /system/bin/date
  echo "redaction=on"
  echo "safe_to_paste_publicly=yes"
  echo

  echo "== module/package quick status =="
  /system/bin/pm path "$PKG" 2>/dev/null || true
  /system/bin/dumpsys package "$PKG" 2>/dev/null \
    | /system/bin/grep -Ei "versionName|versionCode|PRIVILEGED|BLUETOOTH|granted|User 0" \
    | /system/bin/sed -n "1,180p" || true
  echo

  echo "== helper files =="
  /system/bin/ls -l "$MOD"/helper-*.sh 2>/dev/null || true
  echo

  echo "== report =="
  /system/bin/sh "$MOD/helper-report.sh" "$@" 2>&1 || true
  echo

  echo "== recent ASVD logcat redacted =="
  /system/bin/logcat -d -t 400 2>/dev/null \
    | /system/bin/grep -Ei "ASVD-BT-HELPER|org.asvd|BtTypeReceiver|metadata_17|setMetadata|SecurityException|Permission Denial|RuntimeException|FATAL|RESULT: ASVD" \
    | /system/bin/tail -220 \
    | redact_stream || true
  echo

  echo "== paste guidance =="
  echo "Paste this report into GitHub/XDA. Do not add --show-mac output unless explicitly requested privately."
  echo
  echo "RESULT: ASVD_BT_TYPE_HELPER_DEBUG_DONE"
} | redact_stream > "$OUT"

/system/bin/cat "$OUT"
echo
echo "debug_file=$OUT"
echo "RESULT: ASVD_BT_TYPE_HELPER_DEBUG_FILE_WRITTEN"
EOFG


cat > "$MOD/helper-restore-last.sh" <<'EOFG'
#!/system/bin/sh
set -eu
MOD="/data/adb/modules/asvd-bt-type-helper"
BACKUP_DIR="$MOD/backups"
CONFIRM=""
DRY_RUN="0"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --confirm-restore) CONFIRM="--confirm-restore" ;;
    --dry-run) DRY_RUN="1" ;;
    --help|-h)
      echo "Usage: $0 [--dry-run] [--confirm-restore]"
      exit 0
      ;;
    *) echo "unknown_arg=$1"; exit 2 ;;
  esac
  shift
done
LAST="$(/system/bin/ls -1t "$BACKUP_DIR"/metadata17-before-*.txt 2>/dev/null | /system/bin/head -n 1 || true)"
[ -s "$LAST" ] || { echo "FAIL no_backup_found=$BACKUP_DIR"; echo "RESULT: ASVD_BT_TYPE_HELPER_RESTORE_LAST_FAIL"; exit 1; }
META="$(/system/bin/grep -m1 '^metadata_17_before=' "$LAST" | /system/bin/sed 's/^metadata_17_before=//' || true)"
MAC="$(/system/bin/grep -m1 '^target_mac=' "$LAST" | /system/bin/sed 's/^target_mac=//' || true)"
NAME="$(/system/bin/grep -m1 '^target_name=' "$LAST" | /system/bin/sed 's/^target_name=//' || true)"
if [ -z "$NAME" ]; then
  NAME="$(/system/bin/grep -m1 '^name=' "$LAST" | /system/bin/sed 's/^name=//' || true)"
fi

echo "== restore last metadata_17 backup =="
echo "backup=$LAST"
echo "target_name=${NAME:-}"
if [ -n "$MAC" ]; then echo "target_mac=<stored>"; else echo "target_mac="; fi
echo "restore_metadata_17=${META:-null}"
if [ "$DRY_RUN" = "1" ]; then
  echo "DRY_RUN=yes"
  echo "write_performed=no"
  echo "RESULT: ASVD_BT_TYPE_HELPER_RESTORE_LAST_DRY_RUN_DONE"
  exit 0
fi
[ "$CONFIRM" = "--confirm-restore" ] || { echo "Refusing to restore without --confirm-restore"; echo "RESULT: ASVD_BT_TYPE_HELPER_RESTORE_LAST_CONFIRM_REQUIRED"; exit 2; }
if [ "$META" = "null" ] || [ -z "$META" ]; then
  if [ -n "$MAC" ]; then exec /system/bin/sh "$MOD/helper-clear-type.sh" --mac "$MAC" --confirm-clear; fi
  exec /system/bin/sh "$MOD/helper-clear-type.sh" --name "${NAME:-H222}" --confirm-clear
else
  if [ -n "$MAC" ]; then exec /system/bin/sh "$MOD/helper-set-type.sh" --mac "$MAC" --type "$META" --confirm-set; fi
  exec /system/bin/sh "$MOD/helper-set-type.sh" --name "${NAME:-H222}" --type "$META" --confirm-set
fi
EOFG

cat > "$MOD/helper-compare-types.sh" <<'EOFG'
#!/system/bin/sh
set -eu
MOD="/data/adb/modules/asvd-bt-type-helper"
TMP="/data/local/tmp/asvd-compare-types.txt"
/system/bin/sh "$MOD/helper-list.sh" > "$TMP" 2>&1 || true
echo "== ASVD BT Type Helper metadata_17 type overview =="
/system/bin/awk '
  /^name=/ { name=substr($0,6); next }
  /^metadata_17=/ {
    meta=substr($0,13); if (meta == "") meta="null";
    if (name == "") name="<unknown>";
    item[meta]=item[meta] "\n- " name;
    name="";
  }
  END {
    for (m in item) print "\n" m ":" item[m];
  }
' "$TMP"
echo
echo "RESULT: ASVD_BT_TYPE_HELPER_COMPARE_TYPES_DONE"
EOFG

cat > "$MOD/helper-setup.sh" <<'EOFG'
#!/system/bin/sh
set -eu
. /data/adb/modules/asvd-bt-type-helper/helper-common.sh
CONF="/data/adb/asvd-bt-type-helper.conf"
TMP="/data/local/tmp/asvd-bt-type-helper-devices.tsv"
RESULT=""
SETUP_SHOW_MAC="0"
DRY_RUN="0"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --show-mac) SETUP_SHOW_MAC="1" ;;
    --dry-run) DRY_RUN="1" ;;
    --help|-h)
      echo "Usage: $0 [--show-mac] [--dry-run]"
      echo "Default redacts MAC addresses in terminal output. Use --show-mac only locally."
      echo "Dry-run resolves targets and actions but does not write metadata or save config."
      exit 0
      ;;
    *) echo "unknown_arg=$1"; exit 2 ;;
  esac
  shift
done

cancel_setup() { echo "cancelled=yes"; echo "RESULT: ASVD_BT_TYPE_HELPER_SETUP_CANCELLED"; exit 0; }

find_result() {
  for f in "/data_mirror/data_ce/null/0/$PKG/files/last-result.txt" "/data/user/0/$PKG/files/last-result.txt" "/data_mirror/data_de/null/0/$PKG/files/last-result.txt"; do
    if [ -s "$f" ]; then echo "$f"; return 0; fi
  done
  return 1
}

parse_devices() {
  RESULT="$1"
  /system/bin/awk '
    /^-- device / { if (idx>0) print idx "	" name "	" addr "	" meta; idx=$3; gsub("--", "", idx); name=""; addr=""; meta=""; next }
    /^name=/ { name=substr($0,6); next }
    /^address=/ { addr=substr($0,9); next }
    /^metadata_17=/ { meta=substr($0,13); next }
    END { if (idx>0) print idx "	" name "	" addr "	" meta }
  ' "$RESULT" > "$TMP"
}

print_devices() {
  /system/bin/awk -F "	" -v showmac="$SETUP_SHOW_MAC" '
    { count[$2]++ }
    { rows[NR]=$0 }
    END {
      print "Recommended / known target:"
      for (i=1; i<=NR; i++) {
        split(rows[i], f, "	")
        if (f[2] == "H222") {
          mac = (showmac == "1") ? f[3] : "<BT_MAC>"
          dup = (count[f[2]] > 1) ? "  duplicate_name=yes" : ""
          printf("[%s] %s  mac=%s  metadata_17=%s%s  recommended=car/Carkit\n", f[1], f[2], mac, f[4], dup)
        }
      }
      print ""
      print "All paired devices:"
      for (i=1; i<=NR; i++) {
        split(rows[i], f, "	")
        mac = (showmac == "1") ? f[3] : "<BT_MAC>"
        dup = (count[f[2]] > 1) ? "  duplicate_name=yes" : ""
        expflag = (f[4] == "Speaker" || f[4] == "Headset" || f[4] == "Untethered Headset" || f[4] == "Watch" || f[4] == "Stylus" || f[4] == "HearingAid" || f[4] == "Default") ? "  experimental_type=yes" : ""
        printf("[%s] %s  mac=%s  metadata_17=%s%s%s\n", f[1], f[2], mac, f[4], dup, expflag)
      }
    }
  ' "$TMP"
}

run_get_for_mac() { /data/adb/modules/asvd-bt-type-helper/helper-get.sh --mac "$1" | /system/bin/grep -E "target_matches=|name=|metadata_17_before=|RESULT: ASVD_BT_TYPE_HELPER" || true; }

save_config() {
  [ "$DRY_RUN" = "1" ] && { echo "config_write=skipped_dry_run"; return 0; }
  {
    echo "target_name=$NAME"
    echo "target_mac=$MAC"
    echo "target_type=$TARGET_TYPE"
    echo "show_mac=0"
    echo "require_confirm=1"
  } > "$CONF"
  /system/bin/chmod 0600 "$CONF" 2>/dev/null || true
  echo "config=$CONF"
}

echo "== ASVD BT Type Helper setup v0.5.6 =="
echo "This wizard lists paired devices, reads the selected target, then asks before writing."
[ "$DRY_RUN" = "1" ] && echo "DRY_RUN=yes: no metadata write and no config write will be performed."
if [ "$SETUP_SHOW_MAC" = "1" ]; then echo "MAC display: raw/local only. Do not paste public logs."; else echo "MAC display: redacted. Use --show-mac only locally if needed."; fi
echo

/system/bin/pm path "$PKG" >/dev/null || { echo "FAIL package_not_visible"; echo "RESULT: ASVD_BT_TYPE_HELPER_SETUP_FAIL"; exit 1; }

echo "== list devices =="
asvd_clear
NAME=""; MAC=""; SHOW_MAC="1"
asvd_broadcast "$PKG.LIST" >/dev/null || true
/system/bin/sleep 2
RESULT="$(find_result || true)"
[ -n "$RESULT" ] || { echo "FAIL no_list_result"; echo "RESULT: ASVD_BT_TYPE_HELPER_SETUP_FAIL"; exit 1; }
parse_devices "$RESULT"
[ -s "$TMP" ] || { echo "FAIL no_devices_parsed"; echo "RESULT: ASVD_BT_TYPE_HELPER_SETUP_FAIL"; exit 1; }

print_devices
echo
printf "Select device number, or q to quit: "
if ! read -r SEL; then cancel_setup; fi
case "$SEL" in q|Q|quit|Quit|exit|Exit|"") cancel_setup ;; esac
LINE="$(/system/bin/awk -F "	" -v n="$SEL" '$1==n {print; exit}' "$TMP")"
[ -n "$LINE" ] || { echo "FAIL invalid_selection=$SEL"; echo "RESULT: ASVD_BT_TYPE_HELPER_SETUP_FAIL"; exit 2; }
NAME="$(echo "$LINE" | /system/bin/cut -f2)"
MAC="$(echo "$LINE" | /system/bin/cut -f3)"
META="$(echo "$LINE" | /system/bin/cut -f4)"
DUP_COUNT="$(/system/bin/awk -F "	" -v n="$NAME" '$2==n {c++} END {print c+0}' "$TMP")"

echo
echo "Selected device:"
echo "Name: $NAME"
if [ "$SETUP_SHOW_MAC" = "1" ]; then echo "MAC: $MAC"; else echo "MAC: <selected>"; fi
echo "Current type: $META"
[ "$DUP_COUNT" -gt 1 ] && echo "Duplicate name: yes; number selection keeps the selected internal MAC."
case "$META" in
  Carkit) echo "Recommended action: read only or keep car/Carkit" ;;
  null|"") echo "Recommended action: read only first; set only if you know the intended type" ;;
  *) echo "Recommended action: read only first; current type is $META" ;;
esac

echo
echo "== verify selected target =="
run_get_for_mac "$MAC"

echo
echo "Available actions:"
echo "[1] read only / no change"
echo "[2] set car / Carkit (verified reference)"
echo "[3] set speaker / Speaker (experimental)"
echo "[4] set headset / Headset (experimental; headphones alias)"
echo "[5] set untethered headset / TWS / earbuds (experimental)"
echo "[6] set watch / Watch (experimental)"
echo "[7] set stylus / Stylus (experimental)"
echo "[8] set hearing aid / HearingAid (experimental)"
echo "[9] set default / Default (experimental)"
echo "[10] clear metadata key 17"
echo "[q] quit"
printf "Select action: "
if ! read -r ACTION; then cancel_setup; fi
case "$ACTION" in
  q|Q|quit|Quit|exit|Exit|"") cancel_setup ;;
  1) TARGET_TYPE="read-only"; /data/adb/modules/asvd-bt-type-helper/helper-get.sh --mac "$MAC" ;;
  2|3|4|5|6|7|8|9)
    case "$ACTION" in
      2) TARGET_TYPE="car"; PRETTY="Carkit" ;;
      3) TARGET_TYPE="speaker"; PRETTY="Speaker (experimental)" ;;
      4) TARGET_TYPE="headset"; PRETTY="Headset (experimental)" ;;
      5) TARGET_TYPE="untethered-headset"; PRETTY="Untethered Headset (experimental)" ;;
      6) TARGET_TYPE="watch"; PRETTY="Watch (experimental)" ;;
      7) TARGET_TYPE="stylus"; PRETTY="Stylus (experimental)" ;;
      8) TARGET_TYPE="hearingaid"; PRETTY="HearingAid (experimental)" ;;
      9) TARGET_TYPE="default"; PRETTY="Default (experimental)" ;;
    esac
    echo
    echo "About to set: $NAME -> $PRETTY"
    if [ "$DRY_RUN" = "1" ]; then
      /data/adb/modules/asvd-bt-type-helper/helper-set-type.sh --mac "$MAC" --type "$TARGET_TYPE" --dry-run
    else
      printf "Type YES to continue: "; if ! read -r YES; then cancel_setup; fi
      [ "$YES" = "YES" ] || cancel_setup
      /data/adb/modules/asvd-bt-type-helper/helper-set-type.sh --mac "$MAC" --type "$TARGET_TYPE" --confirm-set
    fi
    ;;
  10)
    TARGET_TYPE="clear"
    echo
    echo "About to clear metadata key 17 for: $NAME"
    if [ "$DRY_RUN" = "1" ]; then
      /data/adb/modules/asvd-bt-type-helper/helper-clear-type.sh --mac "$MAC" --dry-run
    else
      printf "Type YES to continue: "; if ! read -r YES; then cancel_setup; fi
      [ "$YES" = "YES" ] || cancel_setup
      /data/adb/modules/asvd-bt-type-helper/helper-clear-type.sh --mac "$MAC" --confirm-clear
    fi
    ;;
  *) echo "FAIL invalid_action=$ACTION"; echo "RESULT: ASVD_BT_TYPE_HELPER_SETUP_FAIL"; exit 2 ;;
esac

echo
echo "== save config =="
save_config

echo
echo "== final verify =="
run_get_for_mac "$MAC"

echo
echo "RESULT: ASVD_BT_TYPE_HELPER_SETUP_DONE"
EOFG
cat > "$MOD/helper-apply-config.sh" <<'EOFG'
#!/system/bin/sh
set -eu
CONF="/data/adb/asvd-bt-type-helper.conf"
DRY_RUN="0"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN="1" ;;
    --help|-h)
      echo "Usage: $0 [--dry-run]"
      exit 0
      ;;
    *) echo "unknown_arg=$1"; exit 2 ;;
  esac
  shift
done
[ -s "$CONF" ] || { echo "FAIL config_missing=$CONF"; echo "RESULT: ASVD_BT_TYPE_HELPER_APPLY_CONFIG_FAIL"; exit 1; }
# shellcheck disable=SC1090
. "$CONF"
TARGET_MAC="${target_mac:-}"
TARGET_NAME="${target_name:-}"
TARGET_TYPE="${target_type:-}"

run_for_target() {
  SCRIPT="$1"
  shift
  if [ -n "$TARGET_MAC" ]; then
    /system/bin/sh "$SCRIPT" --mac "$TARGET_MAC" "$@"
  elif [ -n "$TARGET_NAME" ]; then
    /system/bin/sh "$SCRIPT" --name "$TARGET_NAME" "$@"
  else
    /system/bin/sh "$SCRIPT" "$@"
  fi
}

echo "== apply config =="
echo "target_name=${TARGET_NAME:-}"
if [ -n "$TARGET_MAC" ]; then echo "target_mac=<configured>"; else echo "target_mac="; fi
echo "target_type=$TARGET_TYPE"
echo "dry_run=$DRY_RUN"
echo

case "$TARGET_TYPE" in
  car|carkit|auto|speaker|headphones|headset|untethered-headset|earbuds|tws|watch|stylus|pen|hearingaid|hearing-aid|default)
    if [ "$DRY_RUN" = "1" ]; then
      run_for_target /data/adb/modules/asvd-bt-type-helper/helper-set-type.sh --type "$TARGET_TYPE" --dry-run
    else
      run_for_target /data/adb/modules/asvd-bt-type-helper/helper-set-type.sh --type "$TARGET_TYPE" --confirm-set
    fi
    ;;
  clear)
    if [ "$DRY_RUN" = "1" ]; then
      run_for_target /data/adb/modules/asvd-bt-type-helper/helper-clear-type.sh --dry-run
    else
      run_for_target /data/adb/modules/asvd-bt-type-helper/helper-clear-type.sh --confirm-clear
    fi
    ;;
  read-only|"")
    run_for_target /data/adb/modules/asvd-bt-type-helper/helper-get.sh
    ;;
  *) echo "FAIL unsupported_config_target_type=$TARGET_TYPE"; echo "RESULT: ASVD_BT_TYPE_HELPER_APPLY_CONFIG_FAIL"; exit 2 ;;
esac

echo
echo "RESULT: ASVD_BT_TYPE_HELPER_APPLY_CONFIG_DONE"
EOFG


cat > "$MOD/helper-doctor.sh" <<'EOFG'
#!/system/bin/sh
set -eu
PKG="org.asvd.bttypehelper"
MOD="/data/adb/modules/asvd-bt-type-helper"
PROP="$MOD/module.prop"

pass() { echo "PASS $1"; }
warn() { echo "WARN $1"; }
fail() { echo "FAIL $1"; FAILS=$((FAILS + 1)); }
FAILS=0

echo "== ASVD BT Type Helper doctor =="
/system/bin/date

echo
echo "== module =="
[ -d "$MOD" ] && pass "module_path=$MOD" || fail "module_path_missing=$MOD"
[ -s "$PROP" ] && pass "module_prop_present" || fail "module_prop_missing"
if [ -s "$PROP" ]; then
  /system/bin/grep -E "^version=|^versionCode=|^updateJson=" "$PROP" || true
  /system/bin/grep -q "^versionCode=56$" "$PROP" && pass "versionCode=56" || warn "versionCode_not_56_or_unreadable"
  /system/bin/grep -q "^updateJson=https://raw.githubusercontent.com/Lycidias93/asvd-bt-type-helper/main/update.json$" "$PROP" && pass "updateJson_present" || fail "updateJson_missing"
fi

echo
echo "== package =="
PKG_PATH="$(/system/bin/pm path "$PKG" 2>/dev/null | /system/bin/head -n 1 || true)"
echo "package_path=$PKG_PATH"
case "$PKG_PATH" in
  package:/system/priv-app/*) pass "priv_app_path" ;;
  package:/data/app/*) fail "data_app_shadow" ;;
  "") fail "package_not_visible" ;;
  *) warn "unexpected_package_path" ;;
esac

echo
echo "== permissions =="
/system/bin/pm grant "$PKG" android.permission.BLUETOOTH_CONNECT >/dev/null 2>&1 || true
PERMS="$(/system/bin/dumpsys package "$PKG" 2>/dev/null | /system/bin/grep -Ei "BLUETOOTH_CONNECT|BLUETOOTH_PRIVILEGED|granted=true" | /system/bin/sed -n "1,120p" || true)"
echo "$PERMS"
echo "$PERMS" | /system/bin/grep -q "BLUETOOTH_PRIVILEGED: granted=true" && pass "bluetooth_privileged_granted" || warn "bluetooth_privileged_not_seen"
echo "$PERMS" | /system/bin/grep -q "BLUETOOTH_CONNECT: granted=true" && pass "bluetooth_connect_granted" || warn "bluetooth_connect_not_seen"

echo
echo "== helper files =="
for f in helper-common.sh helper-grant.sh helper-list.sh helper-get.sh helper-set-type.sh helper-clear-type.sh helper-report.sh helper-debug.sh helper-setup.sh helper-apply-config.sh helper-doctor.sh helper-update-info.sh helper-restore-last.sh helper-compare-types.sh asvd.sh; do
  if [ -s "$MOD/$f" ]; then
    /system/bin/sh -n "$MOD/$f" && pass "syntax_$f"
  else
    fail "missing_$f"
  fi
done

echo
echo "== bluetooth target read smoke =="
/system/bin/sh "$MOD/helper-get.sh" --name H222 2>/dev/null   | /system/bin/grep -E "target_matches=|metadata_17_before=|RESULT: ASVD_BT_TYPE_HELPER_GET_DONE|RESULT: ASVD_BT_TYPE_HELPER_GET_WRAPPER_DONE" || warn "h222_get_no_output"

echo
echo "== summary =="
echo "failures=$FAILS"
if [ "$FAILS" -eq 0 ]; then
  echo "RESULT: ASVD_BT_TYPE_HELPER_DOCTOR_PASS"
else
  echo "RESULT: ASVD_BT_TYPE_HELPER_DOCTOR_FAIL"
  exit 1
fi
EOFG

cat > "$MOD/helper-update-info.sh" <<'EOFG'
#!/system/bin/sh
set -eu
MOD="/data/adb/modules/asvd-bt-type-helper"
PROP="$MOD/module.prop"

echo "== ASVD BT Type Helper update info =="
if [ -s "$PROP" ]; then
  /system/bin/grep -E "^version=|^versionCode=|^updateJson=" "$PROP" || true
else
  echo "module_prop_missing=$PROP"
fi

echo
echo "online_update_supported=yes"
echo "latest_json_url=https://raw.githubusercontent.com/Lycidias93/asvd-bt-type-helper/main/update.json"
echo "note=Magisk uses versionCode for update comparison."
echo "RESULT: ASVD_BT_TYPE_HELPER_UPDATE_INFO_DONE"
EOFG

cat > "$MOD/asvd.sh" <<'EOFG'
#!/system/bin/sh
set -eu
MOD="/data/adb/modules/asvd-bt-type-helper"

while true; do
  echo "== ASVD BT Type Helper v0.5.6 =="
  echo "[1] Setup wizard"
  echo "[2] Setup wizard dry-run"
  echo "[3] List devices"
  echo "[4] Compare current metadata types"
  echo "[5] Read device by name"
  echo "[6] Set type dry-run"
  echo "[7] Set type confirmed"
  echo "[8] Clear type dry-run"
  echo "[9] Restore last backup dry-run"
  echo "[10] Restore last backup confirmed"
  echo "[11] Debug report"
  echo "[12] Doctor"
  echo "[13] Update info"
  echo "[q] Quit"
  printf "Select: "
  if ! read -r choice; then exit 0; fi
  case "$choice" in
    1) /system/bin/sh "$MOD/helper-setup.sh" ;;
    2) /system/bin/sh "$MOD/helper-setup.sh" --dry-run ;;
    3) /system/bin/sh "$MOD/helper-list.sh" ;;
    4) /system/bin/sh "$MOD/helper-compare-types.sh" ;;
    5)
      printf "Device name [H222]: "; read -r name || name=""; [ -n "$name" ] || name="H222"
      /system/bin/sh "$MOD/helper-get.sh" --name "$name"
      ;;
    6)
      printf "Device name [H222]: "; read -r name || name=""; [ -n "$name" ] || name="H222"
      printf "Type [car|speaker|headset|untethered-headset|watch|stylus|hearingaid|default|clear]: "; read -r typ || typ=""; [ -n "$typ" ] || typ="car"
      /system/bin/sh "$MOD/helper-set-type.sh" --name "$name" --type "$typ" --dry-run
      ;;
    7)
      printf "Device name [H222]: "; read -r name || name=""; [ -n "$name" ] || name="H222"
      printf "Type [car|speaker|headset|untethered-headset|watch|stylus|hearingaid|default|clear]: "; read -r typ || typ=""; [ -n "$typ" ] || typ="car"
      echo "About to write metadata for $name -> $typ"
      printf "Type YES to continue: "; read -r yes || yes=""
      [ "$yes" = "YES" ] || { echo "cancelled=yes"; continue; }
      /system/bin/sh "$MOD/helper-set-type.sh" --name "$name" --type "$typ" --confirm-set
      ;;
    8)
      printf "Device name [H222]: "; read -r name || name=""; [ -n "$name" ] || name="H222"
      /system/bin/sh "$MOD/helper-clear-type.sh" --name "$name" --dry-run
      ;;
    9) /system/bin/sh "$MOD/helper-restore-last.sh" --dry-run ;;
    10)
      echo "About to restore the last metadata_17 backup."
      printf "Type YES to continue: "; read -r yes || yes=""
      [ "$yes" = "YES" ] || { echo "cancelled=yes"; continue; }
      /system/bin/sh "$MOD/helper-restore-last.sh" --confirm-restore
      ;;
    11)
      printf "Device name [H222]: "; read -r name || name=""; [ -n "$name" ] || name="H222"
      /system/bin/sh "$MOD/helper-debug.sh" --name "$name"
      ;;
    12) /system/bin/sh "$MOD/helper-doctor.sh" ;;
    13) /system/bin/sh "$MOD/helper-update-info.sh" ;;
    q|Q|quit|exit) exit 0 ;;
    *) echo "unknown_selection=$choice" ;;
  esac
  echo
  echo "Press Enter to continue..."
  read -r _ || true
  echo
done
EOFG

chmod 0755 "$MOD"/helper-*.sh "$MOD/asvd.sh" "$MOD/customize.sh"

cat > "$MOD/README.md" <<'EOFREADME'
# ASVD BT Type Helper v0.5.6

User-friendly privileged Bluetooth metadata helper.

Scope:
- Root/Magisk required
- Priv-app helper APK
- One-command main menu: `asvd.sh`
- True dry-run support for setup, set, clear, config apply, and restore preview
- All known Android Bluetooth metadata device type values: `Default`, `Watch`, `Untethered Headset`, `Stylus`, `Speaker`, `Headset`, `Carkit`, `HearingAid`
- Aliases: `car`, `speaker`, `headphones`, `headset`, `earbuds`, `tws`, `watch`, `stylus`, `hearingaid`, `default`, `clear`
- Backup before confirmed metadata writes/clears
- Restore-last helper
- Compare-types helper
- Doctor helper for fast support diagnosis
- Interactive setup wizard with redacted MAC output by default
- Report/debug helpers for GitHub/XDA
- Magisk online update metadata via updateJson
- Manual only; no boot automation
- No GMS manipulation
- No Bluetooth reload
- No direct `/data/misc/bluedroid/bt_config.conf` patching

Quick start after flashing and reboot:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-grant.sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/asvd.sh
```

Safe checks:

```sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-doctor.sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-setup.sh --dry-run
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-compare-types.sh
tsu /system/bin/sh /data/adb/modules/asvd-bt-type-helper/helper-set-type.sh --name H222 --type car --dry-run
```

`car/Carkit` is verified on H222. Other type values are experimental until device feedback confirms UI behavior.
EOFREADME

printf '\n== syntax ==\n'
for f in customize.sh helper-common.sh helper-grant.sh helper-list.sh helper-get.sh helper-set-carkit.sh helper-set-type.sh helper-clear-type.sh helper-report.sh helper-debug.sh helper-setup.sh helper-apply-config.sh helper-doctor.sh helper-update-info.sh helper-restore-last.sh helper-compare-types.sh asvd.sh; do
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

printf '\n== write update.json ==\n'
UPDATE_JSON="/storage/emulated/0/Download/update.json"
cat > "$UPDATE_JSON" <<EOFUPDATE
{
  "version": "$VER",
  "versionCode": $VERSION_CODE,
  "zipUrl": "https://github.com/Lycidias93/asvd-bt-type-helper/releases/download/$TAG/ASVD-BT-Type-Helper-$TAG.zip",
  "changelog": "https://github.com/Lycidias93/asvd-bt-type-helper/releases/tag/$TAG"
}
EOFUPDATE
python -m json.tool "$UPDATE_JSON" >/dev/null

printf '\n== artifacts ==\n'
ls -lh "$OUT" "$OUT.sha256" "$UPDATE_JSON"

printf '\nRESULT: ASVD_BT_TYPE_HELPER_PRIVAPP_V064_BUILD_DONE\n'
