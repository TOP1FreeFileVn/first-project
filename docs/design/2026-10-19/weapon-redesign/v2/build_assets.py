"""Build skill-guided approval art only; production generators stay untouched."""
from pathlib import Path
import json
import sys
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
sys.path.insert(0, str(ROOT / "tools/ui"))
sys.path.insert(0, str(HERE))
import make_units
import weapon_melee
import weapon_ranged
import weapon_magic

NAMES = ["Kiếm", "Rìu", "Đao", "Katana", "Cung", "Nỏ", "Súng", "Đại bác",
         "Gậy phép", "Bình thuốc", "Sách phép", "Đũa phép", "Giáo", "Cự kiếm", "Chùy", "Búa"]
FAMILIES = ["Cận chiến", "Tầm xa", "Phép thuật", "Giáo & vũ khí nặng"]
HELD = {
    "cung": (112, 112, .8, 6.5), "no": (124, 110, .8, 6.5),
    "sung": (143, 103, .8, 6.5), "dai_bac": (130, 123, .85, 6.5),
    "thuoc": (132, 97, .85, 7.0), "sach_phep": (137, 111, .8, 6.5),
}


def main():
    weapons = {}
    for module in (weapon_melee, weapon_ranged, weapon_magic):
        for key, icon in module.make_weapons().items():
            if key in weapons:
                raise ValueError(f"Duplicate weapon: {key}")
            weapons[key] = icon
    assert set(weapons) == {row[0] for row in make_units.SOLDIERS}
    make_units._WEAPONS = weapons

    def held_weapon(name, x, y, scale, tag):
        x, y, scale, outline = HELD.get(name, (130, 54, 1., 7.0))
        text = weapons[name].flat_svg(128, line=outline / scale)
        body = text[text.index(">", text.index("<svg")) + 1:text.rindex("</svg>")]
        return "", f'<g transform="translate({x} {y}) scale({scale})">{body}</g>'

    make_units.weapon = held_weapon
    for directory in ("weapons", "units"):
        (HERE / directory).mkdir(exist_ok=True)
    items = []
    for index, (key, klass, rarity, weapon_name) in enumerate(make_units.SOLDIERS):
        for size in (48, 64, 128, 256):
            suffix = "" if size == 128 else f"_{size}"
            text = weapons[key].flat_svg(size)
            ET.fromstring(text)
            assert not any(token in text.lower() for token in ("gradient", "filter=", "opacity=")), key
            (HERE / "weapons" / f"icon_w_{key}{suffix}.svg").write_text(text, encoding="utf-8")
        text = make_units.cat_soldier(make_units.COAT[klass], klass, rarity, weapon_name)
        ET.fromstring(text)
        (HERE / "units" / f"unit_{key}.svg").write_text(text, encoding="utf-8")
        items.append({"id": key, "name": NAMES[index], "family": FAMILIES[index // 4],
                      "rarity_index": rarity, "held_pose": HELD.get(key, (130, 54, 1., 7.0))})
    (HERE / "assets.json").write_text(json.dumps({"status": "awaiting_review", "version": 2,
        "skill": "casual-weapon-design", "items": items}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("Built 16 v2 weapons at 48/64/128/256 and 16 held units; production untouched.")


if __name__ == "__main__":
    main()
