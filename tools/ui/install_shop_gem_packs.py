"""Install generated gem-pack art without tracing or redrawing it.

python -B tools/ui/install_shop_gem_packs.py
python -B tools/ui/install_shop_gem_packs.py --check
Use --partial to process only the source images already available.
Requires Pillow and numpy. No generation API or credentials are accessed.
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "output/imagegen/gem-packs-2026-10-24"
ART = ROOT / "game/ui/art/shop_gem_packs"
DOCS = ROOT / "docs/design/2026-10-24/gem-pack-art"
AMOUNTS = (120, 600, 1500, 3300, 6900, 15000)
SUBJECTS = ("Three gems", "Drawstring pouch", "Shallow tray", "Deep carton box", "Open chest", "Overflowing chest")
INK_ALPHA = 8
OFFWHITE_TOLERANCE = 28
SAFE_METADATA = ("tier", "status", "transport", "requested_image_model", "reported_image_model", "requested_size", "quality", "started_utc", "finished_utc", "prompt", "style_prompt", "reference_files", "output", "response_model", "image_model", "revised_prompt")


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def bbox(alpha: Image.Image, threshold: int = 1):
    return alpha.point(lambda value: 255 if value >= threshold else 0).getbbox()


def extract(image: Image.Image) -> tuple[Image.Image, dict]:
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A")
    if alpha.getextrema()[0] < 255:
        return rgba, {"method": "preserve_generated_alpha", "removed_background_pixels": 0}
    rgb = np.asarray(rgba)[:, :, :3].astype(np.int16)
    edge = np.concatenate((rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]))
    color = np.median(edge, axis=0).astype(np.int16)
    candidate = (np.max(np.abs(rgb - color), axis=2) <= OFFWHITE_TOLERANCE)
    candidate &= (rgb[:, :, 0] >= 210) & (rgb[:, :, 1] >= 200) & (rgb[:, :, 2] >= 175)
    mask = Image.fromarray(candidate.astype(np.uint8), "L").copy()
    w, h = mask.size
    seeds = [(x, y) for x in range(w) for y in (0, h - 1)]
    seeds += [(x, y) for y in range(h) for x in (0, w - 1)]
    for point in seeds:
        if mask.getpixel(point) == 1:
            ImageDraw.floodfill(mask, point, 2, thresh=0)
    removed = np.asarray(mask) == 2
    if removed.mean() < 0.02:
        raise ValueError("No credible border-connected offwhite background found")
    alpha_data = np.full((h, w), 255, dtype=np.uint8)
    alpha_data[removed] = 0
    rgba.putalpha(Image.fromarray(alpha_data, "L"))
    return rgba, {"method": "border_connected_offwhite_floodfill", "border_median_rgb": color.tolist(), "per_channel_tolerance": OFFWHITE_TOLERANCE, "removed_background_pixels": int(removed.sum())}


def process(source: Path) -> tuple[Image.Image, dict]:
    with Image.open(source) as original:
        source_info = {"source_mode": original.mode, "source_size": list(original.size), "source_alpha_extrema": list(original.convert("RGBA").getchannel("A").getextrema())}
        cutout, extraction = extract(original)
    ink = bbox(cutout.getchannel("A"), INK_ALPHA)
    if ink is None:
        raise ValueError(f"Empty illustration: {source}")
    cropped = cutout.crop(ink)
    scale = min(448 / cropped.width, 448 / cropped.height)
    dimensions = (max(1, round(cropped.width * scale)), max(1, round(cropped.height * scale)))
    # Premultiplication keeps fully transparent source RGB from creating a fringe.
    resized = cropped.convert("RGBa").resize(dimensions, Image.Resampling.LANCZOS).convert("RGBA")
    result = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    offset = ((512 - dimensions[0]) // 2, (512 - dimensions[1]) // 2)
    result.paste(resized, offset)
    alpha = result.getchannel("A")
    visible = np.asarray(alpha)
    record = source_info | extraction | {"source_ink_bbox_alpha8": list(ink), "output_size": [512, 512], "output_mode": result.mode, "resized_crop_size": list(dimensions), "placement": list(offset), "alpha_extrema": list(alpha.getextrema()), "alpha_bbox": list(bbox(alpha)), "ink_bbox_alpha8": list(bbox(alpha, INK_ALPHA)), "nonzero_alpha_pixels": int((visible > 0).sum()), "partial_alpha_pixels": int(((visible > 0) & (visible < 255)).sum())}
    extent = record["alpha_bbox"]
    assert min(extent[:2]) >= 32 and max(extent[2:]) <= 480, extent
    return result, record


def png_bytes(image: Image.Image) -> bytes:
    stream = io.BytesIO()
    image.save(stream, format="PNG", optimize=True)
    return stream.getvalue()


def contact_sheet(images: list[tuple[int, Image.Image]]) -> Image.Image:
    canvas = Image.new("RGB", (684, 492), "#355e65")
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.truetype(str(ROOT / "game/ui/fonts/PaytoneOne-Regular.ttf"), 20)
    small = ImageFont.truetype(str(ROOT / "game/ui/fonts/PaytoneOne-Regular.ttf"), 12)
    for tier, image in images:
        index = tier - 1
        x, y = 12 + (index % 3) * 224, 12 + (index // 3) * 240
        draw.rounded_rectangle((x, y, x + 212, y + 228), radius=18, fill="#eee2f3", outline="#583f21", width=3)
        label = f"{AMOUNTS[index]:,}".replace(",", ".")
        draw.text((x + 106, y + 13), label, anchor="mt", fill="#583f21", font=font)
        thumb = image.resize((148, 148), Image.Resampling.LANCZOS)
        canvas.paste(thumb, (x + 32, y + 42), thumb)
        draw.text((x + 106, y + 201), f"{tier:02d} · {SUBJECTS[index]}", anchor="mt", fill="#583f21", font=small)
    return canvas


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Verify outputs against sources without writing")
    parser.add_argument("--partial", action="store_true", help="Allow missing source tiers")
    args = parser.parse_args()
    records, images, missing = [], [], []
    if not args.check:
        ART.mkdir(parents=True, exist_ok=True)
        DOCS.mkdir(parents=True, exist_ok=True)
    for tier in range(1, 7):
        source = SOURCE / f"{tier:02d}-raw.png"
        if not source.exists():
            missing.append(tier)
            continue
        image, record = process(source)
        output = ART / f"{tier:02d}.png"
        content = png_bytes(image)
        record.update(tier=tier, subject=SUBJECTS[tier - 1], gems=AMOUNTS[tier - 1], source=rel(source), source_sha256=sha(source.read_bytes()), output=rel(output), output_sha256=sha(content))
        metadata = SOURCE / f"{tier:02d}-generation.json"
        if metadata.exists():
            raw = json.loads(metadata.read_text(encoding="utf-8-sig"))
            record["generation"] = {key: raw[key] for key in SAFE_METADATA if key in raw}
        if args.check:
            if not output.exists() or output.read_bytes() != content:
                raise SystemExit(f"Missing or outdated output: {rel(output)}")
        else:
            output.write_bytes(content)
        records.append(record)
        images.append((tier, image))
        print(f"{tier:02d}: {record['method']} -> {rel(output)} alpha_bbox={record['alpha_bbox']}")
    if missing and not args.partial:
        raise SystemExit(f"Missing sources: {missing}; rerun with --partial to install available tiers")
    if len({record["output_sha256"] for record in records}) != len(records):
        raise SystemExit("Duplicate production illustrations detected")
    manifest = {"complete": not missing, "missing_tiers": missing, "canvas": [512, 512], "maximum_art_extent": [32, 32, 480, 480], "alignment": "centered ink bbox on both axes", "ink_alpha_threshold": INK_ALPHA, "resampling": "premultiplied RGBA Lanczos", "model_note": "requested_image_model is the requested model only. response_model identifies the response orchestrator, not the image generator. reported_image_model records only an explicitly reported image model; a missing or null value means unknown. No image model identity is inferred.", "records": records}
    if args.check:
        installed = json.loads((DOCS / "manifest.json").read_text(encoding="utf-8"))
        if manifest != installed:
            raise SystemExit("Production files match but manifest is outdated")
    else:
        (DOCS / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        contact_sheet(images).save(DOCS / "contact-sheet.png")
        (DOCS / "README.md").write_text("# Gem-pack illustrations\n\nSix individually generated shop illustrations: three gems, drawstring pouch, shallow tray, deep carton box, open chest, and overflowing chest. Production PNGs contain no text or UI.\n\nGenerated through the user-selected local 9Router Responses route. The requested image model was `gpt-image-2.5-sunburst`. `response_model` identifies the response orchestrator, not the image generator; only `reported_image_model` records an explicitly reported image model. A missing or null reported image model means unknown; no identity is inferred. Per-image safe generation metadata and original/output SHA-256 hashes are in [manifest.json](manifest.json). Prompts are in [prompts](prompts/). Original images remain unchanged under `output/imagegen/gem-packs-2026-10-24/`.\n\nImages 03 and 06 preserve their generated alpha within the meaningful ink crop. The crop ignores source alpha below 8 outside the illustration (faint stray transparency); object alpha and colors are retained. Opaque images 01, 02, 04, and 05 remove only offwhite pixels connected to the image border, leaving enclosed cream materials intact. No tracing, drawing, recoloring, or stroke replacement is applied.\n\nEach production image is RGBA 512×512, fitted within 32…480, with its meaningful ink bbox centered on both axes. Scaling uses premultiplied RGBA Lanczos. [contact-sheet.png](contact-sheet.png) shows the assets at 148×148 thumbnail size on the shop card color.\n\nReinstall: `python -B tools/ui/install_shop_gem_packs.py`\n\nRead-only verification: `python -B tools/ui/install_shop_gem_packs.py --check`\n\nAllow incomplete source batches: add `--partial`. The installer never accesses credentials, a generation API, Godot, balances, or player data.\n", encoding="utf-8")
    print(f"GEM_PACK_ART_SUMMARY installed={len(records)} unique={len({record['output_sha256'] for record in records})} complete={not missing} checked={args.check}")


if __name__ == "__main__":
    main()
