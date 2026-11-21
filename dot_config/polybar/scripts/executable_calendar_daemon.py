#!/usr/bin/env python3
"""Everforest Dark Hard hover calendar popup + bar refresher for Polybar.

Matches Sway Waybar and macOS SketchyBar calendar look and interactions:
  - Pure minimal calendar popup (no toolbar buttons)
  - Dynamically locates the clock module left of Polybar's system tray
  - Hover over the clock module: opens Month calendar right below the clock
  - Right-click clock or popup: toggles Month <-> 3-column Year calendar
  - Scroll on clock or popup: shifts month/year when visible, or cycles
    Local <-> Pacific (PST8PDT) timezone when closed
  - Left-click clock: toggles compact <-> full date format
  - Middle-click clock: cycles Local <-> Pacific (PST8PDT) timezone
  - Moving pointer off both clock and popup closes it and resets to today
"""

import calendar
import datetime
import html
import os
import re
import signal
import socket
import subprocess
import time

import gi

gi.require_version("Gdk", "3.0")
gi.require_version("Gtk", "3.0")
gi.require_version("Pango", "1.0")
from gi.repository import Gdk, GLib, Gtk, Pango

UID = os.getuid()
ALT_FILE = f"/tmp/polybar_clock_alt_{UID}"
TZ_FILE = f"/tmp/polybar_clock_tz_{UID}"
SOCK_PATH = f"/tmp/polybar_calendar_{UID}.sock"
CLOCK_SCRIPT = os.path.expanduser("~/.config/polybar/scripts/clock.sh")

TIMEZONES = ["", "PST8PDT"]
BAR_HEIGHT = 33
HOVER_IN_MS = 200
HOVER_OUT_MS = 200

POLYBAR_WIN_RE = re.compile(
    r'^\s*(0x[0-9a-fA-F]+)\s+"polybar-[^"]+":\s+\("polybar"\s+"Polybar"\)\s+(\d+)x(\d+)\+(-?\d+)\+(-?\d+)\s+\+(-?\d+)\+(-?\d+)'
)
CHILD_GEOM_RE = re.compile(
    r'^\s*0x[0-9a-fA-F]+\s+.*\s+(\d+)x(\d+)\+(-?\d+)\+(-?\d+)\s+\+(-?\d+)\+(-?\d+)'
)

# Everforest Dark Hard palette (matches Waybar tooltip & SketchyBar calendar)
CSS = b"""
window.calendar-popup {
  background-color: #2e383c;
  color: #d3c6aa;
  border: 1px solid #414b50;
  border-radius: 0px;
}

.cal-text {
  font-family: "Hack Nerd Font Mono";
  font-size: 12pt;
  color: #d3c6aa;
  padding: 10px 14px;
}
"""


def get_tz_idx() -> int:
    try:
        idx = int(open(TZ_FILE, encoding="utf-8").read().strip())
        if 0 <= idx < len(TIMEZONES):
            return idx
    except (OSError, ValueError):
        pass
    return 0


def now_for_tz(tz: str) -> datetime.datetime:
    prev = os.environ.get("TZ")
    try:
        if tz:
            os.environ["TZ"] = tz
        elif "TZ" in os.environ:
            del os.environ["TZ"]
        time.tzset()
        return datetime.datetime.now().astimezone()
    finally:
        if prev is None:
            os.environ.pop("TZ", None)
        else:
            os.environ["TZ"] = prev
        time.tzset()


def current_clock_plain_text() -> str:
    idx = get_tz_idx()
    tz = TIMEZONES[idx]
    dt = now_for_tz(tz)
    alt = os.path.exists(ALT_FILE)
    if tz:
        fmt = "%H:%M (%Z) · %a, %b %d, %Y" if alt else "%H:%M (%Z) · %b %d"
    else:
        fmt = "%H:%M (%Z) · %a, %b %d, %Y" if alt else "%H:%M · %b %d"
    return "X " + dt.strftime(fmt)


def span(text: str, color: str, bold: bool = False, underline: bool = False) -> str:
    esc = html.escape(text)
    if bold:
        esc = f"<b>{esc}</b>"
    if underline:
        esc = f"<u>{esc}</u>"
    return f"<span foreground='{color}'>{esc}</span>"


def build_month_lines(year: int, month: int, today: datetime.date, show_year: bool) -> list[str]:
    cal = calendar.Calendar(firstweekday=6)  # Sunday first (matches Waybar/SketchyBar)
    hdr = f"{datetime.date(year, month, 1):%B}" + (f" {year}" if show_year else "")
    lines = [
        span(hdr.center(20) + "    ", "#d3c6aa", bold=True),
        span("Su Mo Tu We Th Fr Sa    ", "#7fbbb3", bold=True),
    ]
    for week in cal.monthdatescalendar(year, month):
        parts = []
        for idx, day in enumerate(week):
            if idx:
                parts.append(" ")
            if day.month != month:
                parts.append("  ")
            elif day == today:
                parts.append(span(f"{day.day:2d}", "#dbbc7f", bold=True, underline=True))
            else:
                parts.append(span(f"{day.day:2d}", "#e67e80"))
        week_num = week[3].isocalendar()[1]
        parts.append(span(f" W{week_num:02d}", "#a7c080", bold=True))
        lines.append("".join(parts))
    return lines


def build_calendar_markup(mode: str, offset: int, tz: str) -> str:
    today = now_for_tz(tz).date()
    if mode == "year":
        year = today.year + offset
        out = [span(f"{year}".center(78), "#d3c6aa", bold=True), ""]
        for row in range(4):
            blocks = [build_month_lines(year, row * 3 + col + 1, today, False) for col in range(3)]
            height = max(len(b) for b in blocks)
            for line_idx in range(height):
                chunks = []
                for col, blk in enumerate(blocks):
                    if col:
                        chunks.append("   ")
                    chunks.append(blk[line_idx] if line_idx < len(blk) else " " * 24)
                out.append("".join(chunks))
            if row < 3:
                out.append("")
        return "\n".join(out)

    total_months = today.year * 12 + (today.month - 1) + offset
    year, month = divmod(total_months, 12)
    return "\n".join(build_month_lines(year, month + 1, today, True))


class CalendarDaemon:
    def __init__(self) -> None:
        self.mode = "month"
        self.offset = 0
        self.visible = False
        self.hover_in_since: float | None = None
        self.hover_out_since: float | None = None
        self.last_clock_key = ""
        self.last_net_tick = 0.0
        self._procs: list[subprocess.Popen] = []

        self.clock_font_desc = Pango.FontDescription.from_string("Hack Nerd Font Bold 12")
        self.cached_hitbox_key = ""
        self.cached_hitbox_width = 180
        self.cached_tray_ts = 0.0
        self.cached_tray_right_edge: dict[tuple[int, int, int], int] = {}

        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        # Override-redirect POPUP floats cleanly above i3 without stealing focus
        self.win = Gtk.Window(type=Gtk.WindowType.POPUP)
        self.win.get_style_context().add_class("calendar-popup")
        self.win.set_decorated(False)
        self.win.set_resizable(False)
        self.win.set_keep_above(True)
        self.win.add_events(
            Gdk.EventMask.BUTTON_PRESS_MASK
            | Gdk.EventMask.SCROLL_MASK
            | Gdk.EventMask.ENTER_NOTIFY_MASK
            | Gdk.EventMask.LEAVE_NOTIFY_MASK
        )
        self.win.connect("button-press-event", self._on_button_press)
        self.win.connect("scroll-event", self._on_scroll)

        self.label = Gtk.Label()
        self.label.set_xalign(0.0)
        self.label.set_yalign(0.0)
        self.label.get_style_context().add_class("cal-text")
        self.win.add(self.label)

        self._setup_socket()
        GLib.timeout_add(100, self._poll_hover)
        GLib.timeout_add(1000, self._tick_bar)

    def _spawn(self, argv: list[str]) -> None:
        self._reap()
        try:
            proc = subprocess.Popen(
                argv,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            self._procs.append(proc)
        except OSError:
            pass

    def _reap(self) -> None:
        if self._procs:
            self._procs = [p for p in self._procs if p.poll() is None]

    def _setup_socket(self) -> None:
        try:
            os.unlink(SOCK_PATH)
        except FileNotFoundError:
            pass
        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
        self.sock.bind(SOCK_PATH)
        self.sock.setblocking(False)
        GLib.io_add_watch(self.sock.fileno(), GLib.IO_IN, self._on_sock_cmd)

    def _on_sock_cmd(self, _fd, _cond) -> bool:
        try:
            cmd = self.sock.recv(256).decode("utf-8", errors="ignore").strip()
        except OSError:
            return True

        if cmd == "toggle-mode":
            if self.visible:
                self.toggle_mode()
            else:
                self.mode = "year"
                self.offset = 0
                self.show_popup()
        elif cmd == "scroll-up":
            if self.visible:
                self.shift(-1)
            else:
                self._spawn([CLOCK_SCRIPT, "tz-prev"])
        elif cmd == "scroll-down":
            if self.visible:
                self.shift(1)
            else:
                self._spawn([CLOCK_SCRIPT, "tz-next"])
        elif cmd in ("tz-changed", "refresh"):
            self.cached_hitbox_key = ""
            if self.visible:
                self._render()
                self._position_popup()
        return True

    def _clock_hitbox_width(self) -> int:
        key = f"{get_tz_idx()}_{int(os.path.exists(ALT_FILE))}"
        if key != self.cached_hitbox_key:
            text = current_clock_plain_text()
            layout = self.label.create_pango_layout(text)
            layout.set_font_description(self.clock_font_desc)
            px_w, _ = layout.get_pixel_size()
            self.cached_hitbox_width = px_w + 16
            self.cached_hitbox_key = key
        return self.cached_hitbox_width

    def _clock_right_edge(self, geom: Gdk.Rectangle) -> int:
        """Return X coordinate of the clock's right edge (immediately left of tray)."""
        key = (geom.x, geom.y, geom.width)
        now = time.monotonic()
        if (now - self.cached_tray_ts) < 2.0 and key in self.cached_tray_right_edge:
            return self.cached_tray_right_edge[key]

        fallback = geom.x + geom.width - 10
        edge = fallback
        try:
            root_out = subprocess.check_output(
                ["xwininfo", "-root", "-tree"],
                stderr=subprocess.DEVNULL,
                text=True,
                timeout=0.5,
            )
            bar_id = None
            for line in root_out.splitlines():
                m = POLYBAR_WIN_RE.match(line)
                if not m:
                    continue
                wid, _, _, _, _, abs_x, abs_y = m.groups()
                if abs(int(abs_x) - geom.x) <= 4 and abs(int(abs_y) - geom.y) <= 4:
                    bar_id = wid
                    break

            if bar_id:
                bar_out = subprocess.check_output(
                    ["xwininfo", "-id", bar_id, "-tree"],
                    stderr=subprocess.DEVNULL,
                    text=True,
                    timeout=0.5,
                )
                tray_xs: list[int] = []
                in_children = False
                child_indent = None
                for line in bar_out.splitlines():
                    if not in_children:
                        if " children:" in line or " child:" in line:
                            in_children = True
                        continue
                    stripped = line.lstrip(" ")
                    indent = len(line) - len(stripped)
                    if child_indent is None:
                        if stripped.startswith("0x"):
                            child_indent = indent
                        else:
                            continue
                    if indent == child_indent and stripped.startswith("0x"):
                        cm = CHILD_GEOM_RE.match(line)
                        if cm:
                            abs_x = int(cm.group(5))
                            if geom.x <= abs_x <= geom.x + geom.width:
                                tray_xs.append(abs_x)
                if tray_xs:
                    # Leave a small gap for the 2-space separator between clock and tray
                    edge = min(tray_xs) - 10
        except (OSError, subprocess.SubprocessError, ValueError):
            pass

        self.cached_tray_ts = now
        self.cached_tray_right_edge[key] = edge
        return edge

    def _pointer_pos(self) -> tuple[int, int, Gdk.Rectangle] | None:
        display = Gdk.Display.get_default()
        if not display:
            return None
        seat = display.get_default_seat()
        if not seat:
            return None
        pointer = seat.get_pointer()
        if not pointer:
            return None
        _, x, y = pointer.get_position()
        mon = display.get_monitor_at_point(x, y)
        if not mon:
            return None
        return x, y, mon.get_geometry()

    def _in_clock_region(self, x: int, y: int, geom: Gdk.Rectangle) -> bool:
        if not (geom.y <= y <= geom.y + BAR_HEIGHT):
            return False
        right_edge = self._clock_right_edge(geom)
        left_edge = right_edge - self._clock_hitbox_width()
        return left_edge <= x <= right_edge

    def _in_popup_region(self, x: int, y: int) -> bool:
        if not self.visible:
            return False
        px, py = self.win.get_position()
        pw, ph = self.win.get_size()
        return (px - 6) <= x <= (px + pw + 6) and (py - 10) <= y <= (py + ph + 6)

    def _poll_hover(self) -> bool:
        pos = self._pointer_pos()
        if pos is None:
            return True
        x, y, geom = pos
        now = time.monotonic() * 1000.0
        in_clock = self._in_clock_region(x, y, geom)
        in_popup = self._in_popup_region(x, y)

        if not self.visible:
            if in_clock:
                if self.hover_in_since is None:
                    self.hover_in_since = now
                elif (now - self.hover_in_since) >= HOVER_IN_MS:
                    self.hover_in_since = None
                    self.mode = "month"
                    self.offset = 0
                    self.show_popup(geom)
            else:
                self.hover_in_since = None
        else:
            if in_clock or in_popup:
                self.hover_out_since = None
            else:
                if self.hover_out_since is None:
                    self.hover_out_since = now
                elif (now - self.hover_out_since) >= HOVER_OUT_MS:
                    self.hide_popup()
        return True

    def _tick_bar(self) -> bool:
        self._reap()
        now = time.monotonic()
        idx = get_tz_idx()
        key = f"{datetime.datetime.now().strftime('%Y%m%d%H%M')}_{idx}_{int(os.path.exists(ALT_FILE))}"
        if key != self.last_clock_key:
            self.last_clock_key = key
            self._spawn(["polybar-msg", "action", "#clock.hook.0"])
        if (now - self.last_net_tick) >= 10.0:
            self.last_net_tick = now
            self._spawn(["polybar-msg", "action", "#network.hook.0"])
        return True

    def _render(self) -> None:
        tz = TIMEZONES[get_tz_idx()]
        self.label.set_markup(build_calendar_markup(self.mode, self.offset, tz))

    def _position_popup(self, geom: Gdk.Rectangle | None = None) -> None:
        if geom is None:
            pos = self._pointer_pos()
            if pos is not None:
                geom = pos[2]
        if geom is None:
            display = Gdk.Display.get_default()
            mon = display.get_primary_monitor() or display.get_monitor(0)
            geom = mon.get_geometry()
        self.win.resize(1, 1)
        _, nat = self.win.get_preferred_size()
        right_edge = self._clock_right_edge(geom)
        px = max(geom.x + 8, min(right_edge - nat.width, geom.x + geom.width - nat.width - 8))
        py = geom.y + BAR_HEIGHT + 4
        self.win.move(px, py)

    def show_popup(self, geom: Gdk.Rectangle | None = None) -> None:
        self._render()
        self.win.show_all()
        self._position_popup(geom)
        self.visible = True
        self.hover_out_since = None

    def hide_popup(self) -> None:
        self.win.hide()
        self.visible = False
        self.hover_in_since = None
        self.hover_out_since = None
        self.mode = "month"
        self.offset = 0

    def toggle_mode(self) -> None:
        self.mode = "month" if self.mode == "year" else "year"
        self.offset = 0
        self._render()
        self._position_popup()

    def shift(self, delta: int) -> None:
        self.offset += delta
        self._render()
        self._position_popup()

    def _on_button_press(self, _widget, event: Gdk.EventButton) -> bool:
        if event.button == 3:  # Right-click toggles Month <-> Year
            self.toggle_mode()
            return True
        if event.button == 2:  # Middle-click toggles Local <-> Pacific TZ
            self._spawn([CLOCK_SCRIPT, "tz-next"])
            return True
        return False

    def _on_scroll(self, _widget, event: Gdk.EventScroll) -> bool:
        if event.direction == Gdk.ScrollDirection.UP:
            self.shift(-1)
            return True
        if event.direction == Gdk.ScrollDirection.DOWN:
            self.shift(1)
            return True
        return False


def main() -> None:
    signal.signal(signal.SIGINT, lambda *_: Gtk.main_quit())
    signal.signal(signal.SIGTERM, lambda *_: Gtk.main_quit())
    CalendarDaemon()
    Gtk.main()


if __name__ == "__main__":
    main()
