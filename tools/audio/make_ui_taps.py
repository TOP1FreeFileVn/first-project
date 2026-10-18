"""Build the game's original, short idle-style UI taps.

Only damped resonances and gently filtered seeded noise are used: no recordings,
sample packs, or third-party audio. Run from any directory with Python 3.
"""

from __future__ import annotations

import json
import math
from pathlib import Path
import random
import struct
import wave


ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "game" / "audio" / "ui"
RATE = 22_050
PEAK = 0.28


def make_tap(variant: int) -> list[float]:
    """A soft 'tok': rounded body, short bright contact, no melodic tail."""
    rng = random.Random(742_019 + variant)
    duration = (0.072, 0.076, 0.074)[variant]
    tuning = (1.0, 1.028, 0.979)[variant]
    samples = []
    filtered_noise = 0.0
    for i in range(round(duration * RATE)):
        t = i / RATE
        # Frequencies settle quickly, unlike a sustained electronic beep.
        body_phase = 2 * math.pi * tuning * (
            430 * t + 100 * 0.008 * (1 - math.exp(-t / 0.008))
        )
        contact_phase = 2 * math.pi * tuning * (
            1_130 * t + 390 * 0.0028 * (1 - math.exp(-t / 0.0028))
        )
        body = 0.52 * math.sin(body_phase) * math.exp(-t / 0.013)
        contact = 0.31 * math.sin(contact_phase) * math.exp(-t / 0.0058)
        upper = 0.09 * math.sin(2 * math.pi * 2_050 * tuning * t) * math.exp(-t / 0.0034)
        filtered_noise += 0.32 * (rng.uniform(-1, 1) - filtered_noise)
        touch = 0.12 * filtered_noise * math.exp(-t / 0.003)
        attack = 1 - math.exp(-t / 0.00065)
        release = min(1.0, max(0.0, (duration - t) / 0.004))
        samples.append((body + contact + upper + touch) * attack * release)
    # Match variants without pushing them near full scale; leave mixer headroom.
    scale = PEAK / max(abs(value) for value in samples)
    return [value * scale for value in samples]


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
    for variant in range(3):
        samples = make_tap(variant)
        path = DEST / ("ui_tap_%02d.wav" % (variant + 1))
        write_wav(path, samples)
        report.append({
            "file": path.name,
            "seconds": round(len(samples) / RATE, 4),
            "peak_dbfs": round(20 * math.log10(max(abs(v) for v in samples)), 2),
            "rms_dbfs": round(20 * math.log10(math.sqrt(sum(v * v for v in samples) / len(samples))), 2),
            "first_sample": samples[0],
            "last_sample": round(samples[-1], 7),
        })
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
