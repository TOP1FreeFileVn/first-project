"""Give every cat soldier its own cat's coat (game/data/Cats.gd: Mướp tabby, Tro grey, Tam calico,
Bơ cream) instead of its class's, keeping its class outfit, rarity trim and approved weapon.

    python -I tools/ui/recoat_cats.py [troop_id ...]      (default: all 16)

For each troop:
  1. the unarmed cat is redrawn with make_units.cat_soldier(coat of its cat) -> SVG, rendered
     at 3x by Godot (as docs/design/2026-10-19/weapon-rollout/sources did);
  2. the approved held weapon is composed on it exactly like build_review.compose (same
     cleaned weapon PNG, same pose) -> game/ui/art/unit_<id>.png (menu portrait);
  3. the battle rig is rebuilt by make_cat_rigs with the same coat -> game/assets/units/<id>/.
"""
import importlib.util
import math
import re
import subprocess
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import make_units as U
import make_cat_rigs as rigs

ROOT = Path(__file__).resolve().parents[2]
ROLLOUT = ROOT / "docs/design/2026-10-19/weapon-rollout"
SPEAR = ROOT / "docs/design/2026-10-20/spear-stroke-sample"
WORK = ROOT / "docs/design/2026-10-24/cat-coats"
ART = ROOT / "game/ui/art"
GODOT = r"C:\Users\dangp\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe"

COATS = {"muop": "tabby", "tro": "grey", "tam": "calico", "bo": "cream"}


def versions():
    """troop id -> cat, read from game/data/Cats.gd so the table lives in one place."""
    text = (ROOT / "game/data/Cats.gd").read_text(encoding="utf-8")
    block = text[text.index("const VERSIONS"):]
    block = block[:block.index("}")]
    out = {}
    for cat, ids in re.findall(r'"(\w+)":\s*\[([^\]]*)\]', block):
        for tid in re.findall(r'"(\w+)"', ids):
            out[tid] = cat
    return out


def normalize(text):
    """The rollout sources use a 9 px main line (31 px under the tail): same as build_sources."""
    def fix(m):
        width = float(m.group(1))
        return f'stroke="#583f21" stroke-width="{31.0 if width == 30.0 else 9.0}"'
    return re.sub(r'stroke="#583f21" stroke-width="([0-9.]+)"', fix, text)


def render(svg_path, png_path, scale):
    subprocess.run([GODOT, "--headless", "--path", str(ROOT), "--script", "res://tools/ui/render_svg_png.gd", "--",
                    svg_path.as_posix(), png_path.as_posix(), str(scale)], check=True, capture_output=True)


def unarmed(tid, coat, klass, rarity):
    old = U.weapon
    U.weapon = lambda *a, **k: ("", "")
    try:
        text = normalize(U.cat_soldier(coat, klass, rarity, tid))
    finally:
        U.weapon = old
    svg = WORK / f"cat_{tid}.svg"
    svg.write_text(text, encoding="utf-8")
    png = WORK / f"cat_{tid}.png"
    render(svg, png, 3)
    return Image.open(png).convert("RGBA")


def held(tid, cat):
    """build_review.compose with the recoated cat underneath; giao keeps its approved spear layer."""
    spec = importlib.util.spec_from_file_location("rollout", ROLLOUT / "build_review.py")
    lib = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(lib)
    if tid == "giao":
        cat.alpha_composite(Image.open(SPEAR / "processed/spear-held-layer.png").convert("RGBA"))
        cat.alpha_composite(Image.open(ROLLOUT / "sources/front-paw.png").convert("RGBA"))
        return cat
    pose = lib.POSES[tid]
    im = Image.open(ROLLOUT / "processed" / f"{tid}.png").convert("RGBA")
    ratio = pose["scale"] * 3
    angle = pose["angle"]
    pad = 128
    scaled = im.resize((round(im.width * ratio), round(im.height * ratio)), Image.Resampling.LANCZOS)
    grip = [(v + pad) * ratio for v in pose["grip"]]
    rot = scaled.rotate(angle, Image.Resampling.BICUBIC, expand=True)
    dx, dy = grip[0] - scaled.width / 2, grip[1] - scaled.height / 2
    theta = math.radians(angle)
    gx = math.cos(theta) * dx + math.sin(theta) * dy + rot.width / 2
    gy = -math.sin(theta) * dx + math.cos(theta) * dy + rot.height / 2
    x, y = round(pose["paw"][0] * 3 - gx), round(pose["paw"][1] * 3 - gy)
    cat.alpha_composite(rot, (x, y))
    cat.alpha_composite(Image.open(ROLLOUT / "sources/front-paw.png").convert("RGBA"))
    return cat


def main(ids):
    WORK.mkdir(parents=True, exist_ok=True)
    owner = versions()
    soldiers = {tid: (klass, rarity, wname) for tid, klass, rarity, wname in U.SOLDIERS}
    # Troops already in their cat's coat keep their approved art untouched.
    for tid in ids or [t for t in soldiers if U.COAT[soldiers[t][0]] != COATS[owner[t]]]:
        klass, rarity, wname = soldiers[tid]
        coat = COATS[owner[tid]]
        print(tid, "->", owner[tid], coat)
        cat = unarmed(tid, coat, klass, rarity)
        portrait = held(tid, cat)
        if portrait is not None:
            portrait.save(WORK / f"unit_{tid}.png")
            portrait.save(ART / f"unit_{tid}.png")
        rigs.build(tid, (coat, klass, rarity, wname, False))


if __name__ == "__main__":
    main(sys.argv[1:])
