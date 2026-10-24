"""Draw the battle effects and the arrow in the flat cat style (soft fills, one brown line),
replacing the Tiny Swords particle sheets.

    python -I tools/ui/make_battle_fx.py   ->   game/assets/battle/fx/<name>.png

Each effect is one horizontal strip of square frames (SpriteLib.EFFECTS reads the frame
size from it). Drawn 4x larger and scaled down for smooth edges.
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "game" / "assets" / "battle" / "fx"
LINE = (88, 63, 33)
SS = 4


def rgba(hex_color, alpha=255):
    h = hex_color.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (alpha,)


def fade(color, alpha):
    return color[:3] + (max(0, min(255, round(color[3] * alpha))),)


def blob(draw, cx, cy, r, fill, line_alpha=1.0, width=2.2):
    """A filled circle with the skin's outline (both fade with `line_alpha`)."""
    if r <= 0.3:
        return
    k = SS
    w = max(1, round(width * k))
    box = [(cx - r) * k, (cy - r) * k, (cx + r) * k, (cy + r) * k]
    draw.ellipse(box, fill=fill, outline=fade(LINE + (255,), line_alpha) if line_alpha > 0 else None, width=w)


def strip(name, size, frames, paint):
    sheet = Image.new("RGBA", (size * frames, size))
    for f in range(frames):
        big = Image.new("RGBA", (size * SS, size * SS))
        paint(ImageDraw.Draw(big), f / max(1, frames - 1), f, size)
        sheet.alpha_composite(big.resize((size, size), Image.Resampling.LANCZOS), (f * size, 0))
    OUT.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT / f"{name}.png")
    print(name, sheet.size)


def puff_painter(seed, color, count):
    rng = random.Random(seed)
    puffs = [(rng.uniform(0, math.tau), rng.uniform(0.25, 0.45), rng.uniform(0.16, 0.24)) for _ in range(count)]

    def paint(draw, t, _f, size):
        c = size / 2
        alpha = 1.0 - t ** 1.6
        for angle, dist, radius in puffs:
            d = size * dist * (0.35 + 0.65 * t)
            r = size * radius * (0.6 + 0.5 * math.sin(math.pi * min(1.0, t * 1.3)))
            blob(draw, c + math.cos(angle) * d, c + 0.15 * size + math.sin(angle) * d * 0.5 - t * size * 0.12,
                 r * (1 - 0.4 * t), fade(rgba(color), alpha), alpha)
    return paint


def explosion(draw, t, _f, size):
    c = size / 2
    alpha = 1.0 - max(0.0, t - 0.45) / 0.55
    grow = 1 - (1 - t) ** 2
    # Smoke puffs drift out last.
    rng = random.Random(7)
    for i in range(7):
        angle = i / 7 * math.tau + rng.uniform(-0.3, 0.3)
        d = size * 0.3 * grow
        blob(draw, c + math.cos(angle) * d, c + math.sin(angle) * d * 0.8, size * 0.13 * (0.5 + grow),
             fade(rgba("#d9c7ad"), alpha * 0.9), alpha)
    # Fire ball: orange, then a yellow heart that shrinks first.
    blob(draw, c, c, size * 0.32 * (0.4 + 0.6 * grow) * (1 - 0.5 * t), fade(rgba("#ff9b3d"), alpha), alpha)
    blob(draw, c, c, size * 0.2 * (1 - t) ** 1.2 * (0.5 + grow), fade(rgba("#ffe066"), alpha), 0)


def blast(draw, t, _f, size):
    c = size / 2
    alpha = 1.0 - t ** 1.5
    k = SS
    r = size * (0.12 + 0.34 * (1 - (1 - t) ** 3))
    width = max(1, round(size * 0.07 * (1 - t) * k))
    draw.ellipse([(c - r) * k, (c - r * 0.75) * k, (c + r) * k, (c + r * 0.75) * k],
                 outline=fade(rgba("#fff1b8"), alpha), width=width)
    for i in range(8):
        angle = i / 8 * math.tau
        d = r * 1.05
        blob(draw, c + math.cos(angle) * d, c + math.sin(angle) * d * 0.75, size * 0.035 * (1 - t) + 0.5,
             fade(rgba("#ffd23f"), alpha), alpha, 1.6)


def fire(draw, t, f, size):
    """A flickering teardrop flame: orange body with the outline, a yellow heart inside."""
    k = SS
    flick = math.sin(f / 8 * math.tau)
    for scale, color, line in ((1.0, "#ff8a3d", True), (0.58, "#ffd23f", False)):
        h = size * 0.8 * scale * (1 + 0.08 * flick)
        w = size * 0.34 * scale * (1 - 0.05 * flick)
        cx = size / 2
        cy = size * 0.93 - h / 2
        lean = size * 0.06 * flick
        pts = []
        for i in range(48):
            a = i / 48 * math.tau
            y = -math.cos(a)
            x = math.sin(a) * math.sin(a / 2) ** 1.2
            pts.append(((cx + x * w + lean * (1 - (y + 1) / 2)) * k, (cy + y * h / 2) * k))
        draw.polygon(pts, fill=rgba(color), outline=LINE + (255,) if line else None, width=round(2.2 * k) if line else 0)


def heal(draw, t, _f, size):
    c = size / 2
    alpha = 1.0 - max(0.0, t - 0.5) / 0.5
    k = SS
    r = size * (0.2 + 0.18 * t)
    draw.ellipse([(c - r) * k, (c + size * 0.18 - r * 0.35) * k, (c + r) * k, (c + size * 0.18 + r * 0.35) * k],
                 outline=fade(rgba("#7ad66b"), alpha * 0.8), width=round(3 * k))
    rng = random.Random(11)
    for i in range(5):
        x = c + rng.uniform(-0.25, 0.25) * size
        y = c + size * 0.2 - (0.1 + 0.5 * ((t + i * 0.17) % 1.0)) * size * 0.8
        s = size * 0.06 * (0.7 + 0.5 * rng.random())
        a = alpha * (1 - ((t + i * 0.17) % 1.0) ** 2)
        for dx, dy, ww, hh in ((-s, -s / 3, s, s / 3), (-s / 3, -s, s / 3, s)):
            draw.rounded_rectangle([(x + dx) * k, (y + dy) * k, (x + ww) * k, (y + hh) * k], radius=s * 0.3 * k,
                                   fill=fade(rgba("#8ee07a"), a), outline=fade(LINE + (255,), a), width=round(1.8 * k))


def arrow(fletch):
    """A small arrow pointing right (Projectile rotates it toward the target)."""
    size = 64
    big = Image.new("RGBA", (size * SS, size * SS))
    d = ImageDraw.Draw(big)
    k = SS
    d.line([(12 * k, 32 * k), (50 * k, 32 * k)], fill=LINE + (255,), width=round(7 * k))
    d.line([(13 * k, 32 * k), (49 * k, 32 * k)], fill=rgba("#c9925a"), width=round(3.5 * k))
    d.polygon([(60 * k, 32 * k), (47 * k, 24 * k), (47 * k, 40 * k)], fill=rgba("#d6dee6"), outline=LINE + (255,), width=round(2.4 * k))
    for sign in (-1, 1):
        d.polygon([(10 * k, 32 * k), (20 * k, 32 * k), (14 * k, (32 + sign * 9) * k), (5 * k, (32 + sign * 9) * k)],
                  fill=rgba(fletch), outline=LINE + (255,), width=round(2 * k))
    return big.resize((size, size), Image.Resampling.LANCZOS)


def main():
    strip("dust", 64, 8, puff_painter(3, "#e6d3b3", 5))
    strip("dust2", 64, 10, puff_painter(5, "#cfe3c8", 6))
    strip("explosion", 192, 8, explosion)
    strip("blast", 192, 10, blast)
    strip("fire", 64, 8, fire)
    strip("heal", 192, 11, heal)
    for name, color in (("arrow_blue", "#5fb0ea"), ("arrow_red", "#e0574b")):
        arrow(color).save(OUT / f"{name}.png")
        print(name)


if __name__ == "__main__":
    main()
