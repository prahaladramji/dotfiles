#!/bin/zsh

source "$HOME/.config/sketchybar/colors.sh"

STATE_FILE="/tmp/sketchybar_clock_alt"
TZ_FILE="/tmp/sketchybar_clock_tz"
YEAR_FILE="/tmp/sketchybar_clock_year"
OFFSET_FILE="/tmp/sketchybar_clock_offset"
CAL_IMG="/tmp/sketchybar_clock_cal.png"
CAL_KEY_FILE="/tmp/sketchybar_clock_cal_key"

# Timezones matching Sway/Waybar config ("" = system local timezone, "PST8PDT")
TIMEZONES=("" "PST8PDT")
TZ_COUNT=${#TIMEZONES[@]}

get_tz_idx() {
  local idx
  idx=$(<"$TZ_FILE") 2>/dev/null || idx=1
  if ! [[ "$idx" =~ ^[0-9]+$ ]] || [ "$idx" -lt 1 ] || [ "$idx" -gt "$TZ_COUNT" ]; then
    idx=1
  fi
  print -r -- "$idx"
}

render_calendar() {
  local mode="${1:-month}"
  local offset="${2:-0}"
  local tz="${3:-}"

  /usr/bin/python3 - "$mode" "$offset" "$CAL_IMG" "$tz" << 'PYEOF'
import calendar, ctypes, ctypes.util, datetime, os, sys, time

mode, offset, out_path, tz = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4]
if tz:
  os.environ["TZ"] = tz
  time.tzset()
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

FONT_SIZE = 30.0
f_reg = ct.CTFontCreateWithName(cfstr("HackNFM-Regular"), FONT_SIZE, None)
f_bold = ct.CTFontCreateWithName(cfstr("HackNFM-Bold"), FONT_SIZE, None)
ch, gl = u16(ord("M")), u16(0)
ct.CTFontGetGlyphsForCharacters(f_reg, ctypes.byref(ch), ctypes.byref(gl), 1)
if ct.CTFontGetAdvancesForGlyphs(f_reg, 0, ctypes.byref(gl), None, 1) > FONT_SIZE * 0.875:
  f_reg = ct.CTFontCreateWithName(cfstr("Menlo-Regular"), FONT_SIZE, None)
  f_bold = ct.CTFontCreateWithName(cfstr("Menlo-Bold"), FONT_SIZE, None)
  ct.CTFontGetGlyphsForCharacters(f_reg, ctypes.byref(ch), ctypes.byref(gl), 1)

cw = ct.CTFontGetAdvancesForGlyphs(f_reg, 0, ctypes.byref(gl), None, 1)
asc, desc = ct.CTFontGetAscent(f_reg), ct.CTFontGetDescent(f_reg)
lh, px, py = round(asc + desc + 10.0), 28.0, 24.0
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
      cg.CGContextFillRect(ctx, Rect(px + (col + s) * cw, by - 4.0, (n - s) * cw, 3.0))
    col += n

url = cf.CFURLCreateFromFileSystemRepresentation(None, out_path.encode(), len(out_path), False)
dest = iio.CGImageDestinationCreateWithURL(url, cfstr("public.png"), 1, None)
iio.CGImageDestinationAddImage(dest, cg.CGBitmapContextCreateImage(ctx), None)
iio.CGImageDestinationFinalize(dest)
PYEOF

  sketchybar --set clock.cal background.image="$CAL_IMG"
}

TZ_IDX=$(get_tz_idx)
CURRENT_TZ="${TIMEZONES[$TZ_IDX]}"

if [ -z "$1" ]; then
  if [ "$SENDER" = "mouse.exited" ] || [ "$SENDER" = "mouse.exited.global" ]; then
    hover_exit clock
    if [ -f "$YEAR_FILE" ] || [ -f "$OFFSET_FILE" ]; then
      rm -f "$YEAR_FILE" "$OFFSET_FILE"
      render_calendar month 0 "$CURRENT_TZ" >/dev/null 2>&1 &
    fi
    exit 0
  fi

  if [ "$SENDER" = "mouse.entered" ]; then
    if [ ! -f "$CAL_IMG" ]; then
      render_calendar month 0 "$CURRENT_TZ"
    fi
    hover_enter clock
    exit 0
  fi

  if [ "$SENDER" = "mouse.scrolled" ]; then
    CURRENT_MODE="month"
    [ -f "$YEAR_FILE" ] && CURRENT_MODE="year"
    CURRENT_OFFSET=$(<"$OFFSET_FILE") 2>/dev/null || CURRENT_OFFSET=0
    DELTA="${SCROLL_DELTA:-0}"
    if [ "$DELTA" -gt 0 ]; then
      CURRENT_OFFSET=$((CURRENT_OFFSET - 1))
    elif [ "$DELTA" -lt 0 ]; then
      CURRENT_OFFSET=$((CURRENT_OFFSET + 1))
    fi
    print -r -- "$CURRENT_OFFSET" > "$OFFSET_FILE"
    render_calendar "$CURRENT_MODE" "$CURRENT_OFFSET" "$CURRENT_TZ"
    sketchybar --set clock popup.drawing=on
    exit 0
  fi
fi

if [ "$1" = "mode" ] || { [ "$SENDER" = "mouse.clicked" ] && [ "$BUTTON" = "right" ]; }; then
  rm -f "$OFFSET_FILE"
  if [ -f "$YEAR_FILE" ]; then
    rm -f "$YEAR_FILE"
    render_calendar month 0 "$CURRENT_TZ"
  else
    touch "$YEAR_FILE"
    render_calendar year 0 "$CURRENT_TZ"
  fi
  print -r -- "clock" > "$HOVER_DIR/_open" 2>/dev/null
  sketchybar --set clock popup.drawing=on
  exit 0
fi

if [ -n "$1" ] || [ "$SENDER" = "mouse.clicked" ]; then
  BUTTON_CODE=$(print -r -- "$INFO" | sed -n 's/.*"button_code":[[:space:]]*\([0-9]*\).*/\1/p')
  TZ_CHANGED=0

  if [ "$1" = "tz_up" ] || { [ "$SENDER" = "mouse.clicked" ] && { [ "$BUTTON_CODE" = "4" ] || [ "$BUTTON_CODE" = "2" ] || { [ "$BUTTON" = "left" ] && [ "$MODIFIER" = "shift" ]; }; }; }; then
    TZ_IDX=$(( (TZ_IDX % TZ_COUNT) + 1 ))
    print -r -- "$TZ_IDX" > "$TZ_FILE"
    CURRENT_TZ="${TIMEZONES[$TZ_IDX]}"
    TZ_CHANGED=1
  elif [ "$1" = "tz_down" ] || { [ "$SENDER" = "mouse.clicked" ] && [ "$BUTTON_CODE" = "3" ]; }; then
    TZ_IDX=$(( ((TZ_IDX - 2 + TZ_COUNT) % TZ_COUNT) + 1 ))
    print -r -- "$TZ_IDX" > "$TZ_FILE"
    CURRENT_TZ="${TIMEZONES[$TZ_IDX]}"
    TZ_CHANGED=1
  elif [ "$1" = "toggle" ] || { [ "$SENDER" = "mouse.clicked" ] && [ "$BUTTON" = "left" ]; }; then
    hover_cancel clock
    if [ -f "$STATE_FILE" ]; then
      rm -f "$STATE_FILE"
    else
      touch "$STATE_FILE"
    fi
  fi
fi

if [ -n "$CURRENT_TZ" ]; then
  TODAY_STR=$(TZ="$CURRENT_TZ" date '+%F')
  if [ -f "$STATE_FILE" ]; then
    LABEL=$(TZ="$CURRENT_TZ" date '+%H:%M (%Z) · %a, %b %d, %Y')
  else
    LABEL=$(TZ="$CURRENT_TZ" date '+%H:%M · %b %d')
  fi
else
  TODAY_STR=$(date '+%F')
  if [ -f "$STATE_FILE" ]; then
    LABEL=$(date '+%H:%M (%Z) · %a, %b %d, %Y')
  else
    LABEL=$(date '+%H:%M · %b %d')
  fi
fi

sketchybar --set clock label="$LABEL"

CAL_KEY="${TODAY_STR}_${CURRENT_TZ}"
PREV_KEY=$(<"$CAL_KEY_FILE") 2>/dev/null || PREV_KEY=""
if [ ! -f "$CAL_IMG" ] || [ "$PREV_KEY" != "$CAL_KEY" ] || [ "${TZ_CHANGED:-0}" -eq 1 ]; then
  CURRENT_MODE="month"
  [ -f "$YEAR_FILE" ] && CURRENT_MODE="year"
  CURRENT_OFFSET=$(<"$OFFSET_FILE") 2>/dev/null || CURRENT_OFFSET=0
  render_calendar "$CURRENT_MODE" "$CURRENT_OFFSET" "$CURRENT_TZ"
  print -r -- "$CAL_KEY" > "$CAL_KEY_FILE"
fi
