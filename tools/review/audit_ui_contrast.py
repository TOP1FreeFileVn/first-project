"""Measure source palette contrast and document native Godot text sizes.

Uses WCAG relative sRGB luminance. Pixel samples are diagnostic only: text with a
continuous halo must be assessed against that halo, and raster antialiasing and
tiny glyphs still need visual review. This is not an automatic conformance test.
"""
from collections import Counter
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/ui_review/2026-10-19/contrast"


def rgb(hex_color):
    value = hex_color.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def luminance(color):
    channels = [channel / 255 for channel in color]
    channels = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in channels]
    return sum(c * weight for c, weight in zip(channels, (0.2126, 0.7152, 0.0722)))


def contrast(first, second):
    high, low = sorted((luminance(first), luminance(second)), reverse=True)
    return (high + 0.05) / (low + 0.05)


PAIRS = [
    ("shortcut caption / cream", "#583f21", "#fff0d3", "Ui.gd rail_item; shortcut_*.svg"),
    ("Castle white fill / Board", "#ffffff", "#dabf96", "CastlePage.gd; board.svg"),
    ("Castle INFO fill / Board", "#fff2c2", "#dabf96", "UiKit.INFO; board.svg"),
    ("Castle gold fill / Board", "#ffd35c", "#dabf96", "UiKit.GOLD_TEXT; board.svg"),
    ("text outline / Board", "#2e1c1c", "#dabf96", "build_theme.gd; board.svg"),
    ("white fill / text outline", "#ffffff", "#2e1c1c", "build_theme.gd"),
    ("white fill / yellow button", "#ffffff", "#f5de73", "btn_yellow.svg"),
    ("outline / yellow button", "#2e1c1c", "#f5de73", "btn_yellow.svg"),
    ("white fill / red button", "#ffffff", "#f25a5a", "btn_red.svg"),
    ("outline / red button", "#2e1c1c", "#f25a5a", "btn_red.svg"),
    ("white fill / green reward card", "#ffffff", "#7ac85f", "card_unit_green.svg"),
    ("white fill / blue reward card", "#ffffff", "#5eaedc", "card_unit_blue.svg"),
    ("white fill / purple reward card", "#ffffff", "#ad7fdf", "card_unit_purple.svg"),
    ("white fill / orange reward card", "#ffffff", "#f2a866", "card_unit_orange.svg"),
    ("outline / green reward card", "#2e1c1c", "#7ac85f", "card_unit_green.svg"),
    ("outline / purple reward card", "#2e1c1c", "#ad7fdf", "card_unit_purple.svg"),
    ("grid open / Board", "#5d8a4a", "#dabf96", "GridPreview.gd; board.svg"),
    ("grid future / Board", "#c9a14a", "#dabf96", "GridPreview.gd; board.svg"),
    ("grid open / future", "#5d8a4a", "#c9a14a", "GridPreview.gd"),
    ("grid future border / future", "#ffe89a", "#c9a14a", "GridPreview.gd"),
    ("grid future border / Board", "#ffe89a", "#dabf96", "GridPreview.gd; board.svg"),
    ("green progress / track", "#7fd66b", "#3a2a1c", "ChestOpening.gd _make_card; UiKit.bar"),
    ("blue progress / track", "#5aa9e6", "#3a2a1c", "ChestOpening.gd _make_card; UiKit.bar"),
    ("disabled text / grey button", "#f2f2f2", "#c3c3c3", "build_theme.gd; btn_grey.svg; inactive exemption"),
    ("proposed Castle ink / Board", "#3b2b1e", "#dabf96", "UiKit.INK; proposal only"),
    ("proposed dark grid border / future", "#583f21", "#c9a14a", "Ui.LINE; proposal only"),
]


def pixel_diagnostics(capture):
    foreground_image = Image.open(OUT / capture["file"]).convert("RGB")
    background_image = Image.open(OUT / capture["background"]).convert("RGB")
    results = []
    for label in capture["labels"]:
        foreground = rgb(label["fill"])
        x, y, width, height = label["render_rect"]
        rect = (max(0, math.floor(x)), max(0, math.floor(y)), min(foreground_image.width, math.ceil(x + width)), min(foreground_image.height, math.ceil(y + height)))
        samples = []
        for normal, blank in zip(foreground_image.crop(rect).get_flattened_data(), background_image.crop(rect).get_flattened_data()):
            # Near-solid fill pixels only. Never classify whole label rectangles,
            # which also contain portraits/icons or background variation.
            if max(abs(a - b) for a, b in zip(normal, blank)) > 12 and max(abs(a - b) for a, b in zip(normal, foreground)) <= 24:
                samples.append(blank)
        result = dict(label)
        result["solid_fill_samples"] = len(samples)
        result["fill_to_outline_ratio"] = round(contrast(foreground, rgb(label["outline"])), 3) if label["render_outline_size"] > 0 else None
        if samples:
            ratios = sorted(contrast(foreground, sample) for sample in samples)
            result["sampled_fill_to_background_p10_p90"] = [round(ratios[int((len(ratios) - 1) * fraction)], 3) for fraction in (0.1, 0.9)]
            result["most_common_background"] = "#" + "".join(f"{c:02x}" for c in Counter(samples).most_common(1)[0][0])
        results.append(result)
    return {"file": capture["file"], "labels": results}


def overview():
    canvas = Image.new("RGB", (1120, 940), "#e9dfcd")
    draw = ImageDraw.Draw(canvas)
    title = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 25)
    caption = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 19)
    body = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 18)
    ink, amber, red = "#583f21", "#e69b15", "#dc3d36"
    draw.text((12, 12), "Tương phản & độ dễ đọc · ảnh gốc 360 × 640", fill=ink, font=title)
    columns = [
        (12, "castle_360x640.png", "Thành · phân biệt ô", [(112, 345, 243, 432, red), (25, 437, 330, 448, amber)], ["Ô xanh / vàng: 1,67:1", "Viền vàng / nền ô: 1,99:1", "Chú giải nhỏ: 7 px"]),
        (380, "castle_workshop_360x640.png", "Xưởng · chữ mô tả", [(25, 350, 239, 363, amber), (25, 417, 239, 430, amber), (25, 484, 239, 510, amber)], ["Mô tả: 8 px; viền: 2,5 px", "Chữ / nền: 1,58:1", "Viền / nền: 9,14:1"]),
        (748, "chest_two_360x640.png", "Rương · nhãn trên thẻ", [(84, 261, 172, 275, amber), (187, 261, 275, 275, amber)], ["Nhãn 2 thẻ: 8,4 px", "Nhãn nhiều thẻ: 6,45 px*", "Thẻ xanh: viền / nền 7,89:1"]),
    ]
    for x, filename, label, boxes, notes in columns:
        draw.text((x, 53), label, fill=ink, font=caption)
        shot = Image.open(OUT / filename).convert("RGB")
        if shot.size != (360, 640):
            raise ValueError(filename)
        canvas.paste(shot, (x, 86))
        for x0, y0, x1, y1, color in boxes:
            draw.rectangle((x + x0, 86 + y0, x + x1, 86 + y1), outline=color, width=2)
        for i, note in enumerate(notes):
            draw.text((x, 745 + 27 * i), note, fill=ink, font=body)
    draw.text((12, 843), "Đỏ: trạng thái ô cần rõ hơn. Cam: chữ nhỏ cần rà lại, không tự kết luận thiếu tương phản.", fill=ink, font=body)
    draw.text((12, 875), "Viền chữ được đo riêng; không chấm rớt chỉ vì chữ trắng trên nền sáng.", fill=ink, font=body)
    draw.text((12, 907), "* Theo scale 0,86 của thẻ nhiều thưởng; đã kiểm tra ảnh trong chest-layout.", fill=ink, font=body)
    canvas.save(OUT / "overview.png")


if __name__ == "__main__":
    manifest = json.loads((OUT / "manifest.json").read_text(encoding="utf-8"))
    palette = [{"pair": name, "foreground": first, "background": second, "ratio": round(contrast(rgb(first), rgb(second)), 3), "source": source} for name, first, second, source in PAIRS]
    report = {"method": "WCAG sRGB relative luminance; halo and readability reviewed separately", "scope": "lobby, Castle, workshop, chest result", "palette": palette, "captures": [pixel_diagnostics(capture) for capture in manifest["captures"]]}
    (OUT / "measurements.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    overview()
    for pair in palette:
        print(f"{pair['ratio']:.3f} {pair['pair']}")
