"""Compare native Godot header proposals using the game's font."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
PROJECT = ROOT.parents[3]
PALETTES = [
    ("A", "Kem mật ong", "f3d79b", "583f21", "503c25"),
    ("B", "Xanh lam", "4d7488", "583f21", "fff3d7"),
    ("C", "Đào đất", "dbaca0", "583f21", "59372f"),
    ("D", "Tím khói", "756986", "583f21", "fff3df"),
]
FONT = PROJECT / "game/ui/fonts/PaytoneOne-Regular.ttf"
label_font = ImageFont.truetype(str(FONT), 23)
title_font = ImageFont.truetype(str(FONT), 27)
note_font = ImageFont.truetype(str(FONT), 17)


def luminance(hex_color):
    channels = [int(hex_color[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    linear = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in channels]
    return sum(c * w for c, w in zip(linear, (0.2126, 0.7152, 0.0722)))


def contrast(a, b):
    high, low = sorted((luminance(a), luminance(b)), reverse=True)
    return (high + 0.05) / (low + 0.05)


padding, gap, shot_width, shot_height, label_height, title_height = 24, 24, 450, 472, 48, 90
tile_height = shot_height + label_height
board = Image.new("RGB", (2 * padding + 2 * shot_width + gap, title_height + padding + 2 * tile_height + gap + padding), "#eeede5")
draw = ImageDraw.Draw(board)
draw.text((padding, 12), "THANH PHÂN VÙNG · 4 LỰA CHỌN", font=title_font, fill="#3e493b")
draw.text((padding, 55), "Chừa lề hai bên · Viền chuẩn UI game", font=note_font, fill="#626650")
report = []
for index, (key, name, fill, border, text) in enumerate(PALETTES):
    native = Image.open(ROOT / "native" / f"{key}.png").convert("RGB")
    if native.size != (450, 800):
        raise ValueError(f"{key}: unexpected native capture size {native.size}")
    ratio = contrast(fill, text)
    if ratio < 4.5:
        raise ValueError(f"{key}: insufficient text contrast {ratio:.2f}")
    x = padding + (index % 2) * (shot_width + gap)
    y = title_height + padding + (index // 2) * (tile_height + gap)
    draw.rounded_rectangle((x, y + 7, x + 32, y + 38), radius=6, fill="#" + fill, outline="#" + border, width=2)
    key_box = draw.textbbox((0, 0), key, font=note_font)
    draw.text((x + (32 - (key_box[2] - key_box[0])) / 2, y + 7), key, font=note_font, fill="#" + text)
    draw.text((x + 44, y + 4), name, font=label_font, fill="#3e493b")
    board.paste(native.crop((0, 0, shot_width, shot_height)), (x, y + label_height))
    report.append({"option": key, "name": name, "fill": fill, "border": border, "text": text,
                   "text_contrast": round(ratio, 3), "side_margin_logical_px": 28,
                   "stroke_logical_px": 4, "stroke_native_px": 2.5,
                   "native_image": f"native/{key}.png", "native_size": list(native.size)})
board.save(ROOT / "comparison.png")
(ROOT / "palette-comparison.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"COMPARISON_COMPLETE {board.size[0]}x{board.size[1]} options={len(report)}")
