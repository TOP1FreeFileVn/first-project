"""Verify latest native artwork routing and preserve the unrelated production art."""
from pathlib import Path
import hashlib
import json

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
ART = ROOT / "game/ui/art"
GEAR = ROOT / "docs/design/2026-10-22/hero-gear-canvas"
ARMOR = ROOT / "docs/design/2026-10-22/armor-canvas"
WEAPONS = ROOT / "docs/design/2026-10-22/hero-weapons-canvas"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    pairs = []
    for family in ("helmet", "armor", "boots"):
        folder = ARMOR if family == "armor" else GEAR
        for size in (32, 48, 64, 96, 256):
            name = f"icon_eq_{family}" + (f"_{size}" if size != 256 else "")
            pairs.append((ART / f"{name}.png", folder / f"godot/{family}-icon-{size}.png", (size, size)))
    for family, weapon, pose in (("bow", "cung", "ranged"), ("staff", "gay_phep", "magic"), ("katana", "katana", "katana")):
        for size in (32, 48, 64, 96, 256):
            name = f"icon_hero_w_{weapon}" + (f"_{size}" if size != 256 else "")
            pairs.append((ART / f"{name}.png", WEAPONS / f"godot/{family}-icon-{size}.png", (size, size)))
        pairs.append((ART / f"hero_cat_{pose}.png", HERE / f"godot/hero-{family}-768.png", (768, 720)))
        source_svg = (WEAPONS / f"svg/hero-{family}-256.svg").read_text("utf-8")
        production_svg = (HERE / f"svg/hero-{family}-768.svg").read_text("utf-8")
        assert production_svg.strip() == source_svg.replace('width="256" height="240"', 'width="768" height="720"').strip(), family
    for destination, source, dimensions in pairs:
        assert sha(destination) == sha(source), destination
        assert Image.open(destination).size == dimensions, destination
    before = json.loads((HERE / "before-sha256.json").read_text())
    changed = sorted(name for name, old_hash in before.items() if sha(ROOT / name) != old_hash)
    expected = sorted(path.relative_to(ROOT).as_posix() for path, _, _ in pairs)
    assert changed == expected, {"changed": changed, "expected": expected}
    manifest = json.loads((ART / "equipment-sources.json").read_text("utf-8"))
    tracked = {entry["asset"]: entry for entry in manifest["assets"]}
    for destination, _, _ in pairs:
        entry = tracked[destination.relative_to(ROOT).as_posix()]
        assert entry["sha256"] == sha(destination), destination
        for source in entry["sources"]:
            assert sha(ROOT / source["path"]) == source["sha256"], source["path"]
    report = {"copied_exactly": len(pairs), "changed_pngs": changed,
              "unchanged_other_pngs": len(before) - len(changed),
              "retained": "all sword and clean axe icons/held sprites; all soldier sprites",
              "production_held_resolution": [768, 720], "held_svg_paths_unchanged": True,
              "manifest_hashes": "all installed assets and source hashes match"}
    (HERE / "verification.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    names = ("eq_helmet", "eq_armor", "eq_boots", "hero_w_cung", "hero_w_gay_phep", "hero_w_katana")
    board = Image.new("RGB", (860, 492), "#e9ece7")
    draw = ImageDraw.Draw(board)
    for column, name in enumerate(names):
        x = 10 + column * 142
        draw.text((x + 4, 10), name, fill="#583f21")
        icon = Image.open(ART / f"icon_{name}.png").convert("RGBA")
        icon.thumbnail((128, 128), Image.Resampling.LANCZOS)
        board.paste(icon, (x + 4, 36), icon)
        for y, size in ((181, 32), (235, 48), (307, 64), (391, 96)):
            image = Image.open(ART / f"icon_{name}_{size}.png").convert("RGBA")
            board.paste(image, (x + (132 - size) // 2, y), image)
    board.save(HERE / "installed-icons.png")
    held = Image.new("RGB", (780, 252), "#e9ece7")
    for i, pose in enumerate(("ranged", "magic", "katana")):
        image = Image.open(ART / f"hero_cat_{pose}.png").convert("RGBA")
        image.thumbnail((256, 240), Image.Resampling.LANCZOS)
        held.paste(image, (i * 260 + 2, 8), image)
    held.save(HERE / "installed-held.png")
    print(f"PASS: {len(pairs)} exact native copies; {len(before) - len(changed)} unrelated PNGs unchanged.")


if __name__ == "__main__":
    main()
