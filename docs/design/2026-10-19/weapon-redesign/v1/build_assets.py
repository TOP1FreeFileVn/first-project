"""Build approval-only weapon and held-cat SVGs. Never writes production art."""
from pathlib import Path
import json
import sys
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
sys.path.insert(0, str(ROOT / "tools" / "ui"))
sys.path.insert(0, str(HERE))
import make_units
import weapon_melee
import weapon_ranged
import weapon_magic

NAMES = [
    "Kiếm", "Rìu", "Đao", "Katana", "Cung", "Nỏ", "Súng", "Đại bác",
    "Gậy phép", "Bình thuốc", "Sách phép", "Đũa phép", "Giáo", "Cự kiếm", "Chùy", "Búa",
]
FAMILIES = ["Cận chiến", "Tầm xa", "Phép thuật", "Giáo & vũ khí nặng"]
RARITIES = ["Thường", "Hiếm", "Sử thi", "Huyền thoại"]
# Keep the muzzle/eyes visible and put each grip close to the cat's right paw.
HELD = {
    "cung": (109, 111, .8, 7.5), "no": (127, 97, .8, 8.0),
    "sung": (149, 96, .8, 8.0), "dai_bac": (130, 120, .85, 8.0),
    "thuoc": (132, 88, .85, 8.0), "sach_phep": (143, 110, .8, 8.0),
    "dua_phep": (130, 54, 1.0, 8.0), "chuy": (130, 54, 1.0, 8.5),
}


def main():
    weapons = {}
    for module in (weapon_melee, weapon_ranged, weapon_magic):
        for key, icon in module.make_weapons().items():
            if key in weapons:
                raise ValueError(f"Duplicate weapon: {key}")
            weapons[key] = icon
    assert set(weapons) == {soldier[0] for soldier in make_units.SOLDIERS}
    make_units._WEAPONS = weapons
    def held_weapon(name, x, y, scale, tag):
        outline = 10.0
        if name in HELD:
            x, y, scale, outline = HELD[name]
        text = weapons[name].flat_svg(128, line=outline / scale)
        body = text[text.index(">", text.index("<svg")) + 1:text.rindex("</svg>")]
        return "", f'<g transform="translate({x} {y}) scale({scale})">{body}</g>'
    make_units.weapon = held_weapon
    (HERE / "weapons").mkdir(exist_ok=True)
    (HERE / "units").mkdir(exist_ok=True)
    items = []
    for index, (key, klass, rarity, weapon_name) in enumerate(make_units.SOLDIERS):
        for size in (64, 128, 256):
            suffix = "" if size == 128 else f"_{size}"
            svg = weapons[key].flat_svg(size)
            ET.fromstring(svg)
            (HERE / "weapons" / f"icon_w_{key}{suffix}.svg").write_text(svg, encoding="utf-8")
        unit = make_units.cat_soldier(make_units.COAT[klass], klass, rarity, weapon_name)
        ET.fromstring(unit)
        (HERE / "units" / f"unit_{key}.svg").write_text(unit, encoding="utf-8")
        items.append({"id": key, "name": NAMES[index], "family": FAMILIES[index // 4],
                      "rarity": RARITIES[rarity], "rarity_index": rarity,
                      "held_pose": HELD.get(key, (130, 54, 1.0, 10.0))})
    (HERE / "assets.json").write_text(json.dumps({"status": "awaiting_review", "items": items},
                                                 ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Built {len(items)} approval weapons and held-cat SVGs; production unchanged.")


if __name__ == "__main__":
    main()
