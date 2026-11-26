#!/bin/zsh

PID_FILE="/tmp/sketchybar_menubar_watcher.pid"
if [ -f "$PID_FILE" ]; then
  OLD_PID=$(<"$PID_FILE") 2>/dev/null
  if [ -n "$OLD_PID" ] && [ "$OLD_PID" != "$$" ]; then
    kill "$OLD_PID" 2>/dev/null
  fi
fi
print -r -- "$$" > "$PID_FILE"

exec /usr/bin/python3 - "$$" << 'PYEOF'
import ctypes
import ctypes.util
import os
import signal
import subprocess
import sys
import time

signal.alarm(0)
signal.signal(signal.SIGHUP, signal.SIG_IGN)
try:
    os.setsid()
except OSError:
    pass

SKETCHYBAR = "/opt/homebrew/opt/sketchybar/bin/sketchybar"
PID_FILE = "/tmp/sketchybar_menubar_watcher.pid"
MY_PID = sys.argv[1]
UTF8 = 0x08000100

cg = ctypes.cdll.LoadLibrary(ctypes.util.find_library("CoreGraphics"))
cf = ctypes.cdll.LoadLibrary(ctypes.util.find_library("CoreFoundation"))
cs = ctypes.CDLL("/System/Library/Frameworks/ApplicationServices.framework/Frameworks/ColorSync.framework/ColorSync")
sl = ctypes.CDLL("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight")

vp = ctypes.c_void_p

class CGPoint(ctypes.Structure):
    _fields_ = [("x", ctypes.c_double), ("y", ctypes.c_double)]

class CGRect(ctypes.Structure):
    _fields_ = [("x", ctypes.c_double), ("y", ctypes.c_double),
                ("w", ctypes.c_double), ("h", ctypes.c_double)]

cg.CGEventCreate.restype = vp
cg.CGEventCreate.argtypes = [vp]
cg.CGEventGetLocation.restype = CGPoint
cg.CGEventGetLocation.argtypes = [vp]
cg.CGGetActiveDisplayList.restype = ctypes.c_int32
cg.CGGetActiveDisplayList.argtypes = [
    ctypes.c_uint32, ctypes.POINTER(ctypes.c_uint32), ctypes.POINTER(ctypes.c_uint32)
]
cg.CGDisplayBounds.restype = CGRect
cg.CGDisplayBounds.argtypes = [ctypes.c_uint32]
cg.CGWindowListCopyWindowInfo.restype = vp
cg.CGWindowListCopyWindowInfo.argtypes = [ctypes.c_uint32, ctypes.c_uint32]
cg.CGRectMakeWithDictionaryRepresentation.restype = ctypes.c_bool
cg.CGRectMakeWithDictionaryRepresentation.argtypes = [vp, ctypes.POINTER(CGRect)]

cs.CGDisplayCreateUUIDFromDisplayID.restype = vp
cs.CGDisplayCreateUUIDFromDisplayID.argtypes = [ctypes.c_uint32]

cf.CFUUIDCreateString.restype = vp
cf.CFUUIDCreateString.argtypes = [vp, vp]
cf.CFArrayGetCount.restype = ctypes.c_long
cf.CFArrayGetCount.argtypes = [vp]
cf.CFArrayGetValueAtIndex.restype = vp
cf.CFArrayGetValueAtIndex.argtypes = [vp, ctypes.c_long]
cf.CFDictionaryGetValue.restype = vp
cf.CFDictionaryGetValue.argtypes = [vp, vp]
cf.CFNumberGetValue.restype = ctypes.c_bool
cf.CFNumberGetValue.argtypes = [vp, ctypes.c_long, vp]
cf.CFStringGetCString.restype = ctypes.c_bool
cf.CFStringGetCString.argtypes = [vp, ctypes.c_char_p, ctypes.c_long, ctypes.c_uint32]
cf.CFRelease.restype = None
cf.CFRelease.argtypes = [vp]

sl.SLSMainConnectionID.restype = ctypes.c_int
sl.SLSMainConnectionID.argtypes = []
sl.SLSGetMenuBarAutohideEnabled.restype = ctypes.c_int
sl.SLSGetMenuBarAutohideEnabled.argtypes = [ctypes.c_int, ctypes.POINTER(ctypes.c_int)]
sl.SLSGetSpaceManagementMode.restype = ctypes.c_int
sl.SLSGetSpaceManagementMode.argtypes = [ctypes.c_int]
sl.SLSCopyActiveMenuBarDisplayIdentifier.restype = vp
sl.SLSCopyActiveMenuBarDisplayIdentifier.argtypes = [ctypes.c_int]
sl.SLSSetActiveMenuBarDisplayIdentifier.restype = ctypes.c_int
sl.SLSSetActiveMenuBarDisplayIdentifier.argtypes = [ctypes.c_int, vp, vp]

kCGWindowLayer = vp.in_dll(cg, "kCGWindowLayer")
kCGWindowOwnerName = vp.in_dll(cg, "kCGWindowOwnerName")
kCGWindowBounds = vp.in_dll(cg, "kCGWindowBounds")
cid = sl.SLSMainConnectionID()
str_buf = ctypes.create_string_buffer(256)

def cfstr_to_py(ref):
    if not ref:
        return ""
    if cf.CFStringGetCString(ref, str_buf, 256, UTF8):
        return str_buf.value.decode("utf-8", "replace")
    return ""

def is_autohide_enabled():
    enabled = ctypes.c_int(0)
    sl.SLSGetMenuBarAutohideEnabled(cid, ctypes.byref(enabled))
    return enabled.value != 0

def get_active_menubar_uuid():
    ref = sl.SLSCopyActiveMenuBarDisplayIdentifier(cid)
    if not ref:
        return ""
    val = cfstr_to_py(ref)
    cf.CFRelease(ref)
    return val

def release_displays(displays):
    for item in displays:
        if item[4]:
            cf.CFRelease(item[4])

def discover_state():
    cnt = ctypes.c_uint32(0)
    cg.CGGetActiveDisplayList(0, None, ctypes.byref(cnt))
    displays = []
    if cnt.value > 0:
        dids = (ctypes.c_uint32 * cnt.value)()
        cg.CGGetActiveDisplayList(cnt.value, dids, ctypes.byref(cnt))
        for i in range(cnt.value):
            did = dids[i]
            b = cg.CGDisplayBounds(did)
            uuid_str = ""
            uuid_cf = None
            u_ref = cs.CGDisplayCreateUUIDFromDisplayID(did)
            if u_ref:
                uuid_cf = cf.CFUUIDCreateString(None, u_ref)
                cf.CFRelease(u_ref)
                if uuid_cf:
                    uuid_str = cfstr_to_py(uuid_cf)
            displays.append((b.x, b.x + b.w, b.y, uuid_str, uuid_cf))
    separate_spaces = (sl.SLSGetSpaceManagementMode(cid) == 1)
    return displays, is_autohide_enabled(), separate_spaces

def hovered_top_display(displays):
    ev = cg.CGEventCreate(None)
    if not ev:
        return None
    pt = cg.CGEventGetLocation(ev)
    cf.CFRelease(ev)
    for disp in displays:
        x0, x1, y0 = disp[0], disp[1], disp[2]
        if x0 <= pt.x <= x1 and (y0 - 5.0) <= pt.y <= (y0 + 56.0):
            return disp
    return None

def inspect_top_windows():
    # 17 = kCGWindowListOptionOnScreenOnly (1) | kCGWindowListExcludeDesktopElements (16)
    wlist = cg.CGWindowListCopyWindowInfo(17, 0)
    if not wlist:
        return False, False
    n = cf.CFArrayGetCount(wlist)
    menubar_vis = False
    first_mb25_z = None
    max_sb25_z = None
    layer = ctypes.c_int()
    rc = CGRect()
    for i in range(n):
        d = cf.CFArrayGetValueAtIndex(wlist, i)
        lref = cf.CFDictionaryGetValue(d, kCGWindowLayer)
        if not (lref and cf.CFNumberGetValue(lref, 3, ctypes.byref(layer))):
            continue
        lv = layer.value
        if lv == 24:
            owner = cfstr_to_py(cf.CFDictionaryGetValue(d, kCGWindowOwnerName))
            if owner in ("Window Server", "MenuBarAgent"):
                menubar_vis = True
                break
        elif lv == 25:
            owner = cfstr_to_py(cf.CFDictionaryGetValue(d, kCGWindowOwnerName))
            if owner == "MenuBarAgent":
                if first_mb25_z is None:
                    first_mb25_z = i
            elif owner == "sketchybar":
                bref = cf.CFDictionaryGetValue(d, kCGWindowBounds)
                if bref and cg.CGRectMakeWithDictionaryRepresentation(bref, ctypes.byref(rc)):
                    if rc.x > -5000.0 and rc.w > 10.0:
                        max_sb25_z = i
    cf.CFRelease(wlist)
    mb25_in_front = (
        not menubar_vis
        and first_mb25_z is not None
        and max_sb25_z is not None
        and first_mb25_z < max_sb25_z
    )
    return menubar_vis, mb25_in_front

def set_bar_hidden(hide):
    if hide:
        cmd = [SKETCHYBAR, "--bar", "hidden=on", "--set", "power", "popup.drawing=off"]
        try:
            os.remove("/tmp/sketchybar_hover/_power_open")
        except OSError:
            pass
        open_file = "/tmp/sketchybar_hover/_open"
        try:
            with open(open_file, "r") as f:
                open_item = f.read().strip()
            if open_item and open_item != "power":
                cmd.extend(["--set", open_item, "popup.drawing=off"])
            os.remove(open_file)
        except OSError:
            pass
    else:
        # --reorder forces SketchyBar to order its layer-25 windows above
        # MenuBarAgent's permanent layer-25 notch-band window on notched Macs.
        cmd = [SKETCHYBAR, "--bar", "hidden=off", "--reorder"]
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

displays, autohide, separate_spaces = discover_state()
last_discover = time.monotonic()
last_z_check = 0.0
last_unhide = time.monotonic()
last_reorder = 0.0
last_uuid_switch = 0.0
bar_hidden = False

time.sleep(0.25)

try:
    while True:
        now = time.monotonic()
        if now - last_discover > 15.0:
            try:
                with open(PID_FILE, "r") as f:
                    if f.read().strip() != MY_PID:
                        break
            except OSError:
                break
            release_displays(displays)
            displays, autohide, separate_spaces = discover_state()
            last_discover = now

        hov = hovered_top_display(displays)
        need_window_check = (
            bar_hidden
            or (hov is not None)
            or ((now - last_unhide) < 2.0)
            or ((now - last_z_check) >= 1.5)
        )

        if need_window_check:
            last_z_check = now
            vis, mb25_in_front = inspect_top_windows()

            if autohide and vis:
                if not bar_hidden:
                    set_bar_hidden(True)
                    bar_hidden = True
                time.sleep(0.06)
                continue

            if bar_hidden:
                set_bar_hidden(False)
                bar_hidden = False
                last_unhide = now
                last_reorder = now
            elif mb25_in_front and (now - last_reorder) >= 0.4:
                set_bar_hidden(False)
                last_reorder = now

            # Keep SketchyBar's active popup display synced to the hovered bar
            # when macOS "Displays have separate Spaces" is enabled.
            if separate_spaces and hov is not None and hov[3] and hov[4]:
                if (now - last_uuid_switch) >= 0.25:
                    if get_active_menubar_uuid() != hov[3]:
                        sl.SLSSetActiveMenuBarDisplayIdentifier(cid, hov[4], None)
                        last_uuid_switch = now

        if bar_hidden or hov is not None or (now - last_unhide) < 2.0:
            time.sleep(0.06)
        else:
            time.sleep(0.15)
finally:
    release_displays(displays)
PYEOF
