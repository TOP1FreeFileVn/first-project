"""Prepare generated gold illustrations with the established gem-pack cleanup.

python -B tools/ui/install_shop_gold_packs.py
python -B tools/ui/install_shop_gold_packs.py --check
Use --partial to install completed tiers while generation is still running.
No generation API, credentials or player data are accessed.
"""
from __future__ import annotations

import argparse
import json

from PIL import Image, ImageDraw, ImageFont

import install_shop_gem_packs as preparation

ROOT = preparation.ROOT
SOURCE = ROOT / "output/imagegen/gold-packs-2026-10-24"
ART = ROOT / "game/ui/art/shop_gold_packs"
DOCS = ROOT / "docs/design/2026-10-24/gold-pack-art"
AMOUNTS = (500, 500, 2500, 5000, 12500, 25000)
SUBJECTS = ("Three coins", "Drawstring pouch", "Shallow tray", "Deep carton box", "Open chest", "Overflowing chest")


def contact_sheet(images: list[tuple[int, Image.Image]]) -> Image.Image:
    canvas = Image.new("RGB", (684, 492), "#355e65")
    draw = ImageDraw.Draw(canvas)
    font_path = str(ROOT / "game/ui/fonts/PaytoneOne-Regular.ttf")
    title_font = ImageFont.truetype(font_path, 20)
    caption_font = ImageFont.truetype(font_path, 12)
    for tier, illustration in images:
        index = tier - 1
        x, y = 12 + index % 3 * 224, 12 + index // 3 * 240
        draw.rounded_rectangle((x, y, x + 212, y + 228), radius=18, fill="#fff0ba", outline="#583f21", width=3)
        amount = f"{AMOUNTS[index]:,}".replace(",", ".")
        draw.text((x + 106, y + 13), amount, anchor="mt", fill="#583f21", font=title_font)
        thumb = illustration.convert("RGBa").resize((148, 148), Image.Resampling.LANCZOS).convert("RGBA")
        canvas.paste(thumb, (x + 32, y + 42), thumb)
        draw.text((x + 106, y + 201), f"{tier:02d} - {SUBJECTS[index]}", anchor="mt", fill="#583f21", font=caption_font)
    return canvas


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Check generated files and metadata without writing")
    parser.add_argument("--partial", action="store_true", help="Allow missing raw images")
    args = parser.parse_args()
    if not args.check:
        ART.mkdir(parents=True, exist_ok=True)
        DOCS.mkdir(parents=True, exist_ok=True)
    records, images, missing = [], [], []
    for tier in range(1, 7):
        source = SOURCE / f"{tier:02d}-raw.png"
        if not source.exists():
            missing.append(tier)
            continue
        image, record = preparation.process(source)
        output = ART / f"{tier:02d}.png"
        content = preparation.png_bytes(image)
        record.update(tier=tier, subject=SUBJECTS[tier - 1], gold=AMOUNTS[tier - 1],
                      concept_reference=f"game/ui/art/shop_gem_packs/{tier:02d}.png",
                      source=preparation.rel(source), source_sha256=preparation.sha(source.read_bytes()),
                      output=preparation.rel(output), output_sha256=preparation.sha(content))
        metadata = SOURCE / f"{tier:02d}-generation.json"
        if metadata.exists():
            generation = json.loads(metadata.read_text(encoding="utf-8-sig"))
            record["generation"] = {key: generation[key] for key in preparation.SAFE_METADATA if key in generation}
        if args.check:
            if not output.exists() or output.read_bytes() != content:
                raise SystemExit(f"Missing or outdated illustration: {preparation.rel(output)}")
        else:
            output.write_bytes(content)
        records.append(record)
        images.append((tier, image))
        print(f"{tier:02d}: {record['method']} -> {preparation.rel(output)} alpha_bbox={record['alpha_bbox']}")
    if missing and not args.partial:
        raise SystemExit(f"Missing sources: {missing}; use --partial for an incomplete batch")
    if len({record['output_sha256'] for record in records}) != len(records):
        raise SystemExit("Duplicate gold illustrations detected")
    manifest = {
        "complete": not missing, "missing_tiers": missing,
        "canvas": [512, 512], "maximum_art_extent": [32, 32, 480, 480],
        "alignment": "centered ink bbox on both axes", "ink_alpha_threshold": preparation.INK_ALPHA,
        "resampling": "premultiplied RGBA Lanczos",
        "concept_policy": "One-to-one counterpart of each existing gem pack; replace gems with gold coins while retaining its container and composition.",
        "model_note": "Requested model is not verified model identity. Only an explicitly reported image model is recorded as reported_image_model.",
        "records": records,
    }
    if args.check:
        installed = json.loads((DOCS / "manifest.json").read_text(encoding="utf-8"))
        if installed != manifest:
            raise SystemExit("Gold illustration manifest is outdated")
    else:
        (DOCS / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        contact_sheet(images).save(DOCS / "contact-sheet.png")
    print(f"GOLD_PACK_ART_SUMMARY installed={len(records)} unique={len({record['output_sha256'] for record in records})} complete={not missing} checked={args.check}")


if __name__ == "__main__":
    main()
