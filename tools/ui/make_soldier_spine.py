"""Build a Spine skeleton (JSON 4.2 + atlas + page PNG) for a cat soldier drawn as separate
rig parts, with `run` and `idle` animations.

    python -I tools/ui/make_soldier_spine.py [rig_folder] [name]
Default rig folder: docs/design/2026-10-23/soldier-rig-v2 (cat.js parts exported to svg/,
pivots and draw order in rig.json). Each part SVG is rendered at 2x with the game's renderer,
cropped and packed. Writes <rig_folder>/spine/<name>.{json,atlas,png}.

Skeleton space is Spine's: units are the 256x240 frame's pixels, Y up, origin on the ground
under the cat (frame point 128, 232). The rig follows the Cat Gunner sample's idea (one body
bone that bobs, tail and head on it); the legs are separate parts behind the body with their
own bones, so they step without cutting the coat. The cat faces the viewer, so "run" is a
quick bouncing trot: legs lift in turn, body sways, paws swing, tail flicks.
"""
import json
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
DEFAULT = ROOT / "docs" / "design" / "2026-10-23" / "soldier-rig-v2"
GODOT = r"C:\Users\dangp\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe"
GROUND = (128, 232)
RENDER_SCALE = 2

def to_skel(x, y):
    return x - GROUND[0], GROUND[1] - y

# Bone parents; pivots come from rig.json (frame coords, y down). "hip" shares body's pivot.
PARENT = {"hip": "root", "body": "hip", "cape": "body", "tail": "body", "head": "body", "paw_l": "body", "paw_r": "body",
          "weapon": "paw_r", "leg_l": "root", "leg_r": "root"}

def keys(times, **channels):
    """[{time, ...}] from parallel lists; time 0 is left implicit (Spine's default)."""
    out = []
    for i, t in enumerate(times):
        k = {} if t == 0 else {"time": round(t, 4)}
        for name, values in channels.items():
            k[name] = values[i]
        out.append(k)
    return out

def run_animation():
    T = [0, 0.11, 0.22, 0.33, 0.44]   # one stride = two steps, 0.44 s
    return {"bones": {
        # Two bounces per stride: down on each foot contact, up in between.
        "hip": {"translate": keys(T, x=[0, 0, 0, 0, 0], y=[0, 8, 0, 8, 0]),
                "scale": keys(T, x=[1.04, 0.97, 1.04, 0.97, 1.04], y=[0.95, 1.03, 0.95, 1.03, 0.95])},
        "body": {"rotate": keys(T, value=[0, 4, 0, -4, 0])},
        "head": {"rotate": keys(T, value=[0, -3, 0, 3, 0]),
                 "translate": keys(T, x=[0, 0, 0, 0, 0], y=[-2, 2, -2, 2, -2])},
        "tail": {"rotate": keys(T, value=[0, 16, 0, -16, 0])},
        "paw_l": {"rotate": keys(T, value=[0, -24, 0, 24, 0])},
        "paw_r": {"rotate": keys(T, value=[0, 14, 0, -14, 0])},
        "weapon": {"rotate": keys(T, value=[0, -6, 0, 6, 0])},
        # Legs step in turn: each lifts while the body rides up on the other.
        "leg_l": {"translate": keys(T, x=[0, -2, 0, 0, 0], y=[0, 14, 0, 0, 0]),
                  "rotate": keys(T, value=[0, -8, 0, 0, 0])},
        "leg_r": {"translate": keys(T, x=[0, 0, 0, 2, 0], y=[0, 0, 0, 14, 0]),
                  "rotate": keys(T, value=[0, 0, 0, 8, 0])},
    }}

def attack_animation():
    """A sword slash: wind up (raise the sword back), strike down across, recover. 0.5 s.
    An `hit` event marks the frame the blade lands, so the game can deal damage there."""
    T = [0, 0.14, 0.22, 0.3, 0.5]
    return {"bones": {
        # Crouch on the wind-up, spring up and lean into the strike.
        "hip": {"translate": keys(T, x=[0, -2, 4, 3, 0], y=[0, -4, 4, 2, 0]),
                "scale": keys(T, x=[1, 1.06, 0.96, 1.0, 1], y=[1, 0.93, 1.05, 1.0, 1])},
        "body": {"rotate": keys(T, value=[0, 8, -10, -8, 0])},
        "head": {"rotate": keys(T, value=[0, 4, -6, -5, 0])},
        # The right paw carries the sword: back over the shoulder, then a big arc down.
        "paw_r": {"rotate": keys(T, value=[0, 70, -60, -50, 0]),
                  "translate": keys(T, x=[0, -6, 10, 8, 0], y=[0, 18, -6, -4, 0])},
        "weapon": {"rotate": keys(T, value=[0, 25, -20, -15, 0])},
        "paw_l": {"rotate": keys(T, value=[0, -20, 20, 14, 0])},
        "tail": {"rotate": keys(T, value=[0, 20, -18, -10, 0])},
    }}, [{"time": 0.22, "name": "hit"}]

def shoot_animation():
    """Ranged: aim (weapon raised and drawn back), release with a recoil, settle. 0.5 s."""
    T = [0, 0.16, 0.2, 0.3, 0.5]
    return {"bones": {
        "hip": {"translate": keys(T, x=[0, -2, 2, 1, 0], y=[0, -2, 1, 0, 0])},
        "body": {"rotate": keys(T, value=[0, 5, -4, -2, 0])},
        "head": {"rotate": keys(T, value=[0, 3, -2, -1, 0])},
        "paw_r": {"rotate": keys(T, value=[0, 30, -12, -6, 0]), "translate": keys(T, x=[0, -8, 6, 3, 0], y=[0, 6, -2, -1, 0])},
        "weapon": {"rotate": keys(T, value=[0, 10, -8, -4, 0])},
        "paw_l": {"rotate": keys(T, value=[0, -16, 8, 4, 0])},
        "tail": {"rotate": keys(T, value=[0, 12, -14, -6, 0])},
    }}, [{"time": 0.2, "name": "hit"}]

def cast_animation():
    """Magic: raise the staff/book high, thrust it forward to cast, lower it. 0.5 s."""
    T = [0, 0.18, 0.26, 0.34, 0.5]
    return {"bones": {
        "hip": {"translate": keys(T, x=[0, 0, 2, 1, 0], y=[0, 6, 2, 1, 0]),
                "scale": keys(T, x=[1, 0.97, 1.03, 1.0, 1], y=[1, 1.05, 0.97, 1.0, 1])},
        "body": {"rotate": keys(T, value=[0, 3, -5, -3, 0])},
        "head": {"rotate": keys(T, value=[0, -4, 3, 2, 0])},
        "paw_r": {"rotate": keys(T, value=[0, 40, -24, -14, 0]), "translate": keys(T, x=[0, -2, 8, 5, 0], y=[0, 20, 4, 2, 0])},
        "weapon": {"rotate": keys(T, value=[0, 14, -10, -6, 0])},
        "paw_l": {"rotate": keys(T, value=[0, -30, 10, 6, 0]), "translate": keys(T, x=[0, 0, 0, 0, 0], y=[0, 10, 2, 1, 0])},
        "tail": {"rotate": keys(T, value=[0, 14, -12, -6, 0])},
    }}, [{"time": 0.26, "name": "hit"}]

ATTACKS = {"slash": attack_animation, "shoot": shoot_animation, "cast": cast_animation}

def idle_animation():
    T = [0, 0.6, 1.2]
    return {"bones": {
        "hip": {"scale": keys(T, x=[1, 1.02, 1], y=[1, 1.035, 1])},
        "head": {"translate": keys(T, x=[0, 0, 0], y=[0, 2, 0])},
        "tail": {"rotate": keys([0, 0.3, 0.6, 0.9, 1.2], value=[0, 10, 0, -10, 0])},
        "paw_r": {"rotate": keys(T, value=[0, -4, 0])},
    }}

def render_parts(folder, order):
    """Render each part SVG with Godot and crop it: {name: (image, box in render px)}."""
    out = {}
    (folder / "render").mkdir(exist_ok=True)
    for n in order:
        png = folder / "render" / f"{n}.png"
        subprocess.run([GODOT, "--headless", "--path", str(ROOT), "--script", "res://tools/ui/render_svg_png.gd", "--",
                        (folder / "svg" / f"{n}.svg").as_posix(), png.as_posix(), str(RENDER_SCALE)],
                       check=True, capture_output=True)
        im = Image.open(png).convert("RGBA")
        box = im.getbbox()
        out[n] = (im.crop(box), box)
    return out

def pack(images, name, out):
    pad, page_w = 2, 1024
    x = y = shelf = 0
    place = {}
    for n in sorted(images, key=lambda k: -images[k].height):
        im = images[n]
        if x + im.width + pad > page_w:
            x, y, shelf = 0, y + shelf + pad, 0
        place[n] = (x, y)
        x += im.width + pad
        shelf = max(shelf, im.height)
    page = Image.new("RGBA", (page_w, y + shelf))
    for n, (px, py) in place.items():
        page.paste(images[n], (px, py))
    page.save(out / f"{name}.png")
    atlas = [f"{name}.png", f"size:{page_w},{page.height}", "filter:Linear,Linear", ""]
    for n, (px, py) in place.items():
        atlas[-1:] = [n, f"bounds:{px},{py},{images[n].width},{images[n].height}", ""]
    (out / f"{name}.atlas").write_text("\n".join(atlas) + "\n", encoding="utf-8")
    return page.size

def main(folder, name, style="slash"):
    rig = json.loads((folder / "rig.json").read_text(encoding="utf-8"))
    order, pivots = rig["order"], {k: tuple(v) for k, v in rig["pivots"].items()}
    pivots["hip"] = pivots["body"]
    out = folder / "spine"
    out.mkdir(exist_ok=True)
    parts = render_parts(folder, order)
    page = pack({n: im for n, (im, _) in parts.items()}, name, out)

    world = {"root": (0, 0)}
    bones = [{"name": "root"}]
    for b in ["hip", "body", "cape", "tail", "head", "paw_l", "paw_r", "weapon", "leg_l", "leg_r"]:
        if b not in pivots:
            continue
        wx, wy = to_skel(*pivots[b])
        world[b] = (wx, wy)
        parent = PARENT[b] if PARENT[b] in world else "body"   # e.g. a weapon with no paw to hold it
        px, py = world[parent]
        bones.append({"name": b, "parent": parent, "x": round(wx - px, 2), "y": round(wy - py, 2)})

    # Images are RENDER_SCALE renders: scale attachments down so skeleton units stay frame pixels.
    k = 1 / RENDER_SCALE
    slots, attachments = [], {}
    for n in order:
        im, box = parts[n]
        cx, cy = to_skel((box[0] + box[2]) / 2 * k, (box[1] + box[3]) / 2 * k)
        bx, by = world[n]
        slots.append({"name": n, "bone": n, "attachment": n})
        attachments[n] = {n: {"x": round(cx - bx, 2), "y": round(cy - by, 2), "scaleX": k, "scaleY": k,
                              "width": im.width, "height": im.height}}

    skeleton = {
        "skeleton": {"spine": "4.2.0", "x": -128, "y": -8, "width": 256, "height": 240, "images": "./", "audio": ""},
        "bones": bones, "slots": slots,
        "skins": [{"name": "default", "attachments": attachments}],
        "events": {"hit": {}},
        "animations": {"run": run_animation(), "idle": idle_animation()},
    }
    attack, events = ATTACKS[style]()
    attack["events"] = events
    skeleton["animations"]["attack"] = attack
    # Shared animations key every soldier bone; drop timelines for bones this rig lacks
    # (no tail on a monster, no paws on the mushroom).
    names = {b["name"] for b in bones}
    for anim in skeleton["animations"].values():
        anim["bones"] = {b: tl for b, tl in anim["bones"].items() if b in names}
    (out / f"{name}.json").write_text(json.dumps(skeleton, indent=1), encoding="utf-8")
    print(out / f"{name}.json", f"{len(bones)} bones, {len(slots)} slots, page {page[0]}x{page[1]}")

if __name__ == "__main__":
    main(Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT, sys.argv[2] if len(sys.argv) > 2 else "soldier_kiem",
         sys.argv[3] if len(sys.argv) > 3 else "slash")
