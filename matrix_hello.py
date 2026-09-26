#!/usr/bin/env python3
"""
matrix-hello: a Matrix-inspired "Hello, World".

    Wake up, Neo...
    The Matrix has you...
    Follow the white rabbit.
    Knock, knock, Neo.

...then digital rain, then HELLO, WORLD decoded out of the code.

Uses only the Python standard library (curses) on Linux and macOS. On
Windows, curses comes from the `windows-curses` package. Keys:
    any key   skip to the next scene (exits on the final scene)
    q / Esc   quit immediately
"""

import argparse
import locale
import math
import os
import random
import sys
import time

try:
    import curses
except ImportError:
    sys.exit("matrix-hello needs the curses module.\n"
             "On Windows, install it with:  py -m pip install windows-curses")

TITLE = "matrix-hello"

# Half-width katakana, like the film, plus digits and a few symbols.
KATAKANA = [chr(c) for c in range(0xFF66, 0xFF9E)]
GLYPHS_UNICODE = KATAKANA + list("0123456789012345:.=*+-<>|Z")
GLYPHS_ASCII = list("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%&*+=-<>?:")

RABBIT = [
    r"(\(\ ",
    r"( -.-)",
    r'o_(")(")',
]


class Skip(Exception):
    """A key was pressed: move on to the next scene."""


class Quit(Exception):
    """q or Esc was pressed: exit now."""


class Screen:
    def __init__(self, stdscr, args):
        self.s = stdscr
        self.fps = args.fps
        self.glyphs = GLYPHS_ASCII if args.ascii else GLYPHS_UNICODE
        self.cursor = "_" if args.ascii else "█"

        try:
            curses.curs_set(0)
        except curses.error:
            pass
        stdscr.nodelay(True)
        stdscr.keypad(True)

        if curses.has_colors():
            curses.start_color()
            black = curses.COLOR_BLACK
            if curses.COLORS >= 256:
                white, bright, mid, dark = 231, 46, 34, 22
            else:
                white, bright, mid, dark = (curses.COLOR_WHITE, curses.COLOR_GREEN,
                                            curses.COLOR_GREEN, curses.COLOR_GREEN)
            curses.init_pair(1, white, black)
            curses.init_pair(2, bright, black)
            curses.init_pair(3, mid, black)
            curses.init_pair(4, dark, black)
            self.WHITE = curses.color_pair(1) | curses.A_BOLD
            self.BRIGHT = curses.color_pair(2) | curses.A_BOLD
            self.GREEN = curses.color_pair(3)
            self.DARK = curses.color_pair(4) | (curses.A_DIM if curses.COLORS < 256 else 0)
            stdscr.bkgd(" ", curses.color_pair(3))
        else:
            self.WHITE = self.BRIGHT = curses.A_BOLD
            self.GREEN = curses.A_NORMAL
            self.DARK = curses.A_DIM
        self.clear()

    def size(self):
        return self.s.getmaxyx()

    def glyph(self):
        return random.choice(self.glyphs)

    def put(self, y, x, text, attr=0):
        h, w = self.size()
        if y < 0 or y >= h or x >= w:
            return
        if x < 0:
            text, x = text[-x:], 0
        text = text[: w - x]
        if not text:
            return
        try:
            self.s.addstr(y, x, text, attr)
        except curses.error:
            pass  # writing the bottom-right cell always "fails"; harmless

    def clear(self):
        self.s.erase()
        self.s.refresh()

    def refresh(self):
        self.s.refresh()

    def poll(self):
        ch = self.s.getch()
        if ch == curses.KEY_RESIZE and os.name == "nt":
            curses.resize_term(0, 0)  # PDCurses only picks up the new size when asked
        if ch in (-1, curses.KEY_RESIZE):
            return
        if ch in (ord("q"), ord("Q"), 27):
            raise Quit
        raise Skip

    def wait(self, seconds):
        end = time.monotonic() + seconds
        while True:
            self.poll()
            remaining = end - time.monotonic()
            if remaining <= 0:
                return
            time.sleep(min(0.02, remaining))

    def frame(self, started):
        """Finish an animation frame: refresh, check keys, hold the frame rate."""
        self.refresh()
        self.poll()
        time.sleep(max(0.0, 1.0 / self.fps - (time.monotonic() - started)))

    # --- terminal-style text -------------------------------------------

    def typewrite(self, y, x, text, attr):
        for i, ch in enumerate(text):
            self.put(y, x + i, ch + self.cursor, attr)
            self.refresh()
            delay = random.uniform(0.05, 0.13)
            if ch in ".,":
                delay += 0.22
            self.wait(delay)

    def blink(self, y, x, seconds, attr):
        end = time.monotonic() + seconds
        on = True
        while time.monotonic() < end:
            self.put(y, x, self.cursor if on else " ", attr)
            self.refresh()
            self.wait(min(0.5, max(0.0, end - time.monotonic())))
            on = not on
        self.put(y, x, " ", attr)


# ---------------------------------------------------------------------------
# Scene 1: the intro
# ---------------------------------------------------------------------------

def hop_rabbit(sc):
    h, w = sc.size()
    art_h, art_w = len(RABBIT), max(len(line) for line in RABBIT)
    jump = 3 if h >= 16 else 1
    bottom = h - 2
    top = bottom - art_h + 1
    if top - jump < 3:
        return  # terminal too small for a rabbit
    blank = " " * w

    x, t = -art_w, 0
    while x < w:
        started = time.monotonic()
        lift = int(round(math.sin(math.pi * (t % 10) / 10) * jump))
        for yy in range(top - jump, bottom + 1):
            sc.put(yy, 0, blank)
        for i, line in enumerate(RABBIT):
            sc.put(top - lift + i, x, line, sc.WHITE)
        sc.refresh()
        sc.poll()
        time.sleep(max(0.0, 0.04 - (time.monotonic() - started)))
        x += 1
        t += 1
    for yy in range(top - jump, bottom + 1):
        sc.put(yy, 0, blank)
    sc.refresh()


def intro(sc, name):
    y, x = 1, 2
    attr = sc.BRIGHT
    sc.clear()
    sc.blink(y, x, 2.0, attr)

    script = [
        (f"Wake up, {name}...", 3.0),
        ("The Matrix has you...", 3.0),
        ("Follow the white rabbit.", 1.0),
        (f"Knock, knock, {name}.", 2.5),
    ]
    for text, hold in script:
        sc.clear()
        sc.typewrite(y, x, text, attr)
        sc.blink(y, x + len(text), hold, attr)
        if "rabbit" in text:
            hop_rabbit(sc)
            sc.blink(y, x + len(text), 1.0, attr)
    sc.clear()


# ---------------------------------------------------------------------------
# Scene 2: digital rain
# ---------------------------------------------------------------------------

class Rain:
    def __init__(self, sc):
        self.sc = sc
        self.mask = None
        self.spawn_rate = 0.02
        self.resize()

    def resize(self):
        self.h, self.w = self.sc.size()
        self.attrs = [[None] * self.w for _ in range(self.h)]
        self.chars = [[" "] * self.w for _ in range(self.h)]
        # Each column holds a list of falling streams. Stagger the first wave
        # above the screen so the rain "arrives" rather than popping in.
        self.columns = [[] for _ in range(self.w)]
        for col in self.columns:
            if random.random() < 0.6:
                col.append(self._stream(-random.uniform(0, self.h)))
        self.sc.s.erase()

    def _stream(self, y=0.0):
        lo = max(4, self.h // 4)
        return {
            "y": y,
            "row": math.floor(y) - 1,
            "speed": random.uniform(0.3, 1.0),
            "len": random.randint(lo, max(lo + 2, self.h)),
        }

    def _masked(self, y, x):
        m = self.mask
        return m is not None and m[0] <= y < m[2] and m[1] <= x < m[3]

    def _draw(self, y, x, attr, new_glyph):
        if not (0 <= y < self.h) or self._masked(y, x):
            return
        if new_glyph:
            self.chars[y][x] = self.sc.glyph()
        elif self.attrs[y][x] is None:
            return
        self.attrs[y][x] = attr
        self.sc.put(y, x, self.chars[y][x], attr)

    def _erase(self, y, x):
        if not (0 <= y < self.h) or self._masked(y, x):
            return
        self.attrs[y][x] = None
        self.sc.put(y, x, " ")

    def set_mask(self, rect):
        """Keep the rain out of rect = (top, left, bottom, right)."""
        if rect == self.mask:
            return
        self.mask = rect
        if rect:
            for y in range(max(0, rect[0]), min(self.h, rect[2])):
                for x in range(max(0, rect[1]), min(self.w, rect[3])):
                    self.attrs[y][x] = None

    def step(self):
        if self.sc.size() != (self.h, self.w):
            self.resize()
        sc = self.sc
        for x, col in enumerate(self.columns):
            newest = col[-1] if col else None
            if newest is None or newest["row"] - newest["len"] > 2:
                if random.random() < self.spawn_rate:
                    col.append(self._stream())
            for s in col:
                s["y"] += s["speed"]
                while s["row"] < math.floor(s["y"]):
                    s["row"] += 1
                    r, n = s["row"], s["len"]
                    self._draw(r, x, sc.WHITE, True)                 # head
                    self._draw(r - 1, x, sc.BRIGHT, False)
                    self._draw(r - 3, x, sc.GREEN, False)
                    self._draw(r - int(n * 0.6), x, sc.DARK, False)
                    self._erase(r - n, x)                             # tail
            col[:] = [s for s in col if s["row"] - s["len"] < self.h]

        # Flicker: characters inside the streams keep mutating.
        for _ in range(max(1, self.w * self.h // 300)):
            y, x = random.randrange(self.h), random.randrange(self.w)
            if self.attrs[y][x] is not None:
                self._draw(y, x, self.attrs[y][x], True)


def rain_phase(sc, rain, seconds):
    end = time.monotonic() + seconds
    while time.monotonic() < end:
        started = time.monotonic()
        rain.step()
        sc.frame(started)


# ---------------------------------------------------------------------------
# Scene 3: HELLO, WORLD
# ---------------------------------------------------------------------------

def finale(sc, rain, message, name, timeout):
    sub = f"Welcome to the real world, {name}."
    hint = "[ press any key to exit the Matrix ]"
    # Frame at which each character of the message stops scrambling.
    locks = None
    start = time.monotonic()
    frame_no = 0

    while True:
        started = time.monotonic()
        if timeout and started - start > timeout:
            return
        rain.step()

        h, w = sc.size()
        title = " ".join(message) if len(message) * 2 + 8 < w else message
        inner_w = max(len(title), len(sub), len(hint)) + 6
        box_w, box_h = min(w, inner_w + 2), min(h, 9)
        top, left = max(0, (h - box_h) // 2), max(0, (w - box_w) // 2)
        rain.set_mask((top, left, top + box_h, left + box_w))

        if locks is None or len(locks) != len(title):
            locks = [i * 2 + random.randint(4, 18) for i in range(len(title))]
            frame_no = 0

        # Box and border
        for yy in range(top, top + box_h):
            sc.put(yy, left, " " * box_w)
        if box_w > 2 and box_h > 2:
            sc.put(top, left, "+" + "-" * (box_w - 2) + "+", sc.DARK)
            sc.put(top + box_h - 1, left, "+" + "-" * (box_w - 2) + "+", sc.DARK)
            for yy in range(top + 1, top + box_h - 1):
                sc.put(yy, left, "|", sc.DARK)
                sc.put(yy, left + box_w - 1, "|", sc.DARK)

        # Title, decoding out of the rain
        cx = left + (box_w - len(title)) // 2
        ty = top + 2
        for i, ch in enumerate(title):
            if ch == " ":
                continue
            if frame_no >= locks[i]:
                sc.put(ty, cx + i, ch, sc.WHITE)
            else:
                sc.put(ty, cx + i, sc.glyph(), sc.BRIGHT)

        done_at = max(locks) + 10
        if frame_no > done_at:
            shown = sub[: (frame_no - done_at) // 2]
            sc.put(ty + 2, left + (box_w - len(sub)) // 2, shown, sc.GREEN)
        hint_at = done_at + len(sub) * 2 + sc.fps
        if frame_no > hint_at and (frame_no // (sc.fps // 2 or 1)) % 2 == 0:
            sc.put(ty + 4, left + (box_w - len(hint)) // 2, hint, sc.DARK)

        frame_no += 1
        sc.frame(started)


# ---------------------------------------------------------------------------

def run(stdscr, args):
    sc = Screen(stdscr, args)
    try:
        if args.splash:
            try:
                rain_phase(sc, Rain(sc), args.splash)
            except Skip:
                pass
            return
        if not args.no_intro:
            try:
                intro(sc, args.name)
            except Skip:
                pass
        rain = Rain(sc)
        try:
            rain_phase(sc, rain, args.rain_seconds)
        except Skip:
            pass
        try:
            finale(sc, rain, args.message.upper(), args.name, args.timeout)
        except Skip:
            pass
    except Quit:
        pass


def main():
    p = argparse.ArgumentParser(description="A Matrix-inspired Hello, World.")
    p.add_argument("--name", default=os.environ.get("MATRIX_HELLO_NAME", "Neo"),
                   help="who to wake up (default: Neo, or $MATRIX_HELLO_NAME)")
    p.add_argument("--message", default="Hello, World.", help="the decoded message")
    p.add_argument("--rain-seconds", type=float, default=6.0,
                   help="seconds of rain before the message appears (default: 6)")
    p.add_argument("--timeout", type=float, default=60.0,
                   help="auto-exit this many seconds after the message appears; 0 waits forever")
    p.add_argument("--fps", type=int, default=24, help="frames per second (default: 24)")
    p.add_argument("--no-intro", action="store_true", help="skip the 'Wake up, Neo' intro")
    p.add_argument("--splash", type=float, metavar="SECONDS",
                   help="only show the rain for SECONDS, then exit (used by matrix-terminal)")
    p.add_argument("--ascii", action="store_true",
                   help="ASCII glyphs only, for fonts without katakana")
    args = p.parse_args()
    args.fps = max(5, min(args.fps, 60))

    locale.setlocale(locale.LC_ALL, "")
    os.environ.setdefault("ESCDELAY", "25")

    # Set the window title so window managers (i3, sway) can find the window.
    if os.name == "nt":
        # windows-curses draws Unicode through the console API whatever the
        # code page is, so there's no need to fall back to ASCII here.
        import ctypes
        ctypes.windll.kernel32.SetConsoleTitleW(TITLE)
    else:
        if not args.ascii and "UTF-8" not in (locale.getpreferredencoding(False) or "").upper():
            args.ascii = True
        if sys.stdout.isatty():
            sys.stdout.write(f"\033]0;{TITLE}\007")
            sys.stdout.flush()

    try:
        curses.wrapper(run, args)
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
