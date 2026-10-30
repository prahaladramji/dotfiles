#!/bin/zsh

source "$HOME/.config/sketchybar/colors.sh"

STATE_FILE="/tmp/sketchybar_clock_alt"
YEAR_FILE="/tmp/sketchybar_clock_year"
OFFSET_FILE="/tmp/sketchybar_clock_offset"
CAL_IMG="/tmp/sketchybar_clock_cal.png"

if [ "$SENDER" = "mouse.exited" ]; then
  rm -f "$YEAR_FILE" "$OFFSET_FILE"
  sketchybar --set clock popup.drawing=off
  exit 0
fi

render_calendar() {
  local mode="${1:-month}"
  local offset="${2:-0}"

  /usr/bin/python3 - "$mode" "$offset" "$CAL_IMG" << 'PYEOF'
import calendar, ctypes, ctypes.util, datetime, sys

mode, offset, out_path = sys.argv[1], int(sys.argv[2]), sys.argv[3]
vp, u16, sz, dbl, u32, b = ctypes.c_void_p, ctypes.c_uint16, ctypes.c_size_t, ctypes.c_double, ctypes.c_uint32, ctypes.c_bool

class Pt(ctypes.Structure): _fields_ = [("x", dbl), ("y", dbl)]
class Rect(ctypes.Structure): _fields_ = [("x", dbl), ("y", dbl), ("w", dbl), ("h", dbl)]

def load(name, sigs):
  lib = ctypes.cdll.LoadLibrary(ctypes.util.find_library(name))
  for fn, res, args in sigs:
    f = getattr(lib, fn)
    f.restype, f.argtypes = res, args
  return lib

cf = load("CoreFoundation", [
  ("CFStringCreateWithCString", vp, [vp, ctypes.c_char_p, u32]),
  ("CFURLCreateFromFileSystemRepresentation", vp, [vp, ctypes.c_char_p, ctypes.c_long, b]),
])
ct = load("CoreText", [
  ("CTFontCreateWithName", vp, [vp, dbl, vp]),
  ("CTFontGetAscent", dbl, [vp]),
  ("CTFontGetDescent", dbl, [vp]),
  ("CTFontGetGlyphsForCharacters", b, [vp, ctypes.POINTER(u16), ctypes.POINTER(u16), ctypes.c_long]),
  ("CTFontGetAdvancesForGlyphs", dbl, [vp, u32, ctypes.POINTER(u16), vp, ctypes.c_long]),
  ("CTFontDrawGlyphs", None, [vp, ctypes.POINTER(u16), ctypes.POINTER(Pt), sz, vp]),
])
cg = load("CoreGraphics", [
  ("CGColorSpaceCreateDeviceRGB", vp, []),
  ("CGBitmapContextCreate", vp, [vp, sz, sz, sz, sz, vp, u32]),
  ("CGBitmapContextCreateImage", vp, [vp]),
  ("CGContextSetRGBFillColor", None, [vp, dbl, dbl, dbl, dbl]),
  ("CGContextFillRect", None, [vp, Rect]),
  ("CGContextSetShouldSmoothFonts", None, [vp, b]),
  ("CGContextSetAllowsFontSmoothing", None, [vp, b]),
])
iio = load("ImageIO", [
  ("CGImageDestinationCreateWithURL", vp, [vp, vp, sz, vp]),
  ("CGImageDestinationAddImage", None, [vp, vp, vp]),
  ("CGImageDestinationFinalize", b, [vp]),
])

cfstr = lambda s: cf.CFStringCreateWithCString(None, s.encode(), 0x08000100)
COLORS = {
  "months":   (0xd3/255, 0xc6/255, 0xaa/255, 1.0), # #d3c6aa bold
  "weekdays": (0x7f/255, 0xbb/255, 0xb3/255, 1.0), # #7fbbb3 bold
  "days":     (0xe6/255, 0x7e/255, 0x80/255, 1.0), # #e67e80 regular
  "weeks":    (0xa7/255, 0xc0/255, 0x80/255, 1.0), # #a7c080 bold
  "today":    (0xdb/255, 0xbc/255, 0x7f/255, 1.0), # #dbbc7f bold + underline
}

cal, today = calendar.Calendar(6), datetime.date.today()

def month_block(y, m, show_year):
  hdr = f"{datetime.date(y, m, 1):%B}" + (f" {y}" if show_year else "")
  rows = [[(hdr.center(20) + "    ", "months")], [("Su Mo Tu We Th Fr Sa    ", "weekdays")]]
  for w in cal.monthdatescalendar(y, m):
    runs = []
    for i, d in enumerate(w):
      if i: runs.append((" ", "days"))
      runs.append(("  ", "days") if d.month != m else (f"{d.day:2d}", "today" if d == today else "days"))
    rows.append(runs + [(f" W{w[3].isocalendar()[1]:02d}", "weeks")])
  return rows

if mode == "year":
  y = today.year + offset
  grid = [[(f"{y}".center(78), "months")], [(" " * 78, "days")]]
  for r in range(4):
    blks = [month_block(y, r * 3 + c + 1, False) for c in range(3)]
    h = max(len(b) for b in blks)
    for line in range(h):
      row = []
      for c, blk in enumerate(blks):
        if c: row.append(("   ", "days"))
        row.extend(blk[line] if line < len(blk) else [(" " * 24, "days")])
      grid.append(row)
    if r < 3: grid.append([(" " * 78, "days")])
else:
  tm = today.year * 12 + today.month - 1 + offset
  grid = month_block(tm // 12, tm % 12 + 1, True)

f_reg = ct.CTFontCreateWithName(cfstr("HackNFM-Regular"), 24.0, None)
f_bold = ct.CTFontCreateWithName(cfstr("HackNFM-Bold"), 24.0, None)
ch, gl = u16(ord("M")), u16(0)
ct.CTFontGetGlyphsForCharacters(f_reg, ctypes.byref(ch), ctypes.byref(gl), 1)
if ct.CTFontGetAdvancesForGlyphs(f_reg, 0, ctypes.byref(gl), None, 1) > 21.0:
  f_reg = ct.CTFontCreateWithName(cfstr("Menlo-Regular"), 24.0, None)
  f_bold = ct.CTFontCreateWithName(cfstr("Menlo-Bold"), 24.0, None)
  ct.CTFontGetGlyphsForCharacters(f_reg, ctypes.byref(ch), ctypes.byref(gl), 1)

cw = ct.CTFontGetAdvancesForGlyphs(f_reg, 0, ctypes.byref(gl), None, 1)
asc, desc = ct.CTFontGetAscent(f_reg), ct.CTFontGetDescent(f_reg)
lh, px, py = round(asc + desc + 8.0), 24.0, 20.0
W = int(round(sum(len(t) for t, _ in grid[0]) * cw + 2 * px))
H = int(round(len(grid) * lh + 2 * py))

ctx = cg.CGBitmapContextCreate(None, W, H, 8, W * 4, cg.CGColorSpaceCreateDeviceRGB(), 1)
cg.CGContextSetAllowsFontSmoothing(ctx, True)
cg.CGContextSetShouldSmoothFonts(ctx, True)

for r_idx, row in enumerate(grid):
  by, col = H - py - r_idx * lh - asc, 0
  for text, style in row:
    n = len(text)
    cg.CGContextSetRGBFillColor(ctx, *COLORS[style])
    font = f_reg if style == "days" else f_bold
    chars, glyphs = (u16 * n)(*map(ord, text)), (u16 * n)()
    ct.CTFontGetGlyphsForCharacters(font, chars, glyphs, n)
    pts = (Pt * n)(*[Pt(px + (col + i) * cw, by) for i in range(n)])
    ct.CTFontDrawGlyphs(font, glyphs, pts, n, ctx)
    if style == "today":
      s = 1 if text[0] == " " else 0
      cg.CGContextFillRect(ctx, Rect(px + (col + s) * cw, by - 3.0, (n - s) * cw, 2.5))
    col += n

url = cf.CFURLCreateFromFileSystemRepresentation(None, out_path.encode(), len(out_path), False)
dest = iio.CGImageDestinationCreateWithURL(url, cfstr("public.png"), 1, None)
iio.CGImageDestinationAddImage(dest, cg.CGBitmapContextCreateImage(ctx), None)
iio.CGImageDestinationFinalize(dest)
PYEOF

  sketchybar --set clock.cal background.image="$CAL_IMG"
}

if [ "$1" = "mode" ] || { [ "$SENDER" = "mouse.clicked" ] && [ "$BUTTON" = "right" ]; }; then
  rm -f "$OFFSET_FILE"
  if [ -f "$YEAR_FILE" ]; then
    rm -f "$YEAR_FILE"
    render_calendar month 0
  else
    touch "$YEAR_FILE"
    render_calendar year 0
  fi
  sketchybar --set clock popup.drawing=on
  exit 0
fi

if [ "$1" = "toggle" ] || { [ "$SENDER" = "mouse.clicked" ] && [ "$BUTTON" = "left" ]; }; then
  if [ -f "$STATE_FILE" ]; then
    rm -f "$STATE_FILE"
  else
    touch "$STATE_FILE"
  fi
fi

if [ -f "$STATE_FILE" ]; then
  LABEL=$(date '+%H:%M (%Z) · %a, %b %d, %Y')
else
  LABEL=$(date '+%H:%M · %b %d')
fi

sketchybar --set clock label="$LABEL"

if [ "$SENDER" = "mouse.entered" ]; then
  rm -f "$YEAR_FILE" "$OFFSET_FILE"
  render_calendar month 0
  sketchybar --set clock popup.drawing=on
elif [ "$SENDER" = "mouse.scrolled" ]; then
  CURRENT_MODE="month"
  [ -f "$YEAR_FILE" ] && CURRENT_MODE="year"
  CURRENT_OFFSET=$(cat "$OFFSET_FILE" 2>/dev/null || echo 0)
  DELTA="${SCROLL_DELTA:-0}"
  if [ "$DELTA" -gt 0 ]; then
    CURRENT_OFFSET=$((CURRENT_OFFSET - 1))
  elif [ "$DELTA" -lt 0 ]; then
    CURRENT_OFFSET=$((CURRENT_OFFSET + 1))
  fi
  echo "$CURRENT_OFFSET" > "$OFFSET_FILE"
  render_calendar "$CURRENT_MODE" "$CURRENT_OFFSET"
  sketchybar --set clock popup.drawing=on
fi
