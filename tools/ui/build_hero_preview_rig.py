"""Retarget the accepted ginger equipment cat to the game's small Spine runtime.

Uses the already separated 9 px hero artwork, the existing 1.2 s idle tracks and
the accepted held weapon/palm layers. No art is redrawn and stat-only equipment
never changes the costume. Feet stay on root, while head, tail and paws remain
independent bones. Outputs game/assets/hero/<family>/<family>.{json,atlas,png}.

Run from the repository root: python tools/ui/build_hero_preview_rig.py
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import math
import subprocess
import xml.etree.ElementTree as ET
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "game/assets/hero"
WORK = ROOT / "output/hero-preview-rig"
GODOT = Path("C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe")
PARTS = ROOT / "docs/design/2026-10-20/cat-spine-parts"
HERO = PARTS / "png/hero_neutral_9px"
CANVAS = ROOT / "docs/design/2026-10-22/hero-weapons-canvas"
INTEGRATION = ROOT / "docs/design/2026-10-23/hero-equipment-integration"
V4 = ROOT / "docs/design/2026-10-20/hero-equipment-v4/processed"
IDLE_SOURCE = ROOT / "docs/design/2026-10-23/cat-rigs/hero_valor/spine/hero_valor.json"
SCALE = 3
GROUND = (128, 240)
NS = "http://www.w3.org/2000/svg"
ET.register_namespace("", NS)

FAMILIES = {
    "bare": {"item": "", "hand": None, "production": "bare"},
    "melee": {"item": "kiem_go", "hand": "right", "production": "melee"},
    "ranged": {"item": "cung_san", "hand": "left", "slug": "bow", "production": "ranged"},
    "magic": {"item": "gay_sao", "hand": "right", "slug": "staff", "production": "magic"},
    "heavy": {"item": "riu_lua", "hand": "right", "slug": "axe", "production": "heavy"},
    "katana": {"item": "katana_nguyet", "hand": "right", "slug": "katana", "production": "katana"},
}
PART_NAMES = {
    "tail": "tail", "cape": "back_accessories", "leg_l": "foot_L_image",
    "leg_r": "foot_R_image", "body": "body", "head": "head",
    "paw_l": "paw_L_image", "paw_r": "paw_R_image",
}
PIVOTS = {
    "hip": (128, 176), "body": (128, 176), "cape": (128, 128),
    "tail": (182, 210), "head": (128, 121), "leg_l": (82, 203),
    "leg_r": (174, 203), "paw_l": (94, 166), "paw_r": (162, 166),
}


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def skel(point: tuple[float, float]) -> tuple[float, float]:
    return point[0] - GROUND[0], GROUND[1] - point[1]


def open_part(path: Path) -> Image.Image:
    image = Image.open(path).convert("RGBA")
    if image.size != (768, 720):
        raise ValueError(f"Unregistered source part: {path} {image.size}")
    return image


def render(svg: Path, png: Path, no_render: bool) -> Image.Image:
    if not no_render:
        result = subprocess.run([
            str(GODOT), "--headless", "--path", str(ROOT), "--script",
            "res://tools/ui/render_svg_png.gd", "--", str(svg), str(png), "3",
        ], capture_output=True, text=True, check=True)
        (png.with_suffix(".log")).write_text(result.stdout + result.stderr, encoding="utf-8")
    if not png.is_file():
        raise FileNotFoundError(f"Cached native render missing: {png}")
    return open_part(png)


def weapon_parts(family: str, spec: dict, no_render: bool):
    """Return independent unchanged weapon + local fur occlusion images."""
    if family == "bare":
        return {}, []
    if family == "melee":
        source = V4 / "melee-weapon-layer.png"
        mask_path = V4 / "right-palm-mask.png"
        mask = Image.open(mask_path).convert("L")
        palm = Image.new("RGBA", (768, 720), "#f5a25d")
        palm.putalpha(mask)
        return {"weapon": open_part(source), "palm": palm}, [source, mask_path]

    slug = spec["slug"]
    held_path = CANVAS / f"svg/{slug}-held-layer.svg"
    full_path = (CANVAS / "svg/hero-axe-768.svg" if slug == "axe" else
                 INTEGRATION / f"svg/hero-{slug}-768.svg")
    full = ET.parse(full_path).getroot()
    # The authoring exporter appends the unchanged palm and two C-shaped paws.
    # Extract that exact authored palm, rather than redrawing or approximating it.
    palm_path = list(full)[-3]
    if palm_path.attrib.get("fill") != "#f5a25d" or "C" not in palm_path.attrib.get("d", ""):
        raise ValueError(f"Held SVG no longer has its expected local palm: {full_path}")
    folder = WORK / family
    folder.mkdir(parents=True, exist_ok=True)
    palm_svg = ET.Element(f"{{{NS}}}svg", {"width": "256", "height": "240", "viewBox": "0 0 256 240"})
    palm_svg.append(copy.deepcopy(palm_path))
    palm_input = folder / "palm.svg"
    ET.ElementTree(palm_svg).write(palm_input, encoding="utf-8", xml_declaration=True)
    weapon = render(held_path, folder / "weapon.png", no_render)
    palm = render(palm_input, folder / "palm.png", no_render)
    return {"weapon": weapon, "palm": palm}, [held_path, full_path]


def pack(images: dict[str, Image.Image], name: str, folder: Path):
    width, pad = 2048, 3
    x = y = shelf = 0
    locations = {}
    for key in sorted(images, key=lambda key: -images[key].height):
        image = images[key]
        if x + image.width + pad > width:
            x, y, shelf = 0, y + shelf + pad, 0
        locations[key] = (x, y)
        x += image.width + pad
        shelf = max(shelf, image.height)
    page = Image.new("RGBA", (width, y + shelf))
    lines = [f"{name}.png", f"size:{width},{page.height}", "filter:Linear,Linear", ""]
    for key, (x, y) in locations.items():
        image = images[key]
        # Paste, without using alpha as a second mask, preserves edge coverage.
        page.paste(image, (x, y))
        lines.extend([key, f"bounds:{x},{y},{image.width},{image.height}", ""])
    page.save(folder / f"{name}.png")
    (folder / f"{name}.atlas").write_text("\n".join(lines) + "\n", encoding="utf-8")
    return locations, page.size


def sample(track: list, t: float, default: dict) -> dict:
    if not track:
        return default
    previous = track[0]
    if t <= previous.get("time", 0):
        return previous
    for following in track[1:]:
        t0, t1 = previous.get("time", 0), following.get("time", 0)
        if t <= t1:
            u = (t - t0) / max(t1 - t0, 0.0001)
            return {k: previous.get(k, default[k]) * (1 - u) + following.get(k, default[k]) * u for k in default}
        previous = following
    return previous


def multiply(a, b):
    return (
        a[0]*b[0]+a[2]*b[1], a[1]*b[0]+a[3]*b[1],
        a[0]*b[2]+a[2]*b[3], a[1]*b[2]+a[3]*b[3],
        a[0]*b[4]+a[2]*b[5]+a[4], a[1]*b[4]+a[3]*b[5]+a[5],
    )


def sampled_bounds(skeleton: dict, times: list[float], animated: bool):
    """Conservative region-rectangle extents, matching SoldierRig's transform math."""
    low_x = low_y = math.inf
    high_x = high_y = -math.inf
    attach = skeleton["skins"][0]["attachments"]
    for t in times:
        world = {}
        for bone in skeleton["bones"]:
            timeline = skeleton["animations"]["idle"]["bones"].get(bone["name"], {}) if animated else {}
            tr = sample(timeline.get("translate", []), t, {"x": 0, "y": 0})
            sc = sample(timeline.get("scale", []), t, {"x": 1, "y": 1})
            rotation = -math.radians(sample(timeline.get("rotate", []), t, {"value": 0})["value"])
            c, s = math.cos(rotation), math.sin(rotation)
            matrix = (c*sc["x"], s*sc["x"], -s*sc["y"], c*sc["y"],
                      bone.get("x", 0)+tr["x"], -(bone.get("y", 0)+tr["y"]))
            world[bone["name"]] = multiply(world[bone["parent"]], matrix) if "parent" in bone else matrix
        for slot in skeleton["slots"]:
            item = attach[slot["name"]][slot["attachment"]]
            w, h = item["width"]*item["scaleX"], item["height"]*item["scaleY"]
            cx, cy = item["x"], -item["y"]
            m = world[slot["bone"]]
            for px, py in ((cx-w/2, cy-h/2), (cx+w/2, cy-h/2), (cx+w/2, cy+h/2), (cx-w/2, cy+h/2)):
                x, y = m[0]*px+m[2]*py+m[4], m[1]*px+m[3]*py+m[5]
                low_x, low_y = min(low_x, x), min(low_y, y)
                high_x, high_y = max(high_x, x), max(high_y, y)
    return [round(v, 4) for v in (low_x, low_y, high_x, high_y)]


def build(family: str, spec: dict, no_render: bool) -> dict:
    folder = OUT / family
    folder.mkdir(parents=True, exist_ok=True)
    layers = {name: open_part(HERO / f"{original}.png") for name, original in PART_NAMES.items()}
    weapon, weapon_sources = weapon_parts(family, spec, no_render)
    layers.update(weapon)
    order = ["tail", "cape", "leg_l", "leg_r", "body", "head"]
    if weapon:
        order += ["weapon", "palm"]
    order += ["paw_l", "paw_r"]
    pivots = dict(PIVOTS)
    if weapon:
        pivots["weapon"] = (94, 166) if spec["hand"] == "left" else (160, 166)
    parents = {"hip": "root", "body": "hip", "cape": "body", "tail": "body", "head": "body",
               "paw_l": "body", "paw_r": "body", "leg_l": "root", "leg_r": "root"}
    if weapon:
        parents["weapon"] = "paw_l" if spec["hand"] == "left" else "paw_r"
    bones = [{"name": "root"}]
    world = {"root": (0, 0)}
    for name in ["hip", "body", "cape", "tail", "head", "paw_l", "paw_r", "leg_l", "leg_r", "weapon"]:
        if name not in pivots:
            continue
        wx, wy = skel(pivots[name])
        parent = parents[name]
        px, py = world[parent]
        bones.append({"name": name, "parent": parent, "x": wx-px, "y": wy-py})
        world[name] = (wx, wy)

    crops, boxes = {}, {}
    for name in order:
        box = layers[name].getbbox()
        if box is None:
            raise ValueError(f"Empty attachment: {family}/{name}")
        crops[name], boxes[name] = layers[name].crop(box), box
    locations, page_size = pack(crops, family, folder)
    slots, attachments = [], {}
    for name in order:
        bone = "weapon" if name == "palm" else name
        image, box = crops[name], boxes[name]
        cx, cy = skel(((box[0]+box[2])/2/SCALE, (box[1]+box[3])/2/SCALE))
        bx, by = world[bone]
        slots.append({"name": name, "bone": bone, "attachment": name})
        attachments[name] = {name: {"x": cx-bx, "y": cy-by, "scaleX": 1/SCALE, "scaleY": 1/SCALE,
                                   "width": image.width, "height": image.height}}
    original = json.loads(IDLE_SOURCE.read_text("utf-8"))["animations"]["idle"]
    idle = copy.deepcopy(original)
    if spec["hand"] == "left":
        idle["bones"]["paw_l"] = idle["bones"].pop("paw_r")
    skeleton = {
        "skeleton": {"spine": "4.2.0", "x": -128, "y": 0, "width": 256, "height": 240, "images": "./"},
        "bones": bones, "slots": slots, "skins": [{"name": "default", "attachments": attachments}],
        "animations": {"idle": idle},
    }
    (folder / f"{family}.json").write_text(json.dumps(skeleton, ensure_ascii=False, indent=1)+"\n", encoding="utf-8")
    setup = sampled_bounds(skeleton, [0], False)
    motion = sampled_bounds(skeleton, [i/120 for i in range(145)], True)
    assembly = Image.new("RGBA", (768, 720))
    for name in order:
        assembly.alpha_composite(layers[name])
    local_work = WORK / family
    local_work.mkdir(parents=True, exist_ok=True)
    assembly.save(local_work / "setup.png")
    sources = [HERO / f"{original}.png" for original in PART_NAMES.values()] + weapon_sources
    regions = {name: {"bone": "weapon" if name == "palm" else name, "source_alpha_box_3x": list(boxes[name]),
                      "atlas_bounds": [*locations[name], *crops[name].size]} for name in order}
    return {
        "equipped_item": spec["item"], "hand": spec["hand"],
        "skeleton": rel(folder / f"{family}.json"), "atlas_size": list(page_size),
        "setup_bounds_godot": setup, "idle_bounds_godot": motion,
        "bounds_format": "min_x,min_y,max_x,max_y in Godot Y-down coordinates at feet origin",
        "slots_back_to_front": order, "regions": regions,
        "weapon_socket_canvas": list(pivots["weapon"]) if weapon else None,
        "sources": [{"path": rel(source), "sha256": sha(source)} for source in sources],
        "production_static_reference": f"game/ui/art/hero_cat_{spec['production']}.png",
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--no-render", action="store_true", help="reuse previously native-rendered weapon/palm PNGs")
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = {
        "revision": "2026-10-24-ginger-equipment-idle", "canvas": [256, 240], "render_scale": SCALE,
        "origin_canvas": list(GROUND), "design_rect_godot": [-128, -240, 256, 240],
        "identity": "Original approved ginger equipment hero; 9px source ink, blue cape, original front-facing face.",
        "animation_source": {"path": rel(IDLE_SOURCE), "sha256": sha(IDLE_SOURCE), "clip": "idle", "duration": 1.2},
        "retarget": "Original hip breathing, head lift, tail swing and held-paw rotation tracks; ranged retargets right-paw track to left-paw. Feet remain static children of root.",
        "appearance_rule": "Only the held weapon changes; helmet, armor and boots affect stats/icons only. No backdrop, circular halo or platform is part of these assets.",
        "source_parts_manifest": rel(PARTS / "manifest.json"), "families": {},
    }
    for family, spec in FAMILIES.items():
        manifest["families"][family] = build(family, spec, args.no_render)
        print(f"Built {family}: setup={manifest['families'][family]['setup_bounds_godot']} idle={manifest['families'][family]['idle_bounds_godot']}", flush=True)
    (OUT / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    print("HERO_PREVIEW_RIG_BUILD_COMPLETE families=6 duration=1.2")


if __name__ == "__main__":
    main()
