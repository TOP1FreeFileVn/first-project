"""Build every game effect (except the UI taps) in the same soft, wooden style.

Voices come from make_gear_sfx.py / make_music.py / make_jingles.py: felt-mallet marimba,
kalimba, Rhodes, round gong, dark breathy noise. No square or saw waves, no beeps.
Everything sits in E major so effects, music and jingles agree. Combat sounds are short
and quiet because many play at once; rewards are brighter and a little longer.
No recordings or third-party audio are used.

    python tools/audio/make_sfx.py   ->   game/audio/sfx/<name>.wav
"""

from __future__ import annotations

import json
import math
from pathlib import Path
import random

from make_gear_sfx import RATE, breath, delay, mallet, mix, room, soften, write_wav
from make_music import chord, hz, kalimba
from make_jingles import gong

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "game" / "audio" / "sfx"

# --- Extra voices -----------------------------------------------------------------------

def sweep(f0: float, f1: float, length: float, volume: float, decay: float, attack: float = 0.003) -> list[float]:
    """A round sine whose pitch glides exponentially from f0 to f1 (a soft 'bloop')."""
    out, phase = [], 0.0
    n = round(length * RATE)
    for i in range(n):
        t = i / RATE
        f = f0 * (f1 / f0) ** (i / n)
        phase += 2 * math.pi * f / RATE
        env = (1 - math.exp(-t / attack)) * math.exp(-t / decay)
        out.append(volume * env * math.sin(phase))
    return out

def hush(length: float, volume: float, seed: int, cutoff: float, decay: float, attack: float = 0.002) -> list[float]:
    """Filtered noise with a quick fade-in and exponential tail: a soft thump or swish."""
    rng = random.Random(seed)
    k = 1 - math.exp(-2 * math.pi * cutoff / RATE)
    out, a, b = [], 0.0, 0.0
    for i in range(round(length * RATE)):
        t = i / RATE
        a += k * (rng.uniform(-1, 1) - a)
        b += k * (a - b)
        out.append(volume * 3 * b * (1 - math.exp(-t / attack)) * math.exp(-t / decay))
    return out

def swish(length: float, volume: float, seed: int) -> list[float]:
    """Air moving past: noise with the low end removed, swelling in then out."""
    rng = random.Random(seed)
    out, low, prev = [], 0.0, 0.0
    n = round(length * RATE)
    for i in range(n):
        x = rng.uniform(-1, 1)
        low += 0.25 * (x - low)
        high = x - low
        prev += 0.45 * (high - prev)
        env = math.sin(math.pi * i / n) ** 2
        out.append(volume * env * prev)
    return out

def bell(note: int, length: float, volume: float) -> list[float]:
    """A tiny glass-like bell: kalimba body with a brighter, quicker partial."""
    return mallet(hz(note), length, volume, length * 0.35, 0.002, 0.35)

def finish(track: list[float], peak: float) -> list[float]:
    fade = round(0.01 * RATE)
    for i in range(min(fade, len(track))):
        track[-1 - i] *= i / fade
    scale = peak / max(abs(v) for v in track)
    return [v * scale for v in track]

def run(notes: list[int], gap: float, length: float, volume: float, voice=kalimba) -> list[float]:
    return mix(*(delay(voice(n, length, volume), k * gap) for k, n in enumerate(notes)))

# --- Shop, coins, rewards -----------------------------------------------------------------

def coin() -> list[float]:
    return finish(room(mix(bell(88, 0.35, 0.6), delay(bell(95, 0.45, 0.6), 0.06)), 0.08, 0.18, 2), 0.32)

def reward() -> list[float]:
    return finish(room(run([76, 80, 83, 88], 0.07, 0.7, 0.5), 0.1, 0.25, 3), 0.45)

def buy() -> list[float]:
    wood = mallet(hz(64), 0.2, 0.7, 0.05, 0.003, 0.12)
    return finish(room(mix(wood, delay(bell(88, 0.35, 0.5), 0.05), delay(bell(92, 0.4, 0.45), 0.11)), 0.08, 0.18, 2), 0.38)

def sell() -> list[float]:
    return finish(room(mix(bell(92, 0.3, 0.5), delay(bell(88, 0.4, 0.5), 0.08), swish(0.18, 0.25, 9)), 0.08, 0.18, 2), 0.34)

def reroll() -> list[float]:
    ticks = run([71, 73, 76], 0.05, 0.18, 0.45, lambda n, l, v: mallet(hz(n), l, v, 0.04, 0.002, 0.1))
    return finish(room(mix(swish(0.3, 0.35, 21), ticks), 0.07, 0.15, 2), 0.34)

# --- Combat (short and quiet: many play at once) ------------------------------------------

def hit() -> list[float]:
    """A padded thump, not a click: low wooden body plus a short dark puff."""
    return finish(soften(mix(sweep(190, 120, 0.09, 0.8, 0.025), hush(0.06, 0.5, 3, 1_400, 0.012)), 2_500), 0.28)

def arrow() -> list[float]:
    return finish(soften(mix(swish(0.14, 0.6, 5), sweep(900, 600, 0.06, 0.12, 0.02)), 4_000), 0.22)

def death() -> list[float]:
    """A cat soldier falls: two soft wooden notes stepping down."""
    return finish(room(mix(mallet(hz(68), 0.2, 0.6, 0.06), delay(mallet(hz(64), 0.3, 0.6, 0.09), 0.08)), 0.08, 0.15, 2), 0.28)

def pop() -> list[float]:
    """A monster poofs: a round bubble 'bloop' and a puff of air."""
    return finish(soften(mix(sweep(260, 620, 0.09, 0.8, 0.04), delay(hush(0.12, 0.35, 7, 2_200, 0.03), 0.02)), 3_500), 0.26)

def explosion() -> list[float]:
    """A soft, cushioned boom: low sine drop and a dark rumble, no crackle."""
    body = sweep(110, 38, 0.6, 0.9, 0.18)
    rumble = hush(0.8, 0.8, 11, 500, 0.22)
    return finish(soften(mix(body, rumble, hush(0.1, 0.4, 12, 2_000, 0.03)), 1_800), 0.5)

def heal() -> list[float]:
    return finish(room(mix(run([80, 83, 88], 0.06, 0.5, 0.4, bell), breath(0.4, 0.15, 13, 0.6)), 0.09, 0.22, 2), 0.24)

def wall() -> list[float]:
    """A blow on the wooden wall: knock plus thud."""
    return finish(soften(mix(mallet(hz(45), 0.25, 0.9, 0.06, 0.002, 0.25), hush(0.1, 0.5, 15, 900, 0.03)), 2_000), 0.32)

def hero() -> list[float]:
    """Hero skill / arrival: a round gong and a kalimba fifth, warm rather than brassy."""
    return finish(room(mix(gong(hz(40), 1.2, 0.35), delay(kalimba(71, 0.8, 0.4), 0.04), delay(kalimba(76, 1.0, 0.45), 0.13),
        breath(0.35, 0.2, 17, 0.7)), 0.1, 0.25, 3), 0.5)

def jump() -> list[float]:
    return finish(sweep(300, 560, 0.12, 0.6, 0.06, 0.01), 0.18)

# --- Chests and summons -------------------------------------------------------------------

def thud() -> list[float]:
    """The chest lands: heavy wooden thump, a little rattle of the lid."""
    rattle = run([57, 59], 0.05, 0.08, 0.25, lambda n, l, v: mallet(hz(n), l, v, 0.02, 0.001, 0.4))
    return finish(soften(mix(sweep(120, 55, 0.3, 1.0, 0.09), hush(0.18, 0.7, 19, 700, 0.05), delay(rattle, 0.06)), 2_200), 0.55)

def charge() -> list[float]:
    """The chest gathers power: a breath swells and kalimba notes speed up and climb."""
    length = 1.15
    out = breath(length, 0.35, 23, 0.95)
    t, gap, k = 0.0, 0.16, 0
    notes = [64, 66, 68, 71, 73, 76, 78, 80, 83, 85, 88]
    while t < length - 0.1 and k < len(notes):
        out = mix(out, delay(kalimba(notes[k], 0.35, 0.18 + 0.03 * k), t))
        t += gap
        gap *= 0.82
        k += 1
    return finish(room(out, 0.08, 0.2, 2), 0.38)

def chest_open() -> list[float]:
    """The lid pops: a puff of air, a round pop and a sparkle run."""
    sparkle = delay(run([83, 88, 92, 95, 100], 0.045, 0.6, 0.35, bell), 0.06)
    return finish(room(mix(swish(0.35, 0.6, 29), sweep(220, 480, 0.12, 0.7, 0.05), sparkle), 0.1, 0.25, 3), 0.5)

def flip() -> list[float]:
    """A card turning: a soft papery flick."""
    return finish(mix(swish(0.09, 0.6, 31), delay(mallet(hz(83), 0.1, 0.15, 0.03, 0.002, 0.0), 0.04)), 0.2)

def rare() -> list[float]:
    return finish(room(run([76, 80, 83], 0.08, 0.6, 0.5), 0.1, 0.25, 3), 0.4)

def epic() -> list[float]:
    pad = chord([56, 61, 64, 68], 1.2, 0.18)  # C# minor add9: a touch of mystery
    return finish(room(mix(pad, delay(run([80, 85, 88, 92], 0.07, 0.8, 0.45), 0.08)), 0.11, 0.28, 3), 0.5)

def legend() -> list[float]:
    """A held breath, a gong, a big Rhodes E major 9 and a long sparkle climbing up."""
    pad = delay(chord([52, 56, 59, 63, 66], 2.0, 0.22), 0.12)
    sparkle = delay(run([76, 80, 83, 88, 92, 95, 100], 0.07, 0.9, 0.4, bell), 0.12)
    tune = delay(mix(kalimba(88, 1.4, 0.4), delay(kalimba(95, 1.6, 0.45), 0.35)), 0.6)
    return finish(room(mix(gong(hz(40), 2.2, 0.45), pad, sparkle, tune, breath(0.5, 0.2, 37, 0.9)), 0.12, 0.3, 4), 0.6)

def pet() -> list[float]:
    """A tapped cat: a short, soft "mrrp" (rising then falling, through a gentle filter) and a chime."""
    out, phase = [], 0.0
    n = round(0.28 * RATE)
    for i in range(n):
        t = i / RATE
        u = i / n
        f = 520 + 240 * math.sin(math.pi * min(1.0, u * 1.4)) - 80 * u
        phase += 2 * math.pi * f / RATE
        env = (1 - math.exp(-t / 0.02)) * math.sin(math.pi * u) ** 0.6
        v = math.sin(phase) + 0.35 * math.sin(2 * phase) + 0.12 * math.sin(3 * phase)
        out.append(0.5 * env * v * (1 + 0.15 * math.sin(2 * math.pi * 28 * t)))
    voice = soften(soften(out, 1_800), 2_600)
    return finish(room(mix(voice, delay(bell(88, 0.35, 0.18), 0.18)), 0.08, 0.15, 2), 0.36)

SOUNDS = {
    "coin": coin, "reward": reward, "buy": buy, "sell": sell, "reroll": reroll,
    "hit": hit, "arrow": arrow, "death": death, "pop": pop, "explosion": explosion, "heal": heal,
    "wall": wall, "hero": hero, "jump": jump,
    "thud": thud, "charge": charge, "chest_open": chest_open, "flip": flip,
    "rare": rare, "epic": epic, "legend": legend, "pet": pet,
}

def main() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    report = []
    for name, build in SOUNDS.items():
        samples = build()
        write_wav(DEST / (name + ".wav"), samples)
        report.append({"file": name + ".wav", "seconds": round(len(samples) / RATE, 3),
            "peak_dbfs": round(20 * math.log10(max(abs(v) for v in samples)), 1)})
    print(json.dumps(report))

if __name__ == "__main__":
    main()
