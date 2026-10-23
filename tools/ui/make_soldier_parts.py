"""Cut a cat soldier (make_units.cat_soldier) into animation layers for a skeletal rig.

Same split as the lobby cats (game/assets/lobby/cardboard/cats): the two feet are the bottom
lobes of the body, cut at y184-204 so the body keeps its hips. Clothes go with the body,
headgear with the head, the weapon is its own layer held by the right paw.

Writes, per soldier, a folder of 256x240 SVGs plus tightly-cropped PNGs and parts.json
(each PNG's box in the 256x240 frame, y down):
    python -I tools/ui/make_soldier_parts.py [soldier_id ...]   (default: kiem)
Output: docs/design/2026-10-23/soldier-rig/<id>/
"""
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import make_svgs as base
import make_units as U
from make_svgs import CAT_BODY, CAT_HEAD, svg

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "design" / "2026-10-23" / "soldier-rig"
GODOT = r"C:\Users\dangp\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe"

FOOT_L = "M44 204 Q43 232 72 232 Q100 234 111 221 L123 204 L123 184 L56 184 Z"
FOOT_R = "M145 221 Q156 234 184 232 Q213 232 212 204 L200 184 L133 184 L133 204 Z"
BODY_NO_FEET = ("M76 116 L180 116 Q206 116 208 150 L212 204 L145 204 L145 221 Q128 206 111 221 "
                "L111 204 L44 204 L48 150 Q50 116 76 116 Z")
# Clip boxes are generous rectangles: the outline stroke (12px) straddles each path.
FULL = "M-40 -40 L296 -40 L296 280 L-40 280 Z"

def layers(soldier_id):
    tid, klass, rarity, weapon_name = next(s for s in U.SOLDIERS if s[0] == soldier_id)
    kind = U.COAT[klass]
    trim = U.TRIM[rarity]
    back, body, head = U.cat_parts(kind)
    clips = (f'<clipPath id="head"><path d="{CAT_HEAD}"/></clipPath><clipPath id="body"><path d="{CAT_BODY}"/></clipPath>'
             f'<clipPath id="foot_l"><path d="{FOOT_L}"/></clipPath><clipPath id="foot_r"><path d="{FOOT_R}"/></clipPath>'
             # Body keeps everything above the foot cut; the outline under the cut belongs to the feet.
             f'<clipPath id="no_feet"><path d="M-40 -40 L296 -40 L296 204 L145 204 L145 260 L111 260 L111 204 L-40 204 Z"/></clipPath>'
             f'<clipPath id="feet_l"><path d="M-40 184 L123 184 L123 280 L-40 280 Z"/></clipPath>'
             f'<clipPath id="feet_r"><path d="M133 184 L296 184 L296 280 L133 280 Z"/></clipPath>')
    torso = body + U.outfit(klass, trim)
    cape = U.cape("#ffd23f") if rarity == 3 else ""
    wdefs, wbody = U.weapon(weapon_name, 130, 54, 1.0, "w")
    out = {
        "tail": back,
        "cape": cape,
        # Feet: the body's two bottom lobes (with their outline), cut where the hips start.
        "foot_l": f'<g clip-path="url(#feet_l)">{body}</g>',
        "foot_r": f'<g clip-path="url(#feet_r)">{body}</g>',
        "body": f'<g clip-path="url(#no_feet)">{torso}</g>',
        "paw_l": U.stroke_path(U.L_PAW),
        "head": head + U.headgear(klass, trim),
        "weapon": wbody,
        "paw_r": U.stroke_path(U.R_PAW),
    }
    return {k: v for k, v in out.items() if v}, clips + wdefs

# Draw order back to front, and each part's pivot in the 256x240 frame (y down).
ORDER = ["tail", "cape", "foot_l", "foot_r", "body", "paw_l", "head", "weapon", "paw_r"]
PIVOT = {"tail": (186, 206), "cape": (128, 130), "foot_l": (84, 196), "foot_r": (172, 196),
         "body": (128, 200), "paw_l": (104, 152), "head": (128, 140), "weapon": (156, 168), "paw_r": (152, 152)}

def main(ids):
    from PIL import Image
    for sid in ids:
        folder = OUT / sid
        (folder / "svg").mkdir(parents=True, exist_ok=True)
        (folder / "images").mkdir(parents=True, exist_ok=True)
        parts, defs = layers(sid)
        for name, body in parts.items():
            (folder / "svg" / f"{name}.svg").write_text(svg(256, 240, body, defs), encoding="utf-8")
        (folder / "svg" / "assembled.svg").write_text(svg(256, 240, "".join(parts[n] for n in ORDER if n in parts), defs), encoding="utf-8")
        # Render at 2x with the game's own SVG renderer, then crop each layer to its pixels.
        rendered = folder / "render"
        rendered.mkdir(exist_ok=True)
        boxes = {}
        for name in [n for n in ORDER if n in parts] + ["assembled"]:
            png = rendered / f"{name}.png"
            subprocess.run([GODOT, "--headless", "--path", str(ROOT), "--script", "res://tools/ui/render_svg_png.gd", "--",
                            str(folder / "svg" / f"{name}.svg").replace("\\", "/"), str(png).replace("\\", "/")],
                           check=True, capture_output=True)
            if name == "assembled":
                continue
            im = Image.open(png).convert("RGBA")
            k = im.width / 256
            box = im.getbbox()
            im.crop(box).save(folder / "images" / f"{name}.png")
            boxes[name] = {"x": box[0] / k, "y": box[1] / k, "w": (box[2] - box[0]) / k, "h": (box[3] - box[1]) / k,
                           "pivot": PIVOT[name], "scale": 1 / k}
        (folder / "parts.json").write_text(json.dumps({"soldier": sid, "frame": [256, 240], "order": [n for n in ORDER if n in parts],
                                                       "parts": boxes}, indent=1), encoding="utf-8")
        print(sid, "->", folder, len(boxes), "layers")

if __name__ == "__main__":
    main(sys.argv[1:] or ["kiem"])
