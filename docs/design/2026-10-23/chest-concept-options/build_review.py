"""Assemble generated chest concepts for review without redrawing their pixels.

Input: output/imagegen/chest-options-2026-10-23/{A,B,C,D}-raw.png.
Each source is one horizontal row of three unlabelled chests. Originals stay
untouched. Use --available to assemble a partial delivery while rows arrive.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
DEFAULT_INPUT = ROOT / "output/imagegen/chest-options-2026-10-23"
INK = "#583f21"
PAPER = "#f3eee0"
PANEL = "#fcf8ed"
SAGE = "#e4ebe0"
MUTED = "#7b725d"
FAMILIES = {
    "A": "Kho báu nắp vòm",
    "B": "Hòm bọc sắt",
    "C": "Kiện carton",
    "D": "Hòm du hành",
}
TIERS = ("Gỗ", "Bạc", "Vàng")
FONT = ROOT / "game/ui/fonts/PaytoneOne-Regular.ttf"


def font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT), size)


def text(draw, xy, value, size=24, fill=INK, anchor=None):
    draw.text(xy, value, font=font(size), fill=fill, anchor=anchor,
              stroke_width=0)


def matte_crop(tile: Image.Image):
    """Remove only a demonstrably simple light matte connected to the border.

    White enclosed inside the object is preserved. No color correction,
    palette replacement, edge tracing or inpainting is performed.
    """
    rgba = np.array(tile.convert("RGBA"))
    rgb = rgba[:, :, :3].astype(np.int16)
    h, w = rgba.shape[:2]
    k = max(4, min(w, h) // 32)
    corners = np.concatenate([
        rgb[:k, :k].reshape(-1, 3), rgb[:k, -k:].reshape(-1, 3),
        rgb[-k:, :k].reshape(-1, 3), rgb[-k:, -k:].reshape(-1, 3),
    ])
    bg = np.median(corners, axis=0)
    spread = float(np.percentile(np.abs(corners - bg), 95))
    simple = bool(bg.min() >= 215 and bg.max() - bg.min() <= 26
                  and spread <= 15)
    removed = 0
    if simple and rgba[:, :, 3].min() > 240:
        candidate = (np.max(np.abs(rgb - bg), axis=2) <= 24)
        # fromarray may expose a read-only buffer; floodfill needs owned pixels.
        mask = Image.fromarray(np.uint8(candidate) * 255).copy()
        # Flood every border-connected component; a silhouette may touch and
        # divide the matte. Pixels enclosed by ink are never reached.
        for x in range(w):
            for y in (0, h - 1):
                if mask.getpixel((x, y)) == 255:
                    ImageDraw.floodfill(mask, (x, y), 128, thresh=0)
        for y in range(h):
            for x in (0, w - 1):
                if mask.getpixel((x, y)) == 255:
                    ImageDraw.floodfill(mask, (x, y), 128, thresh=0)
        outside = np.asarray(mask) == 128
        removed = int(outside.sum())
        # Fail closed if the estimate barely finds any background.
        if removed >= w * h * 0.12:
            rgba[outside, 3] = 0
        else:
            removed = 0
    result = Image.fromarray(rgba)
    bbox = result.getbbox()
    if bbox is None:
        raise ValueError("A source third contains no visible image")
    # Keep a small transparent margin around the exact surviving pixels.
    pad = max(3, round(max(w, h) * 0.008))
    bbox = (max(0, bbox[0] - pad), max(0, bbox[1] - pad),
            min(w, bbox[2] + pad), min(h, bbox[3] + pad))
    return result.crop(bbox), {
        "simple_matte_detected": simple,
        "estimated_matte_rgb": [round(float(c)) for c in bg],
        "matte_corner_spread": round(spread, 2),
        "border_matte_pixels_removed": removed,
        "content_crop": list(bbox),
    }


def segment_boundaries(source: Image.Image):
    """Find empty vertical gutters; generated spacing is not equal thirds."""
    rgba = np.asarray(source.convert("RGBA"))
    rgb = rgba[:, :, :3].astype(np.int16)
    # Brown outlines remain much darker than the off-white source matte.
    ink = (rgb.mean(axis=2) < 175) & (rgb.min(axis=2) < 150)
    ink &= rgba[:, :, 3] > 32
    counts = ink.sum(axis=0)
    w = source.width
    boundaries = [0]
    for target in (w / 3, 2 * w / 3):
        lo, hi = max(1, round(target - w * .10)), min(w - 1, round(target + w * .10))
        gaps, start = [], None
        for x in range(lo, hi + 1):
            clear = x < hi and counts[x] <= 2
            if clear and start is None:
                start = x
            elif not clear and start is not None:
                if x - start >= 3:
                    gaps.append((start, x))
                start = None
        if not gaps:
            raise ValueError(f"No clear object gutter near x={target:.0f}; inspect the source before cropping")
        gap = min(gaps, key=lambda pair: abs((pair[0] + pair[1]) / 2 - target))
        boundaries.append(round((gap[0] + gap[1]) / 2))
    boundaries.append(w)
    return boundaries


def place(canvas, image, rect, factor=1.0):
    """Uniformly contain visible pixels; never stretch an individual design."""
    x, y, w, h = rect
    scale = min(w / image.width, h / image.height) * factor
    size = (max(1, round(image.width * scale)),
            max(1, round(image.height * scale)))
    fitted = image.resize(size, Image.Resampling.LANCZOS)
    canvas.alpha_composite(fitted, (round(x + (w - size[0]) / 2),
                                    round(y + (h - size[1]) / 2)))


def panel(canvas, rect):
    ImageDraw.Draw(canvas).rounded_rectangle(rect, radius=20, fill=PANEL)


def family_sheet(code, images, output):
    canvas = Image.new("RGBA", (1500, 690), PAPER)
    draw = ImageDraw.Draw(canvas)
    text(draw, (40, 24), f"{code} · {FAMILIES[code]}", 42)
    text(draw, (42, 91), "Ba cấp rương · bản phác thảo để chọn thiết kế", 21,
         MUTED)
    for i, image in enumerate(images):
        x = 30 + i * 490
        panel(canvas, (x, 142, x + 460, 647))
        text(draw, (x + 24, 161), f"{code}{i + 1} · {TIERS[i]}", 29)
        place(canvas, image, (x + 28, 224, 404, 375), [0.88, 0.94, 1][i])
    canvas.convert("RGB").save(output / f"family-{code}.png")


def overview(rows, output):
    height = 172 + len(rows) * 365 + 74
    canvas = Image.new("RGBA", (1500, height), SAGE)
    draw = ImageDraw.Draw(canvas)
    text(draw, (36, 22), "CHỌN THIẾT KẾ RƯƠNG", 43)
    text(draw, (38, 85), "4 hướng tạo hình · có thể chọn cả bộ hoặc ghép từng mẫu", 23,
         MUTED)
    for i, tier in enumerate(TIERS):
        text(draw, (470 + i * 404, 139), tier, 23, anchor="mm")
    for row, (code, images) in enumerate(rows.items()):
        y = 177 + row * 365
        text(draw, (34, y + 28), code, 54)
        # Short two-line family titles keep the artwork comparison spacious.
        parts = {"A": ["Kho báu", "nắp vòm"], "B": ["Hòm", "bọc sắt"],
                 "C": ["Kiện", "carton"], "D": ["Hòm", "du hành"]}[code]
        for j, line in enumerate(parts):
            text(draw, (36, y + 111 + j * 37), line, 27)
        for i, image in enumerate(images):
            x = 268 + i * 404
            panel(canvas, (x, y, x + 384, y + 340))
            text(draw, (x + 19, y + 13), f"{code}{i + 1}", 27)
            place(canvas, image, (x + 20, y + 62, 344, 248),
                  [0.88, 0.94, 1][i])
    text(draw, (38, height - 49),
         "Ảnh ý tưởng · chưa thay rương trong game · chọn bằng mã A1–D3", 21,
         MUTED)
    canvas.convert("RGB").save(output / "overview.png")


def proofs(rows, output):
    canvas = Image.new("RGBA", (1500, 142 + len(rows) * 220), SAGE)
    draw = ImageDraw.Draw(canvas)
    text(draw, (34, 23), "KIỂM TRA KHI THU NHỎ", 36)
    text(draw, (36, 79), "Mỗi mẫu được đặt trong ô 96 px và 64 px, giữ nguyên tỉ lệ", 21,
         MUTED)
    for row, (code, images) in enumerate(rows.items()):
        y = 140 + row * 220
        for i, image in enumerate(images):
            x = 30 + i * 490
            panel(canvas, (x, y, x + 460, y + 194))
            text(draw, (x + 20, y + 15), f"{code}{i + 1} · {TIERS[i]}", 24)
            place(canvas, image, (x + 58, y + 65, 96, 96))
            place(canvas, image, (x + 270, y + 81, 64, 64))
            text(draw, (x + 106, y + 177), "96 px", 16, anchor="mm")
            text(draw, (x + 302, y + 177), "64 px", 16, anchor="mm")
    canvas.convert("RGB").save(output / "small-size-proof.png")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-dir", type=Path, default=DEFAULT_INPUT)
    parser.add_argument("--output-dir", type=Path, default=HERE)
    parser.add_argument("--available", action="store_true",
                        help="Build only source rows that currently exist")
    args = parser.parse_args()
    sources = {code: args.input_dir / f"{code}-raw.png" for code in FAMILIES}
    # Keep the first carton sheet intact; prefer the reviewed construction fix.
    carton_v2 = args.input_dir / "C-v2-raw.png"
    if carton_v2.is_file():
        sources["C"] = carton_v2
    missing = [str(path) for path in sources.values() if not path.is_file()]
    if missing and not args.available:
        parser.error("Missing source rows; use --available for a partial review:\n"
                     + "\n".join(missing))
    sources = {code: path for code, path in sources.items() if path.is_file()}
    if not sources:
        parser.error("No source rows exist yet; no review files were written")
    output = args.output_dir
    (output / "png").mkdir(parents=True, exist_ok=True)
    rows, metadata = {}, {}
    for code, path in sources.items():
        with Image.open(path) as source:
            source = source.convert("RGBA")
            boundaries = segment_boundaries(source)
            images, items = [], []
            for i in range(3):
                box = (boundaries[i], 0, boundaries[i + 1], source.height)
                image, details = matte_crop(source.crop(box))
                image.save(output / "png" / f"{code}{i + 1}.png")
                images.append(image)
                items.append({"code": f"{code}{i + 1}", "tier": TIERS[i],
                              "source_segment": list(box), **details})
            rows[code] = images
            metadata[code] = {"title": FAMILIES[code],
                              "source": path.relative_to(ROOT).as_posix()
                              if path.is_relative_to(ROOT) else str(path),
                              "source_size": list(source.size),
                              "segment_boundaries": boundaries, "items": items}
        family_sheet(code, images, output)
    overview(rows, output)
    proofs(rows, output)
    report = {"families": metadata, "production_changed": False,
              "processing": "Dark-outline projection detects clear gutters; optional border-connected light matte removal; uniform resizing only"}
    (output / "review-manifest.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    (output / "review-data.js").write_text(
        "window.CHEST_REVIEW = " + json.dumps(report, ensure_ascii=False) + ";\n",
        encoding="utf-8")
    print(f"Built {len(rows)} families / {3 * len(rows)} concepts in {output}")


if __name__ == "__main__":
    main()
