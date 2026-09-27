"""
Sound effects for matrix-hello, synthesized on the fly (no audio files).

A tiny software mixer runs in a background thread and streams 16-bit mono
audio to the OS:
    Linux    pacat (PulseAudio / PipeWire) or aplay (ALSA)
    Windows  the waveOut API, through ctypes
If none of those is available, everything stays silent.

For testing, MATRIX_HELLO_SOUND_FILE=out.wav records to a file instead.
"""

import array
import math
import os
import random
import shutil
import subprocess
import threading
import time
import wave

RATE = 22050
CHUNK = 512       # samples per mixing step (~23 ms)
AHEAD = 0.12      # seconds of audio to keep queued ahead of real time
FADE = 1.5        # seconds for the rain ambience to fade in or out

# A major pentatonic, for the notes that ring as HELLO, WORLD decodes.
PENTATONIC = [880.0, 987.8, 1108.7, 1318.5, 1480.0,
              1760.0, 1975.5, 2217.5, 2637.0, 2960.0]


# ---------------------------------------------------------------------------
# Synthesis
# ---------------------------------------------------------------------------

def _blip(freq, dur, tau, amp, sweep_to=None, noise=0.0):
    """A decaying sine, optionally sweeping in pitch, with an optional noise click."""
    n = int(dur * RATE)
    out = [0.0] * n
    phase = 0.0
    for i in range(n):
        t = i / RATE
        f = freq if sweep_to is None else freq + (sweep_to - freq) * i / n
        phase += 2 * math.pi * f / RATE
        s = math.sin(phase) * (1 - noise)
        if noise:
            s += random.uniform(-1, 1) * noise * math.exp(-t / 0.004)
        out[i] = amp * math.exp(-t / tau) * s
    for i in range(min(n, 44)):  # 2 ms fade-in, so it doesn't pop
        out[i] *= i / 44
    return out


def _ping(freq):
    """A bell-ish note: fundamental plus two overtones."""
    n = int(0.3 * RATE)
    return [0.14 * math.exp(-i / RATE / 0.07) *
            (math.sin(2 * math.pi * freq * i / RATE)
             + 0.4 * math.sin(4 * math.pi * freq * i / RATE)
             + 0.2 * math.sin(6 * math.pi * freq * i / RATE)) * min(1.0, i / 44)
            for i in range(n)]


def _whoosh(dur):
    """Noise through a low-pass filter that opens and closes: the rain arriving."""
    n = int(dur * RATE)
    out = [0.0] * n
    y = 0.0
    for i in range(n):
        x = i / n
        a = 0.02 + 0.35 * math.sin(math.pi * x) ** 2
        y += a * (random.uniform(-1, 1) - y)
        out[i] = 0.45 * math.sin(math.pi * x) ** 2 * y
    return out


def _rain_loop(seconds=6.0):
    """The ambience under the digital rain; loops seamlessly."""
    n = int(seconds * RATE)
    out = [0.0] * n
    # A low drone. Every frequency fits a whole number of cycles into the
    # loop, so there's no click where it wraps around.
    for i in range(n):
        t = i / RATE
        swell = 0.6 + 0.4 * math.sin(2 * math.pi * 0.5 * t)
        out[i] = 0.05 * swell * (math.sin(2 * math.pi * 55 * t)
                                 + 0.6 * math.sin(2 * math.pi * 82.5 * t))
    # A soft hiss. The filter runs around the loop twice so the seam is smooth.
    noise = [random.uniform(-1, 1) for _ in range(n)]
    y = 0.0
    for pass_no in range(2):
        for i in range(n):
            y += 0.08 * (noise[i] - y)
            if pass_no:
                out[i] += 0.12 * y
    # Digital droplets: short high chimes at random, wrapping around the end.
    notes = [1760, 2093, 2349, 2637, 3136, 3520, 4186]
    for _ in range(int(seconds * 40)):
        start = random.randrange(n)
        grain = _blip(random.choice(notes) * random.uniform(0.99, 1.01),
                      random.uniform(0.03, 0.08), 0.012, random.uniform(0.03, 0.09))
        for j, s in enumerate(grain):
            out[(start + j) % n] += s
    return out


def _effects():
    return {
        # Terminal typing: short digital ticks, slightly different each time.
        "key": [_blip(random.uniform(1500, 2300), 0.035, 0.007, 0.30, noise=0.35)
                for _ in range(6)],
        "knock": [_blip(170, 0.14, 0.03, 0.9, sweep_to=90, noise=0.5)],
        "hop": [_blip(320, 0.09, 0.04, 0.16, sweep_to=640)],
        "whoosh": [_whoosh(1.3)],
        "boom": [_blip(110, 1.3, 0.35, 0.7, sweep_to=35, noise=0.3)],
        "ping": [_ping(f) for f in PENTATONIC],
    }


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

class _PipeSink:
    """Raw PCM into a player's stdin (pacat, aplay)."""

    def __init__(self, argv):
        self.p = subprocess.Popen(argv, stdin=subprocess.PIPE,
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(0.1)
        if self.p.poll() is not None:  # e.g. pacat with no sound server running
            raise OSError(f"{argv[0]} exited")

    def write(self, data):
        self.p.stdin.write(data)
        self.p.stdin.flush()

    def close(self):
        try:
            self.p.stdin.close()
            self.p.wait(timeout=1)
        except Exception:
            self.p.kill()


class _WaveOutSink:
    """Windows' built-in waveOut API: a ring of buffers handed to the driver."""

    BUFFERS = 4

    def __init__(self):
        import ctypes
        from ctypes import wintypes

        class WAVEFORMATEX(ctypes.Structure):
            _fields_ = [("wFormatTag", wintypes.WORD), ("nChannels", wintypes.WORD),
                        ("nSamplesPerSec", wintypes.DWORD), ("nAvgBytesPerSec", wintypes.DWORD),
                        ("nBlockAlign", wintypes.WORD), ("wBitsPerSample", wintypes.WORD),
                        ("cbSize", wintypes.WORD)]

        class WAVEHDR(ctypes.Structure):
            _fields_ = [("lpData", ctypes.c_void_p), ("dwBufferLength", wintypes.DWORD),
                        ("dwBytesRecorded", wintypes.DWORD), ("dwUser", ctypes.c_size_t),
                        ("dwFlags", wintypes.DWORD), ("dwLoops", wintypes.DWORD),
                        ("lpNext", ctypes.c_void_p), ("reserved", ctypes.c_size_t)]

        self.ct = ctypes
        self.winmm = ctypes.WinDLL("winmm")
        fmt = WAVEFORMATEX(1, 1, RATE, RATE * 2, 2, 16, 0)  # PCM, mono, 16-bit
        self.handle = ctypes.c_void_p()
        wave_mapper = ctypes.c_uint(0xFFFFFFFF)  # the default output device
        rc = self.winmm.waveOutOpen(ctypes.byref(self.handle), wave_mapper, ctypes.byref(fmt),
                                    ctypes.c_size_t(0), ctypes.c_size_t(0), wintypes.DWORD(0))
        if rc:
            raise OSError(f"waveOutOpen failed ({rc})")
        size = CHUNK * 2
        self.bufs = [ctypes.create_string_buffer(size) for _ in range(self.BUFFERS)]
        self.hdrs = [WAVEHDR() for _ in range(self.BUFFERS)]
        for buf, hdr in zip(self.bufs, self.hdrs):
            hdr.lpData = ctypes.addressof(buf)
            hdr.dwBufferLength = size
            self.winmm.waveOutPrepareHeader(self.handle, ctypes.byref(hdr), ctypes.sizeof(hdr))
        self.queued = [False] * self.BUFFERS
        self.next = 0

    def write(self, data):
        i, hdr = self.next, self.hdrs[self.next]
        while self.queued[i] and not hdr.dwFlags & 1:  # WHDR_DONE
            time.sleep(0.004)
        self.ct.memmove(self.bufs[i], data, len(data))
        self.winmm.waveOutWrite(self.handle, self.ct.byref(hdr), self.ct.sizeof(hdr))
        self.queued[i] = True
        self.next = (i + 1) % self.BUFFERS

    def close(self):
        self.winmm.waveOutReset(self.handle)
        for hdr in self.hdrs:
            self.winmm.waveOutUnprepareHeader(self.handle, self.ct.byref(hdr), self.ct.sizeof(hdr))
        self.winmm.waveOutClose(self.handle)


class _WavFileSink:
    def __init__(self, path):
        self.w = wave.open(path, "wb")
        self.w.setnchannels(1)
        self.w.setsampwidth(2)
        self.w.setframerate(RATE)

    def write(self, data):
        self.w.writeframes(data)

    def close(self):
        self.w.close()


def _open_sink():
    path = os.environ.get("MATRIX_HELLO_SOUND_FILE")
    if path:
        return _WavFileSink(path)
    if os.name == "nt":
        return _WaveOutSink()
    players = [
        ["pacat", "--playback", "--raw", "--format=s16le", f"--rate={RATE}", "--channels=1",
         "--latency-msec=60", "--client-name=matrix-hello"],
        ["aplay", "-q", "-t", "raw", "-f", "S16_LE", "-r", str(RATE), "-c", "1",
         "--buffer-time=100000", "-"],
    ]
    for argv in players:
        if shutil.which(argv[0]):
            try:
                return _PipeSink(argv)
            except OSError:
                continue
    return None


# ---------------------------------------------------------------------------
# Mixer
# ---------------------------------------------------------------------------

class Sound:
    """play() one-shot effects and set ambient() on or off; all calls are cheap
    and safe to make even when there's no audio device."""

    def __init__(self, volume=0.6, muted=False):
        self.volume = max(0.0, min(volume, 1.0))
        self.muted = muted
        self._fx = {}
        self._rain = None
        self._voices = []          # [samples, position, gain]
        self._lock = threading.Lock()
        self._amb = 0.0
        self._amb_target = 0.0
        self._stop_at = None
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()
        # The rain ambience takes a moment to synthesize; don't hold up the rest.
        threading.Thread(target=self._make_rain, daemon=True).start()

    def play(self, name, index=None, delay=0.0, gain=1.0):
        variants = self._fx.get(name)
        if self.muted or not variants:
            return
        samples = variants[index % len(variants)] if index is not None else random.choice(variants)
        with self._lock:
            self._voices.append([samples, -int(delay * RATE), gain])

    def ambient(self, level):
        """Fade the rain ambience towards level (0 = off, 1 = full)."""
        self._amb_target = level

    def toggle_mute(self):
        self.muted = not self.muted

    def close(self, linger=0.4):
        """Fade out, let the last sounds ring for up to `linger` seconds, stop."""
        self._amb_target = 0.0
        self._stop_at = time.monotonic() + linger
        self._thread.join(timeout=linger + 1.0)

    def _make_rain(self):
        self._rain = _rain_loop()

    def _run(self):
        self._fx = _effects()
        try:
            sink = _open_sink()
        except Exception:
            sink = None
        if sink is None:
            self._fx = {}  # nothing to play on: make play() a no-op
            return
        rain_pos, written, start = 0, 0, time.monotonic()
        step = CHUNK / RATE / FADE
        try:
            while self._stop_at is None or time.monotonic() < self._stop_at:
                ahead = written / RATE - (time.monotonic() - start)
                if ahead > AHEAD:
                    time.sleep(ahead - AHEAD)
                    continue

                mix = [0.0] * CHUNK
                with self._lock:
                    voices = list(self._voices)
                keep = []
                for v in voices:
                    samples, pos, gain = v
                    first = max(0, -pos)   # where in this chunk the voice starts
                    offset = max(0, pos)   # how far into the sound we are
                    for k in range(min(CHUNK - first, len(samples) - offset)):
                        mix[first + k] += samples[offset + k] * gain
                    v[1] = pos + CHUNK
                    if v[1] < len(samples):
                        keep.append(v)
                with self._lock:
                    self._voices = keep + self._voices[len(voices):]

                if self._amb < self._amb_target:
                    self._amb = min(self._amb_target, self._amb + step)
                elif self._amb > self._amb_target:
                    self._amb = max(self._amb_target, self._amb - step * 3)
                rain = self._rain
                if rain and self._amb > 0:
                    n, g = len(rain), self._amb
                    for k in range(CHUNK):
                        mix[k] += rain[(rain_pos + k) % n] * g
                    rain_pos = (rain_pos + CHUNK) % n

                vol = 0.0 if self.muted else self.volume * 32767
                sink.write(array.array("h", [int(max(-32767.0, min(32767.0, x * vol)))
                                             for x in mix]).tobytes())
                written += CHUNK
        except Exception:
            pass  # the player went away (unplugged, killed): carry on silently
        finally:
            try:
                sink.close()
            except Exception:
                pass
