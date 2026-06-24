package org.asvd.bttypehelper;

import java.lang.reflect.*;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.regex.Pattern;

public class RootBridge {
  static final int KEY_DEVICE_TYPE = 17;
  static final Pattern MAC_RE = Pattern.compile("(?i)^([0-9a-f]{2}:){5}[0-9a-f]{2}$");
  static boolean showMac = false;

  static String s(Object o){ return o == null ? "null" : String.valueOf(o); }
  static String mask(String v){ return v == null ? "null" : v.replaceAll("(?i)([0-9a-f]{2}:){5}[0-9a-f]{2}", "<BT_MAC>"); }
  static String addr(String v){ return showMac ? s(v) : mask(v); }
  static Throwable cause(Throwable t){ return t instanceof InvocationTargetException && ((InvocationTargetException)t).getCause()!=null ? ((InvocationTargetException)t).getCause() : t; }
  static Object invoke(Object o, String n, Class[] sig, Object[] args) throws Exception { Method m=o.getClass().getMethod(n, sig); m.setAccessible(true); return m.invoke(o,args); }
  static Object invokeStatic(Class<?> c, String n, Class[] sig, Object[] args) throws Exception { Method m=c.getMethod(n, sig); m.setAccessible(true); return m.invoke(null,args); }
  static String bytesToText(Object o){ if(o == null) return "null"; try { return new String((byte[]) o, StandardCharsets.UTF_8); } catch(Throwable t){ return "bytes_or_object=" + o.getClass().getName(); } }
  static byte[] bytes(String v){ return v.getBytes(StandardCharsets.UTF_8); }
  static String norm(String v){
    if(v == null) return null;
    String x = v.trim().toLowerCase(Locale.US).replace('_','-');
    if(x.equals("car") || x.equals("auto") || x.equals("carkit") || x.equals("car-kit")) return "Carkit";
    if(x.equals("speaker") || x.equals("lautsprecher")) return "Speaker";
    if(x.equals("headset") || x.equals("headsets") || x.equals("headphones") || x.equals("headphone") || x.equals("kopfhörer") || x.equals("kopfhoerer")) return "Headset";
    if(x.equals("untethered-headset") || x.equals("untethered") || x.equals("earbuds") || x.equals("earbud") || x.equals("buds") || x.equals("tws") || x.equals("true-wireless")) return "Untethered Headset";
    if(x.equals("watch") || x.equals("smartwatch") || x.equals("wearable")) return "Watch";
    if(x.equals("stylus") || x.equals("pen") || x.equals("stift")) return "Stylus";
    if(x.equals("hearingaid") || x.equals("hearing-aid") || x.equals("hearing-aids") || x.equals("hearing-aid")) return "HearingAid";
    if(x.equals("default") || x.equals("android-default") || x.equals("reset-default") || x.equals("clear")) return "Default";
    return v.trim();
  }

  static Object attr(int uid, String pkg) {
    try {
      Class<?> b = Class.forName("android.content.AttributionSource$Builder");
      Object builder = b.getConstructor(int.class).newInstance(Integer.valueOf(uid));
      try { b.getMethod("setPackageName", String.class).invoke(builder, pkg); } catch(Throwable ignored) {}
      return b.getMethod("build").invoke(builder);
    } catch(Throwable t) { return null; }
  }

  static Object callbackProxy() throws Exception {
    Class<?> cbIface = Class.forName("android.bluetooth.IBluetoothManagerCallback");
    final Object binder = Class.forName("android.os.Binder").getConstructor().newInstance();
    return Proxy.newProxyInstance(cbIface.getClassLoader(), new Class[]{cbIface}, new InvocationHandler(){
      public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        String n = method.getName();
        if(n.equals("asBinder")) return binder;
        if(n.equals("toString")) return "ASVDBtRootBridgeCallback";
        if(n.equals("hashCode")) return Integer.valueOf(System.identityHashCode(proxy));
        if(n.equals("equals")) return Boolean.valueOf(proxy == (args == null ? null : args[0]));
        return null;
      }
    });
  }

  static class Bt {
    Object adapter;
    Object attr;
    Class<?> btDev;
    Bt(Object adapter, Object attr, Class<?> btDev){ this.adapter=adapter; this.attr=attr; this.btDev=btDev; }
  }

  static Bt connect() throws Exception {
    Object attrAndroid = attr(1000, "android");
    Object attrShell = attr(2000, "com.android.shell");
    Object attrRoot = attr(0, "root");
    Class<?> sm = Class.forName("android.os.ServiceManager");
    Object binder = invokeStatic(sm, "getService", new Class[]{String.class}, new Object[]{"bluetooth_manager"});
    System.out.println("bluetooth_manager_binder_null=" + (binder == null));
    if(binder == null) throw new RuntimeException("no bluetooth_manager binder");
    Class<?> mgrStub = Class.forName("android.bluetooth.IBluetoothManager$Stub");
    Object mgr = invokeStatic(mgrStub, "asInterface", new Class[]{Class.forName("android.os.IBinder")}, new Object[]{binder});
    System.out.println("manager_class=" + (mgr == null ? "null" : mgr.getClass().getName()));
    Object cb = callbackProxy();
    Object adapterBinder = invoke(mgr, "registerAdapter", new Class[]{Class.forName("android.bluetooth.IBluetoothManagerCallback")}, new Object[]{cb});
    System.out.println("call_registerAdapter_ok=yes");
    System.out.println("adapter_binder_class=" + (adapterBinder == null ? "null" : adapterBinder.getClass().getName()));
    if(adapterBinder == null) throw new RuntimeException("registerAdapter returned null");
    Class<?> ibStub = Class.forName("android.bluetooth.IBluetooth$Stub");
    Object adapter = invokeStatic(ibStub, "asInterface", new Class[]{Class.forName("android.os.IBinder")}, new Object[]{adapterBinder});
    System.out.println("adapter_class=" + (adapter == null ? "null" : adapter.getClass().getName()));
    if(adapter == null) throw new RuntimeException("IBluetooth adapter null");
    Class<?> btDev = Class.forName("android.bluetooth.BluetoothDevice");
    Object[] attrs = new Object[]{attrAndroid, attrShell, attrRoot};
    Object attrChosen = null;
    for(int i=0;i<attrs.length;i++){
      if(attrs[i] == null) continue;
      try { getBonded(adapter, attrs[i]); attrChosen = attrs[i]; System.out.println("used_attr_index=" + i); break; }
      catch(Throwable t){ Throwable c=cause(t); System.out.println("attr_index_"+i+"_bonded_fail="+c.getClass().getName()+": "+mask(c.getMessage())); }
    }
    if(attrChosen == null) throw new RuntimeException("no working AttributionSource");
    return new Bt(adapter, attrChosen, btDev);
  }

  static List getBonded(Object adapter, Object attr) throws Exception {
    Object out = invoke(adapter, "getBondedDevices", new Class[]{Class.forName("android.content.AttributionSource")}, new Object[]{attr});
    if(out instanceof List) return (List) out;
    if(out instanceof Collection) return new ArrayList((Collection) out);
    if(out instanceof Object[]) return Arrays.asList((Object[])out);
    throw new RuntimeException("unexpected bonded type=" + (out == null ? "null" : out.getClass().getName()));
  }
  static String remoteName(Bt bt, Object dev){ try { return (String) invoke(bt.adapter,"getRemoteName",new Class[]{bt.btDev,Class.forName("android.content.AttributionSource")},new Object[]{dev,bt.attr}); } catch(Throwable t){ return null; } }
  static String remoteAlias(Bt bt, Object dev){ try { return (String) invoke(bt.adapter,"getRemoteAlias",new Class[]{bt.btDev,Class.forName("android.content.AttributionSource")},new Object[]{dev,bt.attr}); } catch(Throwable t){ return null; } }
  static String localName(Object dev){ try { return (String) invoke(dev,"getName",new Class[]{},new Object[]{}); } catch(Throwable t){ return null; } }
  static String address(Object dev){ try { return (String) invoke(dev,"getAddress",new Class[]{},new Object[]{}); } catch(Throwable t){ return null; } }
  static Object getMeta(Bt bt, Object dev) throws Exception { return invoke(bt.adapter,"getMetadata",new Class[]{bt.btDev,int.class,Class.forName("android.content.AttributionSource")},new Object[]{dev,Integer.valueOf(KEY_DEVICE_TYPE),bt.attr}); }
  static boolean setMeta(Bt bt, Object dev, String value) throws Exception { Object out=invoke(bt.adapter,"setMetadata",new Class[]{bt.btDev,int.class,byte[].class,Class.forName("android.content.AttributionSource")},new Object[]{dev,Integer.valueOf(KEY_DEVICE_TYPE),bytes(value),bt.attr}); return Boolean.TRUE.equals(out); }

  static Object find(Bt bt, String name, String mac, List list) {
    int nameMatches=0, macMatches=0; Object selected=null;
    for(Object d: (List<Object>) list){
      String rn=remoteName(bt,d), ln=localName(d), al=remoteAlias(bt,d), ad=address(d);
      boolean nm = name != null && (name.equals(rn) || name.equals(ln) || name.equals(al));
      boolean mm = mac != null && ad != null && mac.equalsIgnoreCase(ad);
      if(nm) nameMatches++; if(mm) macMatches++;
      if(selected == null && (mm || nm)) selected = d;
    }
    System.out.println("target_name_matches=" + nameMatches);
    System.out.println("target_mac_matches=" + macMatches);
    return selected;
  }

  static Map<String,String> parse(String[] args) {
    Map<String,String> m = new LinkedHashMap<String,String>();
    for(int i=0;i<args.length;i++){
      String a=args[i];
      if(a.equals("--show-mac")){ showMac=true; continue; }
      if((a.equals("--name") || a.equals("--mac") || a.equals("--type")) && i+1<args.length){ m.put(a.substring(2), args[++i]); continue; }
      if(a.equals("--dry-run")){ m.put("dry-run","1"); continue; }
    }
    return m;
  }

  static void usage(){ System.out.println("usage: RootBridge list [--show-mac] | get --name N|--mac M [--show-mac] | set --name N|--mac M --type TYPE [--dry-run]"); }

  public static void main(String[] args) throws Exception {
    System.out.println("bridge_version=0.6.4-root-bridge-lab.1");
    if(args.length < 1){ usage(); System.out.println("RESULT: ASVD_BT_ROOT_BRIDGE_USAGE"); return; }
    String cmd=args[0];
    Map<String,String> p=parse(Arrays.copyOfRange(args,1,args.length));
    Bt bt=connect();
    List bonded=getBonded(bt.adapter,bt.attr);
    System.out.println("bonded_count=" + bonded.size());
    if(cmd.equals("list")){
      int idx=0;
      for(Object d: (List<Object>) bonded){
        System.out.println("device_index=" + idx++);
        System.out.println("name=" + s(remoteName(bt,d)));
        System.out.println("alias=" + s(remoteAlias(bt,d)));
        System.out.println("address=" + addr(address(d)));
      }
      System.out.println("RESULT: ASVD_BT_ROOT_BRIDGE_LIST_DONE"); return;
    }
    if(cmd.equals("get") || cmd.equals("set")){
      String name=p.get("name"), mac=p.get("mac");
      System.out.println("target_name=" + s(name));
      System.out.println("target_mac=" + addr(mac));
      Object dev=find(bt,name,mac,bonded);
      if(dev == null){ System.out.println("RESULT: ASVD_BT_ROOT_BRIDGE_TARGET_MISSING"); return; }
      System.out.println("selected_name=" + s(remoteName(bt,dev)));
      System.out.println("selected_alias=" + s(remoteAlias(bt,dev)));
      System.out.println("selected_address=" + addr(address(dev)));
      String before=bytesToText(getMeta(bt,dev));
      System.out.println("metadata_17_before=" + before);
      if(cmd.equals("get")){ System.out.println("RESULT: ASVD_BT_ROOT_BRIDGE_GET_DONE"); return; }
      String typ=norm(p.get("type"));
      System.out.println("metadata_17_set_value=" + s(typ));
      if(typ == null){ System.out.println("RESULT: ASVD_BT_ROOT_BRIDGE_SET_FAIL_NO_TYPE"); return; }
      if("1".equals(p.get("dry-run"))){ System.out.println("dry_run=1"); System.out.println("RESULT: ASVD_BT_ROOT_BRIDGE_SET_DRY_RUN_DONE"); return; }
      boolean setRes=setMeta(bt,dev,typ);
      System.out.println("metadata_17_set_result=" + setRes);
      String after=bytesToText(getMeta(bt,dev));
      System.out.println("metadata_17_after=" + after);
      System.out.println("metadata_17_after_equals_set=" + typ.equals(after));
      System.out.println(typ.equals(after) ? "RESULT: ASVD_BT_ROOT_BRIDGE_SET_DONE" : "RESULT: ASVD_BT_ROOT_BRIDGE_SET_FAIL_AFTER_MISMATCH");
      return;
    }
    usage();
    System.out.println("RESULT: ASVD_BT_ROOT_BRIDGE_UNKNOWN_COMMAND");
  }
}
