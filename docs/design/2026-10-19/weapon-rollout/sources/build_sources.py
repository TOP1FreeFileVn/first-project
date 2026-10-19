"""Build proposal-only unarmed cats without changing production generators."""

from pathlib import Path
import hashlib
import json
import shutil
import sys
import xml.etree.ElementTree as ET


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
sys.path.insert(0, str(ROOT / "tools/ui"))
import make_units as units

ET.register_namespace("", "http://www.w3.org/2000/svg")
INK = "#583f21"
TARGET = 9.0


def normalize(source: str):
    tree = ET.fromstring(source)
    changes = []
    for node in tree.iter():
        if node.get("stroke") != INK:
            continue
        previous = float(node.get("stroke-width"))
        replacement = 31.0 if previous == 30.0 else TARGET
        changes.append({"from": previous, "to": replacement})
        node.set("stroke-width", str(replacement))
    # All geometry, fills, faces and non-brown marks stay exactly as generated.
    original = ET.fromstring(source)
    for before, after in zip(original.iter(), tree.iter()):
        expected = dict(before.attrib)
        if expected.get("stroke") == INK:
            expected["stroke-width"] = str(
                31.0 if float(expected["stroke-width"]) == 30.0 else TARGET
            )
        assert after.attrib == expected
        assert after.tag == before.tag and after.text == before.text
    return ET.tostring(tree, encoding="utf-8", xml_declaration=True), changes


def main():
    # Never call either generator's main/save functions.
    old_weapon = units.weapon
    units.weapon = lambda *args, **kwargs: ("", "")
    manifest = []
    try:
        for item_id, klass, rarity, weapon_name in units.SOLDIERS:
            text = units.cat_soldier(units.COAT[klass], klass, rarity, weapon_name)
            output, changes = normalize(text)
            path = HERE / f"cat_{item_id}.svg"
            path.write_bytes(output)
            manifest.append(
                {
                    "id": item_id,
                    "class": klass,
                    "rarity": rarity,
                    "source": path.name,
                    "raster": f"cat_{item_id}.png",
                    "canvas": [256, 240],
                    "raster_size": [768, 720],
                    "weapon_embedded": False,
                    "brown_strokes": changes,
                    "sha256": hashlib.sha256(output).hexdigest(),
                }
            )
    finally:
        units.weapon = old_weapon
    paw = ROOT / "docs/design/2026-10-19/weapon-redesign/v6-nine-px/sources/front-paw.svg"
    shutil.copyfile(paw, HERE / "front-paw.svg")
    paw_tree = ET.parse(HERE / "front-paw.svg")
    assert all(
        float(node.get("stroke-width")) == TARGET
        for node in paw_tree.iter()
        if node.get("stroke") == INK
    )
    result = {
        "generator": "tools/ui/make_units.py::cat_soldier (weapon monkeypatched in memory)",
        "production_changed": False,
        "geometry_and_colors_preserved": True,
        "target_outer_stroke_unit_px": TARGET,
        "tail_dark_stroke_unit_px": 31.0,
        "tail_color_stroke_unit_px": 13.0,
        "native_scale": 3,
        "items": manifest,
        "front_paw": {"svg": "front-paw.svg", "png": "front-paw.png", "source": str(paw.relative_to(ROOT))},
    }
    (HERE / "source-manifest.json").write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print("UNARMED_NINE_PX_SOURCES_CREATED", len(manifest))


if __name__ == "__main__":
    main()
