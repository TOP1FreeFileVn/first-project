"""Build the battle jingles: battle start, wave start, victory and defeat.

Same voices and key as make_music.py, so they sit on top of the music (MusicLib ducks
it for victory and defeat). Each one is short and readable at a glance:
  battle_start  a soft gong, a kalimba run up and an open chord: "here we go".
  wave          two calm wooden bell notes: "they are coming".
  victory       a horn fanfare (three calls up to a held E major chord), with sparkles.
  defeat        the sad trombone: four falling horn notes, the last sliding down.
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

def horn(note: int, length: float, volume: float, bright: float = 1.0, bend: float = 0.0) -> list[float]:
    """A soft brass voice: odd and even harmonics that swell in, with a little vibrato;
    `bend` slides the pitch (semitones) over the note, for the sad trombone fall."""
    out, phase = [], 0.0
    n = round(length * RATE)
    f0 = hz(note)
    for i in range(n):
        t = i / RATE
        u = i / n
        f = f0 * 2 ** (bend * u / 12) * (1 + 0.006 * math.sin(2 * math.pi * 5.5 * t) * min(1.0, t / 0.25))
        phase += 2 * math.pi * f / RATE
        env = min(1.0, t / 0.05) * (1 - u) ** 0.4 * (0.85 + 0.15 * math.sin(math.pi * min(1.0, t / 0.12)))
        v = sum((bright ** k) * math.sin(phase * (k + 1)) / (k + 1) for k in range(6))
        out.append(volume * env * v)
    return soften(out, 3_200)

def victory() -> list[float]:
    """A fanfare: three short horn calls up to a held E major chord, kalimba sparkles,
    a gong under it. Bright and brass-led, so a win sounds like a win."""
    t = Track(3.4)
    for note, at, length in [(64, 0.0, 0.16), (64, 0.17, 0.16), (64, 0.34, 0.16), (71, 0.52, 0.5)]:
        t.add(horn(note, length, 0.22, 0.75), at)
    for note in (64, 68, 71, 76):
        t.add(horn(note, 1.9, 0.12, 0.7), 1.05)
    t.add(horn(59, 1.9, 0.12, 0.6), 1.05)
    t.add(gong(hz(40), 2.2, 0.22), 1.05)
    for k, note in enumerate([88, 92, 95, 100, 104]):
        t.add(kalimba(note, 0.6, 0.12), 1.15 + 0.08 * k)
    return finish(room(t.buf), 0.82)

def _old_victory() -> list[float]:
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
    """The sad trombone: four falling horn notes, the last one sliding down and wobbling,
    then a low gong. Unmistakably "lost", still soft."""
    t = Track(3.3)
    for note, at, length, bend in [(67, 0.0, 0.4, 0.0), (66, 0.45, 0.4, 0.0), (65, 0.9, 0.4, 0.0), (64, 1.35, 1.4, -1.5)]:
        t.add(horn(note, length, 0.24, 0.65, bend), at)
    t.add(chord([40, 52, 55, 59], 1.7, 0.1), 1.35)
    t.add(gong(hz(33), 1.9, 0.18), 1.4)
    return finish(room(soften(t.buf, 2_800)), 0.72)

def _old_defeat() -> list[float]:
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
