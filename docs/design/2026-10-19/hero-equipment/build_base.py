"""Extract the native hero into fixed 9 px review layers, without editing production.

Run from any working directory:
    python -X utf8 -B docs/design/2026-10-19/hero-equipment/build_base.py --render

Every SVG/PNG keeps the full 256x240/768x720 registration canvas. ``hero-base``
contains body + head but no paws, helmet or sword; the paws are a separate layer.
"""

from __future__ import annotations

import argparse
import copy
import importlib.util
import json
import subprocess
import xml.etree.ElementTree as ET
from pathlib import Path


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
OUT = HERE / "sources"
NS = "http://www.w3.org/2000/svg"
ET.register_namespace("", NS)
LINE = "#583f21"
GINGER = "#f5a25d"
GODOT = Path("C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe")


def tag(name: str) -> str:
    return f"{{{NS}}}{name}"


def native_module():
    spec = importlib.util.spec_from_file_location("native_hero_svg", ROOT / "tools/ui/make_svgs.py")
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def normalise(element: ET.Element) -> ET.Element:
    out = copy.deepcopy(element)
    for node in out.iter():
        if node.get("stroke", "").lower() == LINE:
            width = float(node.get("stroke-width", "0"))
            # Leave the 6 px cape clasps as deliberate interior details.
            if width in (12, 13):
                node.set("stroke-width", "9")
            elif width == 30:
                # Understroke minus the preserved 13 px coat stroke gives 9 px per edge.
                node.set("stroke-width", "31")
    return out


def restored_ears() -> list[ET.Element]:
    # The exact regular-cat ear construction from native cat_svg(), recolored ginger.
    # Bases are behind the native wide head; do not translate the ears outward.
    out = []
    for side in (1, -1):
        def x(v: int) -> int:
            return 128 + side * (v - 128)
        out.append(ET.Element(tag("path"), {
            "d": f"M{x(46)} 90 Q{x(48)} 34 {x(58)} 16 Q{x(64)} 8 {x(74)} 16 Q{x(100)} 32 {x(120)} 46 Z",
            "fill": GINGER, "stroke": LINE, "stroke-width": "9",
            "stroke-linejoin": "round", "stroke-linecap": "round",
        }))
        out.append(ET.Element(tag("path"), {
            "d": f"M{x(60)} 72 Q{x(61)} 40 {x(66)} 30 Q{x(70)} 26 {x(76)} 30 Q{x(92)} 40 {x(104)} 48 Z",
            "fill": "#f6b8b0",
        }))
    return out


def write_svg(name: str, defs: ET.Element, elements: list[ET.Element]) -> None:
    svg = ET.Element(tag("svg"), {
        "width": "256", "height": "240", "viewBox": "0 0 256 240",
    })
    svg.append(copy.deepcopy(defs))
    for element in elements:
        svg.append(copy.deepcopy(element))
    ET.ElementTree(svg).write(OUT / f"{name}.svg", encoding="utf-8", xml_declaration=True)


def build() -> list[str]:
    OUT.mkdir(parents=True, exist_ok=True)
    native = native_module()
    original = ET.fromstring(native.cat_svg("hero"))
    children = list(original)
    # Assert the native sections, so a later upstream edit fails visibly instead of
    # accidentally retaining the sword or deleting part of the face.
    assert len(children) == 34
    assert children[12].get("d") == native.CAT_BODY
    assert children[19].get("d") == native.CAT_HEAD
    assert children[27].get("fill") == "#dfe6ee"
    assert children[5].get("d") == "M206 222 L44 112"
    defs = children[0]
    tail = [normalise(e) for e in children[1:3]]
    cape = [normalise(e) for e in children[3:5]]
    # The old native cape would extend 2.5 px below this canvas after changing the
    # outline. Pull its bottom Bezier control up by 6 px (edge moves only 3 px).
    # The hem, colour, shoulder positions and overall native shape stay unchanged.
    cape[0].set("d", cape[0].get("d", "").replace("Q128 248", "Q128 242"))
    torso = [normalise(e) for e in children[12:15]]
    clasps = [normalise(e) for e in children[17:19]]
    body = tail + cape + torso + clasps
    head_noears = [normalise(e) for e in children[19:27]]
    head = restored_ears() + head_noears
    paws = [normalise(e) for e in children[15:17]]
    layers = {
        "hero-tail": tail,
        "hero-cape": cape,
        "hero-torso": torso + clasps,
        "hero-body": body,
        "hero-head": head,
        "hero-head-noears": head_noears,
        "hero-paws": paws,
        "hero-base": body + head,
        "hero-neutral": body + paws + head,
    }
    for name, elements in layers.items():
        write_svg(name, defs, elements)
    manifest = {
        "canvas": [256, 240], "render_scale": 3, "png_size": [768, 720],
        "native_source": "tools/ui/make_svgs.py::cat_svg('hero')",
        "outline": {"color": LINE, "main_width": 9, "tail_understroke": 31, "tail_coat": 13},
        "removed": ["old back-mounted sword", "old helmet including plume"],
        "preserved": ["ginger coat", "white chest and muzzle", "native face and brows", "blue cape and gold hem/clasps", "head and body silhouette"],
        "restored": "native regular-cat ears in hero ginger, bases hidden by native head",
        "helmet_layer": "Use hero-head-noears while helmet is worn; hero-head retains ears for the clean unhelmeted base",
        "minor_safety_adjustment": "cape bottom control Q128248 -> Q128242, avoids 2.5 px lower-edge clipping",
        "layers": list(layers),
        "paws": "separate native 9px hook-stroke layer; wear gloves on top at shared sockets (94,166)/(160,166)",
        "registration": "All assets retain full canvas; never independently trim worn layers",
    }
    (OUT / "source-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    keys = ", ".join(json.dumps(k) for k in layers)
    renderer = f'''extends SceneTree

const KEYS := [{keys}]

func _initialize() -> void:
    var folder := ProjectSettings.globalize_path("res://docs/design/2026-10-19/hero-equipment/sources")
    for key in KEYS:
        var stem := folder.path_join(key)
        var image := Image.new()
        assert(image.load_svg_from_string(FileAccess.get_file_as_string(stem + ".svg"), 3.0) == OK, key)
        assert(image.get_size() == Vector2i(768, 720), key)
        assert(image.save_png(stem + ".png") == OK, key)
        print("HERO_BASE_NATIVE_RENDERED ", key, " ", image.get_size())
    print("HERO_BASE_NATIVE_COMPLETE ", KEYS.size())
    quit()
'''
    (OUT / "render_base.gd").write_text(renderer, encoding="utf-8")
    return list(layers)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--render", action="store_true", help="Rasterize the full-canvas SVG layers in Godot")
    parser.add_argument("--godot", type=Path, default=GODOT)
    args = parser.parse_args()
    keys = build()
    if args.render:
        result = subprocess.run([
            str(args.godot), "--headless", "--path", str(ROOT),
            "--script", "res://docs/design/2026-10-19/hero-equipment/sources/render_base.gd",
        ], cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace")
        (OUT / "godot-render.log").write_text(result.stdout + result.stderr, encoding="utf-8")
        print(result.stdout)
        if result.returncode:
            raise RuntimeError(result.stderr)
        assert "HERO_BASE_NATIVE_COMPLETE" in result.stdout
        assert all((OUT / f"{key}.png").exists() for key in keys)
    print(f"Built {len(keys)} native hero review layers in {OUT}")


if __name__ == "__main__":
    main()
