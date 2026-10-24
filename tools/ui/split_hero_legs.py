"""Give the hero cat the soldier cats' leg construction: a closed body with its own
rounded bottom outline, and two separate leg stubs drawn behind it (only the feet show),
so the body's and the feet's lines never meet or overlap.

The approved hero parts (docs/design/2026-10-20/cat-spine-parts/png/hero_neutral_9px) have an
open-bottomed body whose outline the two feet complete. This keeps everything of the body
above its lower edge unchanged, closes that edge, and draws new feet in the same fur and ink.
Then it rebuilds the rigs (build_hero_preview_rig, cached weapon renders) and re-adds the
hero's animations (animate_hero_rig).

    python -I tools/ui/split_hero_legs.py
"""
import shutil
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_hero_preview_rig as rig
import animate_hero_rig as anim

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "docs/design/2026-10-20/cat-spine-parts/png/hero_neutral_9px"
OUT = ROOT / "docs/design/2026-10-24/hero-legs"
INK = (88, 63, 33, 255)
FUR = (245, 162, 93, 255)
LINE = 27              # the parts' 9 px line at 3x
SS = 4                 # supersampling for smooth curves

# 3x canvas pixels (768 x 720, ground at y 720).
KEEP_ABOVE = 596       # body rows kept as drawn
BODY_LEFT, BODY_RIGHT = 118, 649
BODY_BOTTOM = 636      # the new closed bottom edge (outer edge of the line)
CORNER = 78
LEG_W = 132
LEG_TOP = 560          # hidden behind the body
LEG_BOTTOM = 708
LEG_X = (264, 503)     # left / right leg centres


def big(size):
    return Image.new("RGBA", (size[0] * SS, size[1] * SS))


def down(image):
    return image.resize((image.width // SS, image.height // SS), Image.Resampling.LANCZOS)


def closed_body(original: Image.Image) -> Image.Image:
    """The original body above KEEP_ABOVE; below it a fur field with a rounded, outlined bottom."""
    w, h = original.size
    shape = big((w, h))
    d = ImageDraw.Draw(shape)
    box = [BODY_LEFT * SS, 300 * SS, BODY_RIGHT * SS, BODY_BOTTOM * SS]
    d.rounded_rectangle(box, radius=CORNER * SS, fill=INK)
    inset = LINE * SS
    d.rounded_rectangle([box[0] + inset, box[1] + inset, box[2] - inset, box[3] - inset],
                        radius=(CORNER - LINE) * SS, fill=FUR)
    shape = down(shape)
    out = Image.new("RGBA", (w, h))
    out.paste(shape.crop((0, KEEP_ABOVE, w, h)), (0, KEEP_ABOVE))
    out.paste(original.crop((0, 0, w, KEEP_ABOVE)), (0, 0))
    return out


def leg(cx: int, size) -> Image.Image:
    """A stub like the soldier cats' legs: rounded bottom, two toe marks."""
    image = big(size)
    d = ImageDraw.Draw(image)
    half = LEG_W // 2
    box = [(cx - half) * SS, LEG_TOP * SS, (cx + half) * SS, LEG_BOTTOM * SS]
    d.rounded_rectangle(box, radius=half * SS, fill=INK)
    inset = LINE * SS
    d.rounded_rectangle([box[0] + inset, box[1] + inset, box[2] - inset, box[3] - inset],
                        radius=(half - LINE) * SS, fill=FUR)
    for dx in (-21, 21):
        x = (cx + dx) * SS
        d.line([(x, (LEG_BOTTOM - 46) * SS), (x, (LEG_BOTTOM - 24) * SS)], fill=INK, width=12 * SS)
        for y in ((LEG_BOTTOM - 46) * SS, (LEG_BOTTOM - 24) * SS):
            d.ellipse([x - 6 * SS, y - 6 * SS, x + 6 * SS, y + 6 * SS], fill=INK)
    return down(image)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for part in SOURCE.glob("*.png"):
        shutil.copy(part, OUT / part.name)
    body = Image.open(SOURCE / "body.png").convert("RGBA")
    closed_body(body).save(OUT / "body.png")
    leg(LEG_X[0], body.size).save(OUT / "foot_L_image.png")
    leg(LEG_X[1], body.size).save(OUT / "foot_R_image.png")
    # A quick look at the new assembly, legs behind the body.
    look = Image.new("RGBA", body.size, (234, 240, 233, 255))
    for name in ["tail", "back_accessories", "foot_L_image", "foot_R_image", "body", "head", "paw_L_image", "paw_R_image"]:
        look.alpha_composite(Image.open(OUT / f"{name}.png").convert("RGBA"))
    look.save(OUT / "assembled-split.png")
    # Rebuild the rigs from these parts, reusing the cached weapon/palm renders.
    rig.HERO = OUT
    sys.argv = [sys.argv[0], "--no-render"]
    rig.main()
    anim.main()


if __name__ == "__main__":
    main()
