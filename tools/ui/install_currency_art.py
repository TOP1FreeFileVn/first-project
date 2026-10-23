"""Install the approved currency and combat-power SVG overrides.

Run from any directory:
    python -B tools/ui/install_currency_art.py
Verify without writing:
    python -B tools/ui/install_currency_art.py --check

Canonical production sources live in game/ui/art_sources, independently of
design-review documents. Ui.tex prefers game/ui/art over the generated skin,
so running make_svgs.py cannot restore the retired currency artwork. Only the
root viewport dimensions change between sizes; paths, palette and stroke
geometry remain identical to the user-approved designs.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "game/ui/art"
SOURCE = ROOT / "game/ui/art_sources"
MANIFEST = Path(__file__).with_name("accepted_currency_art.json")
SIZES = (32, 48, 64, 96, 128)
SELECTIONS = (
    {
        "source": "currency_coin.svg",
        "names": ("coin", "coins"),
        "selection": "Bright front-facing gold coin with a small gear stamp",
        "review_source": "docs/design/2026-10-23/gold-icons-bright/svg/gold-classic-96.svg",
    },
    {
        "source": "currency_gem.svg",
        "names": ("gem", "gems"),
        "selection": "Wide brilliant purple diamond",
        "review_source": "docs/design/2026-10-23/diamond-icons/svg/diamond-brilliant-96.svg",
    },
    {
        "source": "power_crossed.svg",
        "names": ("power",),
        "selection": "Crossed swords for total combat power",
        "review_source": "docs/design/2026-10-23/power-icons/svg/power-crossed-96.svg",
    },
)


def relative(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sized_svg(artwork: str, size: int) -> bytes:
    root = ET.fromstring(artwork)
    if root.tag != "{http://www.w3.org/2000/svg}svg" or root.attrib.get("viewBox") != "0 0 96 96":
        raise ValueError("Approved artwork must retain its 96 by 96 source viewBox")

    def resize_root(match: re.Match[str]) -> str:
        header, count = re.subn(
            r'\b(width|height)="[^"]*"',
            lambda dimension: f'{dimension.group(1)}="{size}"',
            match.group(0),
        )
        if count != 2:
            raise ValueError("Approved SVG root must specify width and height")
        return header

    return (re.sub(r"<svg\b[^>]*>", resize_root, artwork, count=1).rstrip() + "\n").encode("utf-8")


def install(check: bool) -> None:
    records = []
    problems = []
    if not check:
        ART.mkdir(parents=True, exist_ok=True)
    for selection in SELECTIONS:
        source = SOURCE / selection["source"]
        artwork = source.read_text(encoding="utf-8")
        outputs = []
        for name in selection["names"]:
            for size in SIZES:
                suffix = "" if size == 128 else f"_{size}"
                target = ART / f"icon_{name}{suffix}.svg"
                expected = sized_svg(artwork, size)
                # Ui.tex prioritizes PNGs; do not silently install a hidden vector.
                if target.with_suffix(".png").exists():
                    problems.append(f"PNG shadows approved vector: {relative(target.with_suffix('.png'))}")
                if check:
                    if not target.exists() or target.read_bytes() != expected:
                        problems.append(f"Missing or outdated: {relative(target)}")
                else:
                    target.write_bytes(expected)
                outputs.append({"path": relative(target), "size": size, "sha256": sha(expected)})
        records.append({
            "selection": selection["selection"],
            "source": relative(source),
            "source_sha256": sha(source.read_bytes()),
            "review_source": selection["review_source"],
            "outputs": outputs,
        })
    manifest = {
        "schema_version": 1,
        "operation": "Approved paths unchanged; resize root viewport only",
        "plural_policy": "coins and gems alias the approved single icons; no unapproved stack is introduced",
        "runtime_priority": "Ui.tex loads game/ui/art before generated game/ui/skin",
        "selections": records,
    }
    expected_manifest = (json.dumps(manifest, indent=2, ensure_ascii=False) + "\n").encode("utf-8")
    if check:
        if not MANIFEST.exists() or MANIFEST.read_bytes() != expected_manifest:
            problems.append(f"Missing or outdated: {relative(MANIFEST)}")
    else:
        MANIFEST.write_bytes(expected_manifest)
    if problems:
        raise SystemExit("\n".join(problems))
    print(f"APPROVED_CURRENCY_ART_{'CHECK' if check else 'INSTALL'}_OK: 25 SVGs, 3 canonical sources")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="verify installed art without writing")
    install(parser.parse_args().check)
