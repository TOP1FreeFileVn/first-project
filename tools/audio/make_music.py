"""Build the game's background music: a chill lo-fi lobby loop and a gentle adventure battle loop.

Same key (E major) and wooden voices as the gear sounds from make_gear_sfx.py, so music
and effects sit together. Melodies and chords are written out by hand (no randomness).
Each loop is rendered into a fixed-length buffer and every tail wraps to the start, so
the loop point is seamless.

  lobby.wav         76 BPM: Rhodes chords (IVmaj7 - iii7 - ii7 - V7), kalimba tune, brushes.
  battle.wav        108 BPM, C# minor: plucked strings, low string pad, marimba, gear ticks
                    (shop break). Deliberately unlike the lobby.
  battle_drive.wav  108 BPM: soft toms, running bass, brush and shaker; same length as
                    battle.wav, MusicLib fades it in while a wave is fighting.

A downloaded track (.ogg) with the same name in game/audio/music replaces these.
No recordings or third-party audio are used.
"""

from __future__ import annotations

import json
import math
from pathlib import Path
import random

from make_gear_sfx import RATE, mallet, soften, write_wav

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "game" / "audio" / "music"
SWING = 0.08  # off-beat eighths land a little late: the lazy lo-fi feel

def hz(midi: float) -> float:
    return 440.0 * 2 ** ((midi - 69) / 12)

class Loop:
    def __init__(self, bpm: float, bars: int) -> None:
        self.beat = 60.0 / bpm
        self.buf = [0.0] * round(bars * 4 * self.beat * RATE)

    def add(self, sound: list[float], beat: float) -> None:
        if beat % 1.0 == 0.5:
            beat += SWING
        start = round(beat * self.beat * RATE)
        n = len(self.buf)
        for i, value in enumerate(sound):
            self.buf[(start + i) % n] += value

# --- Voices -----------------------------------------------------------------------------

def rhodes(freq: float, length: float, volume: float) -> list[float]:
    """Electric piano: a two-operator FM tone whose brightness fades, plus a soft tine."""
    out = []
    for i in range(round(length * RATE)):
        t = i / RATE
        env = (1 - math.exp(-t / 0.004)) * math.exp(-t / 1.1) * min(1.0, (length - t) / 0.05)
        index = 1.1 * math.exp(-t / 0.35)
        v = math.sin(2 * math.pi * freq * t + index * math.sin(2 * math.pi * freq * t))
        v += 0.12 * math.sin(2 * math.pi * freq * 7 * t) * math.exp(-t / 0.05)
        out.append(volume * env * v)
    return out

def chord(notes: list[int], length: float, volume: float) -> list[float]:
    out = [0.0] * round(length * RATE)
    for k, note in enumerate(notes):
        # A tiny strum, low to high.
        offset = round(0.012 * k * RATE)
        for i, v in enumerate(rhodes(hz(note), length - 0.012 * k, volume)):
            out[offset + i] += v
    return out

def kalimba(note: int, length: float, volume: float) -> list[float]:
    return mallet(hz(note), length, volume, 0.32, 0.003, 0.1)

def bass(freq: float, length: float, volume: float) -> list[float]:
    out = []
    for i in range(round(length * RATE)):
        t = i / RATE
        env = (1 - math.exp(-t / 0.01)) * math.exp(-t / (length * 0.7)) * min(1.0, (length - t) / 0.03)
        out.append(volume * env * (math.sin(2 * math.pi * freq * t) + 0.2 * math.sin(4 * math.pi * freq * t)))
    return out

def noise_hit(length: float, volume: float, seed: int, bright: bool) -> list[float]:
    """Shaker (bright) or brush (dark): enveloped noise."""
    rng = random.Random(seed)
    out, low = [], 0.0
    for i in range(round(length * RATE)):
        t = i / RATE
        x = rng.uniform(-1, 1)
        low += (0.15 if bright else 0.3) * (x - low)
        v = (x - low) if bright else low
        out.append(volume * v * (1 - math.exp(-t / 0.004)) * math.exp(-t / (length * 0.3)))
    return out

def kick(volume: float) -> list[float]:
    out = []
    for i in range(round(0.25 * RATE)):
        t = i / RATE
        f = 48 + 55 * math.exp(-t / 0.025)
        out.append(volume * math.sin(2 * math.pi * f * t) * math.exp(-t / 0.09))
    return out

def tick(volume: float) -> list[float]:
    """The gear 'tick': a tiny, high wooden knock."""
    return soften(mallet(hz(95), 0.06, volume, 0.012, 0.001, 0.0), 4_000)

def reverb(track: list[float], mix: float = 0.25) -> list[float]:
    """A small, dark room: four feedback combs on a low-passed send, wrapped for looping."""
    n = len(track)
    send = soften(track, 2_500)
    wet = [0.0] * n
    for delay_s, fb in [(0.0297, 0.72), (0.0371, 0.7), (0.0411, 0.68), (0.0437, 0.66)]:
        d = round(delay_s * RATE)
        buf = [0.0] * n
        for _ in range(2):  # second pass lets the tail wrap round the loop point
            for i in range(n):
                buf[i] = send[i] + fb * buf[i - d]
        for i in range(n):
            wet[i] += buf[i] * 0.25
    wet = soften(wet, 3_000)
    return [d + mix * w for d, w in zip(track, wet)]

def finish(track: list[float], peak: float) -> list[float]:
    scale = peak / max(abs(v) for v in track)
    return [v * scale for v in track]

# --- Songs ------------------------------------------------------------------------------

# Rhodes voicings (MIDI) and bass roots.
AMAJ7, GSM7, FSM7, B7 = [57, 61, 64, 68], [56, 59, 63, 66], [54, 57, 61, 64], [54, 57, 59, 63]
EMAJ7, CSM7 = [56, 59, 63, 64], [56, 59, 61, 64]
ROOT_OF = {id(AMAJ7): 45, id(GSM7): 44, id(FSM7): 42, id(B7): 47, id(EMAJ7): 40, id(CSM7): 37}

# [beat, midi, beats]
LOBBY_TUNE = [
    [[0, 76, 1], [1, 73, 0.5], [1.5, 76, 0.5], [2, 80, 1.5]],
    [[0, 78, 1], [1, 75, 1], [2, 71, 2]],
    [[0, 73, 0.5], [0.5, 76, 0.5], [1, 78, 1], [2, 76, 0.5], [2.5, 73, 0.5], [3, 69, 1]],
    [[0, 71, 1.5], [1.5, 75, 0.5], [2, 78, 2]],
    [[0, 80, 1], [1, 78, 0.5], [1.5, 76, 0.5], [2, 73, 2]],
    [[0, 75, 0.5], [0.5, 76, 0.5], [1, 78, 1], [2, 71, 2]],
    [[0, 69, 1], [1, 73, 1], [2, 76, 1], [3, 78, 1]],
    [[0, 75, 1.5], [2, 71, 2]],
]

def lobby() -> list[float]:
    prog = [AMAJ7, GSM7, FSM7, B7] * 2
    loop = Loop(76, len(prog))
    b = loop.beat
    for bar, notes in enumerate(prog):
        root = ROOT_OF[id(notes)]
        loop.add(chord(notes, 2.5 * b, 0.11), bar * 4)
        loop.add(chord(notes, 1.5 * b, 0.07), bar * 4 + 2.5)
        loop.add(bass(hz(root), 2.4 * b, 0.3), bar * 4)
        loop.add(bass(hz(root + 7), 1.3 * b, 0.18), bar * 4 + 2.5)
        loop.add(kick(0.28), bar * 4)
        loop.add(kick(0.18), bar * 4 + 2.5)
        for beat in (1, 3):
            loop.add(noise_hit(0.2, 0.07, bar * 7 + beat, False), bar * 4 + beat)
        for k in range(8):
            loop.add(noise_hit(0.05, 0.018 if k % 2 else 0.01, bar * 31 + k, True), bar * 4 + k * 0.5)
        for beat, note, beats in LOBBY_TUNE[bar]:
            loop.add(kalimba(note, beats * b + 0.4, 0.15), bar * 4 + beat)
    return soften(reverb(loop.buf, 0.3), 5_000)

# --- Battle: a different colour from the lobby -------------------------------------------
# C# minor (the relative minor of the lobby's E major, so the gear sounds and jingles still
# fit), faster, and no Rhodes or kalimba: plucked strings, a low string pad, marimba and
# soft toms give it an "adventure" feel while staying gentle.

def pluck(freq: float, length: float, volume: float, seed: int, damp: float = 0.996) -> list[float]:
    """A plucked string (Karplus-Strong): warm and woody, like a muted guitar or pizzicato."""
    rng = random.Random(seed)
    period = max(2, round(RATE / freq))
    ring = [rng.uniform(-1, 1) for _ in range(period)]
    out = []
    for i in range(round(length * RATE)):
        k = i % period
        value = ring[k]
        ring[k] = damp * 0.5 * (value + ring[(k + 1) % period])
        out.append(volume * value * min(1.0, (length - i / RATE) / 0.04))
    return soften(out, 3_000)

def strings(freqs: list[float], length: float, volume: float) -> list[float]:
    """A slow, low string pad: detuned saws, heavily low-passed, swelling in."""
    out = []
    for i in range(round(length * RATE)):
        t = i / RATE
        env = min(1.0, t / 0.9) * min(1.0, (length - t) / 0.6)
        v = 0.0
        for f in freqs:
            for detune in (0.996, 1.004):
                v += 2 * ((f * detune * t) % 1.0) - 1
        out.append(volume * env * v / (2 * len(freqs)))
    return soften(soften(out, 700), 900)

def tom(freq: float, volume: float) -> list[float]:
    out = []
    for i in range(round(0.4 * RATE)):
        t = i / RATE
        f = freq * (1 + 0.5 * math.exp(-t / 0.02))
        out.append(volume * math.sin(2 * math.pi * f * t) * math.exp(-t / 0.13))
    return soften(out, 1_500)

# i - VI - III - VII: C#m, A, E, B (roots as MIDI).
BATTLE_PROG = [(49, [49, 52, 56]), (45, [45, 49, 52]), (52, [52, 56, 59]), (47, [47, 51, 54])] * 2
# Plucked riff in C# minor pentatonic, one bar each: [beat, midi].
BATTLE_RIFF = [
    [[0, 61], [0.5, 64], [1, 68], [1.5, 64], [2, 66], [2.5, 64], [3, 61], [3.5, 59]],
    [[0, 57], [0.5, 61], [1, 64], [1.5, 61], [2, 66], [2.5, 64], [3, 61], [3.5, 64]],
    [[0, 64], [0.5, 68], [1, 71], [1.5, 68], [2, 73], [2.5, 71], [3, 68], [3.5, 64]],
    [[0, 66], [0.5, 63], [1, 59], [1.5, 63], [2, 66], [2.5, 68], [3, 71], [3.5, 66]],
]
# Marimba answer phrase on the second half of the loop: [beat, midi, beats].
BATTLE_TUNE = [
    [], [], [], [],
    [[0, 73, 1], [1, 76, 1], [2, 80, 1.5], [3.5, 78, 0.5]],
    [[0, 76, 1.5], [1.5, 73, 0.5], [2, 69, 2]],
    [[0, 71, 1], [1, 76, 1], [2, 80, 1], [3, 83, 1]],
    [[0, 82, 2], [2, 78, 2]],
]

def battle() -> list[float]:
    loop = Loop(108, len(BATTLE_PROG))
    b = loop.beat
    for bar, (root, triad) in enumerate(BATTLE_PROG):
        loop.add(strings([hz(n) for n in triad], 4 * b + 0.5, 0.2), bar * 4)
        for k, (beat, note) in enumerate(BATTLE_RIFF[bar % 4]):
            loop.add(pluck(hz(note), 0.5, 0.2 if k % 2 == 0 else 0.13, bar * 17 + k), bar * 4 + beat)
        for beat, note, beats in BATTLE_TUNE[bar]:
            loop.add(mallet(hz(note), beats * b + 0.3, 0.17, 0.25, 0.004, 0.12), bar * 4 + beat)
        for k in range(4):
            loop.add(tick(0.04 if k % 2 == 0 else 0.025), bar * 4 + k)
    return soften(reverb(loop.buf, 0.22), 5_000)

def battle_drive() -> list[float]:
    """Toms, a running bass and shaker, faded in while a wave is fighting."""
    loop = Loop(108, len(BATTLE_PROG))
    b = loop.beat
    for bar, (root, triad) in enumerate(BATTLE_PROG):
        bass_root = root - 12 if root > 47 else root
        for k, (beat, step) in enumerate([(0, 0), (0.75, 0), (1.5, 7), (2, 0), (2.75, 0), (3.5, 12)]):
            loop.add(bass(hz(bass_root + step), 0.6 * b, 0.32 if beat in (0, 2) else 0.2), bar * 4 + beat)
        loop.add(tom(70, 0.55), bar * 4)
        loop.add(tom(70, 0.35), bar * 4 + 1.5)
        loop.add(tom(98, 0.4), bar * 4 + 2)
        if bar % 2 == 1:
            loop.add(tom(120, 0.3), bar * 4 + 3.5)
        for beat in (1, 3):
            loop.add(noise_hit(0.2, 0.12, bar * 7 + beat, False), bar * 4 + beat)
        for k in range(8):
            loop.add(noise_hit(0.05, 0.035 if k % 2 else 0.022, bar * 31 + k, True), bar * 4 + k * 0.5)
    return soften(loop.buf, 4_000)

def main() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    report = []
    for name, build, peak in [("lobby", lobby, 0.7), ("battle", battle, 0.62), ("battle_drive", battle_drive, 0.55)]:
        samples = finish(build(), peak)
        write_wav(DEST / (name + ".wav"), samples)
        report.append({
            "file": name + ".wav",
            "seconds": round(len(samples) / RATE, 3),
            "peak_dbfs": round(20 * math.log10(max(abs(v) for v in samples)), 2),
            "rms_dbfs": round(20 * math.log10(math.sqrt(sum(v * v for v in samples) / len(samples))), 2),
        })
    print(json.dumps(report, indent=2))

if __name__ == "__main__":
    main()
