"""Prepare review-only source layers, preserving the production SVG files."""
from pathlib import Path
import re
import xml.etree.ElementTree as ET

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
source = (ROOT / "game/ui/skin/menu_castle_island.svg").read_text(encoding="utf-8")
island, count = re.subn(
    r'<g transform="translate\(145 2\) scale\(\.9\)">.*?</g>',
    "",
    source,
    flags=re.S,
)
assert count == 1, f"Expected exactly one castle group, got {count}"
ET.fromstring(island)
(OUT / "base-island.svg").write_text(island, encoding="utf-8")
(OUT / "hero-cat.svg").write_bytes((ROOT / "game/ui/skin/cat_hero.svg").read_bytes())
print("Prepared base-island.svg and unchanged hero-cat.svg")
