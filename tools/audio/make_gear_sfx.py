"""Build the gear board's soft, chill sounds: pick up, place, return and merge.

Everything is a warm wooden/marimba-like voice (damped sines, rounded attack,
one-pole low-pass, short room echo) so dragging gears all match long feels calm,
never metallic or clicky. No recordings or third-party audio are used.
SoundLib lowers `gear_place` and raises `gear_merge` by tier through pitch_scale.
"""

from __future__ import annotations

import json
import math
from pathlib import Path
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "game" / "audio" / "gear"
RATE = 22_050

def silence(seconds: float) -> list[float]:
    return [0.0] * round(seconds * RATE)

def mix(*tracks: list[float]) -> list[float]:
    out = silence(max(len(t) for t in tracks) / RATE)
    for track in tracks:
        for i, value in enumerate(track):
            out[i] += value
    return out

def delay(track: list[float], seconds: float) -> list[float]:
    return silence(seconds) + track

def mallet(freq: float, length: float, volume: float, decay: float, attack = 0.006, bright = 0.18) -> list[float]:
    """A soft marimba-ish note: fundamental, a gentle 4th partial and a felt-mallet attack."""
    out = []
    for i in range(round(length * RATE)):
        t = i / RATE
        env = (1 - math.exp(-t / attack)) * math.exp(-t / decay)
        tone = math.sin(2 * math.pi * freq * t)
        tone += bright * math.sin(2 * math.pi * freq * 3.93 * t) * math.exp(-t / (decay * 0.18))
        tone += 0.22 * math.sin(2 * math.pi * freq * 0.5 * t) * math.exp(-t / (decay * 0.6))
        out.append(volume * env * tone)
    return out

def breath(length: float, volume: float, seed: int, swell = 0.5) -> list[float]:
    """Very dark noise that swells in and out: a soft 'fff' instead of a scrape."""
    rng = random.Random(seed)
    out, a, b = [], 0.0, 0.0
    n = round(length * RATE)
    for i in range(n):
        x = i / n
        env = math.sin(math.pi * min(1.0, x / swell) * 0.5) ** 2 * (1 - x) ** 1.5
        a += 0.08 * (rng.uniform(-1, 1) - a)
        b += 0.08 * (a - b)
        out.append(volume * env * b * 6)
    return out

def soften(track: list[float], cutoff: float) -> list[float]:
    k = 1 - math.exp(-2 * math.pi * cutoff / RATE)
    out, y = [], 0.0
    for value in track:
        y += k * (value - y)
        out.append(y)
    return out

def room(track: list[float], seconds = 0.11, feedback = 0.28, taps = 3) -> list[float]:
    out = track + silence(seconds * taps)
    for n in range(1, taps + 1):
        gain = feedback ** n
        offset = round(seconds * n * RATE)
        for i, value in enumerate(track):
            out[i + offset] += value * gain
    return soften(out, 3_200)

def finish(track: list[float], peak: float) -> list[float]:
    fade = round(0.012 * RATE)
    for i in range(fade):
        track[-1 - i] *= i / fade
    scale = peak / max(abs(v) for v in track)
    return [v * scale for v in track]

# E major pentatonic, the same warm key for every gear sound.
E4, Gs4, B4, Cs5, E5, Gs5, B5 = 329.6, 415.3, 493.9, 554.4, 659.3, 830.6, 987.8

def gear_pick() -> list[float]:
    """Lifting: a light, rounded 'pum' that leans upward."""
    note = mix(mallet(B4, 0.16, 0.6, 0.05), delay(mallet(E5, 0.14, 0.35, 0.04), 0.035))
    return finish(room(soften(note, 2_400), 0.09, 0.18, 2), 0.42)

def gear_place() -> list[float]:
    """Settling into a slot: a warm wooden 'tok' with a soft low cushion and short tail."""
    body = mallet(E4, 0.32, 0.8, 0.09, 0.004, 0.14)
    cushion = mallet(E4 / 2, 0.18, 0.35, 0.05, 0.008, 0.0)
    felt = breath(0.05, 0.12, 31)
    return finish(room(soften(mix(body, cushion, felt), 2_000)), 0.55)

def gear_back() -> list[float]:
    """Not placed: two quiet notes stepping down, a calm 'never mind'."""
    note = mix(mallet(Gs4, 0.16, 0.5, 0.05), delay(mallet(E4, 0.22, 0.45, 0.07), 0.07))
    return finish(room(soften(note, 1_800), 0.1, 0.2, 2), 0.35)

def gear_merge() -> list[float]:
    """Two gears join: a soft swell, then a gentle kalimba-like rising arpeggio."""
    swell = breath(0.22, 0.25, 77, 0.8)
    arp = mix(*(delay(mallet(f, 0.7, v, 0.22, 0.005, 0.1), 0.16 + 0.07 * n)
        for n, (f, v) in enumerate([(E5, 0.5), (Gs5, 0.45), (B5, 0.5)])))
    pad = delay(mix(mallet(E4, 0.8, 0.25, 0.3, 0.04, 0.0), mallet(B4, 0.8, 0.18, 0.3, 0.04, 0.0)), 0.16)
    return finish(room(soften(mix(swell, arp, pad), 2_600), 0.13, 0.3, 3), 0.6)

def write_wav(path: Path, samples: list[float]) -> None:
    pcm = struct.pack("<%dh" % len(samples), *(round(v * 32_767) for v in samples))
    with wave.open(str(path), "wb") as target:
        target.setnchannels(1)
        target.setsampwidth(2)
        target.setframerate(RATE)
        target.writeframes(pcm)

def main() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    report = []
    for name, build in [("gear_pick", gear_pick), ("gear_place", gear_place),
            ("gear_back", gear_back), ("gear_merge", gear_merge)]:
        samples = build()
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
