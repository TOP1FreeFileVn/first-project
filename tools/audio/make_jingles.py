"""Build the battle jingles: battle start, wave start, victory and defeat.

Same voices and key as make_music.py, so they sit on top of the music (MusicLib ducks
it for victory and defeat). Each one is short and readable at a glance:
  battle_start  a soft gong, a kalimba run up and an open chord: "here we go".
  wave          two calm wooden bell notes: "they are coming".
  victory       a bright kalimba fanfare resolving on E major 9, with sparkles.
  defeat        a slow fall onto A minor then E: clearly sad, still gentle.
No recordings or third-party audio are used.
"""

from __future__ import annotations

import json
import math
from pathlib import Path

from make_gear_sfx import RATE, breath, mallet, soften, write_wav
from make_music import chord, hz, kalimba

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "game" / "audio" / "jingle"

class Track:
    def __init__(self, seconds: float) -> None:
        self.buf = [0.0] * round(seconds * RATE)

    def add(self, sound: list[float], at: float) -> None:
        start = round(at * RATE)
        for i, value in enumerate(sound[: len(self.buf) - start]):
            self.buf[start + i] += value

def gong(freq: float, length: float, volume: float) -> list[float]:
    """A soft, round gong: inharmonic partials with slow decay."""
    out = []
    for i in range(round(length * RATE)):
        t = i / RATE
        env = (1 - math.exp(-t / 0.02)) * math.exp(-t / (length * 0.35))
        v = math.sin(2 * math.pi * freq * t) + 0.5 * math.sin(2 * math.pi * freq * 2.76 * t) * math.exp(-t / 0.4)
        v += 0.25 * math.sin(2 * math.pi * freq * 5.4 * t) * math.exp(-t / 0.2)
        out.append(volume * env * v)
    return out

def room(track: list[float]) -> list[float]:
    """Short echoes and a low-pass: the jingles sit in the same room as the music."""
    out = track + [0.0] * round(0.5 * RATE)
    for delay_s, gain in [(0.09, 0.25), (0.17, 0.15), (0.26, 0.08), (0.37, 0.04)]:
        d = round(delay_s * RATE)
        for i, value in enumerate(track):
            out[i + d] += value * gain
    return soften(out, 4_500)

def finish(track: list[float], peak: float) -> list[float]:
    fade = round(0.05 * RATE)
    for i in range(fade):
        track[-1 - i] *= i / fade
    scale = peak / max(abs(v) for v in track)
    return [v * scale for v in track]

def battle_start() -> list[float]:
    t = Track(2.4)
    t.add(gong(hz(40), 2.3, 0.35), 0.0)
    t.add(breath(0.6, 0.25, 5, 0.9), 0.0)
    for k, note in enumerate([64, 68, 71, 73, 76, 80]):
        t.add(kalimba(note, 0.6, 0.22), 0.1 + 0.07 * k)
    t.add(chord([52, 59, 64, 68, 71], 1.8, 0.14), 0.55)
    t.add(kalimba(83, 1.2, 0.2), 0.55)
    return finish(room(t.buf), 0.75)

def wave() -> list[float]:
    t = Track(1.3)
    t.add(mallet(hz(71), 0.9, 0.5, 0.3, 0.004, 0.25), 0.0)
    t.add(mallet(hz(76), 1.1, 0.5, 0.35, 0.004, 0.25), 0.22)
    t.add(gong(hz(52), 1.0, 0.18), 0.22)
    return finish(room(t.buf), 0.6)

def victory() -> list[float]:
    t = Track(3.2)
    for k, (note, at) in enumerate([(71, 0.0), (76, 0.14), (80, 0.28), (83, 0.42)]):
        t.add(kalimba(note, 0.5, 0.26), at)
    t.add(kalimba(88, 1.6, 0.3), 0.62)
    t.add(kalimba(80, 1.6, 0.18), 0.62)
    t.add(chord([52, 56, 59, 63, 66], 2.4, 0.16), 0.62)
    t.add(gong(hz(40), 2.2, 0.22), 0.62)
    for k, note in enumerate([88, 92, 95, 100]):
        t.add(mallet(hz(note), 0.5, 0.08, 0.15, 0.002, 0.0), 1.0 + 0.09 * k)
    return finish(room(t.buf), 0.8)

def defeat() -> list[float]:
    t = Track(3.4)
    for note, at in [(76, 0.0), (75, 0.3), (71, 0.6), (69, 0.9)]:
        t.add(kalimba(note, 0.7, 0.22), at)
    t.add(chord([45, 57, 60, 64], 1.4, 0.15), 0.9)  # A minor: the sad turn
    t.add(kalimba(64, 2.0, 0.22), 1.6)
    t.add(chord([40, 52, 59, 64], 1.8, 0.12), 1.6)
    t.add(gong(hz(33), 2.0, 0.2), 1.6)
    return finish(room(soften(t.buf, 2_800)), 0.7)

def main() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    report = []
    for name, build in [("battle_start", battle_start), ("wave", wave), ("victory", victory), ("defeat", defeat)]:
        samples = build()
        write_wav(DEST / (name + ".wav"), samples)
        report.append({
            "file": name + ".wav",
            "seconds": round(len(samples) / RATE, 3),
            "peak_dbfs": round(20 * math.log10(max(abs(v) for v in samples)), 2),
        })
    print(json.dumps(report, indent=2))

if __name__ == "__main__":
    main()
