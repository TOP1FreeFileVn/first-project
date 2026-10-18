"""Present the refreshed feature icons and native 360px Godot UI captures."""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2] / "docs/ui_review/2026-10-19/event-icons"
canvas = Image.new("RGB", (1120, 916), "#e9dfcd")
draw = ImageDraw.Draw(canvas)
title = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 25)
caption = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 18)
small = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 16)
draw.text((20, 14), "Cửa hàng & sự kiện · nét mèo, bố cục mới", fill="#583f21", font=title)

sheet = Image.open(ROOT / "icon_sizes_32_48_64_96_128.png").convert("RGB")
names = ["Cửa hàng", "Quà 7 ngày", "Nhiệm vụ", "Sự kiện", "Thành", "Tuần tra", "Thời gian", "Quà tặng"]
for row, name in enumerate(names):
    x = 48 + row * 128
    canvas.paste(sheet.crop((584, row * 144 + 8, 712, row * 144 + 136)), (x, 54))
    draw.text((x + 64, 196), name, fill="#583f21", font=small, anchor="mt")

for x, file, text in [(10, "before/lobby_360x640.png", "Trước · sảnh"),
                       (380, "lobby_360x640.png", "Sau · sảnh"),
                       (750, "events_360x640.png", "Sau · cửa sổ sự kiện")]:
    draw.text((x + 4, 232), text, fill="#583f21", font=caption)
    shot = Image.open(ROOT / file).convert("RGB")
    if shot.size != (360, 640):
        raise ValueError(f"Expected native 360px capture: {file} {shot.size}")
    canvas.paste(shot, (x, 266))

canvas.save(ROOT / "overview.png")
