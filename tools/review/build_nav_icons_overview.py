"""Build the sword/shield comparison from the native Godot captures."""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2] / "docs/ui_review/2026-10-19"
OUT = ROOT / "nav-icons"

canvas = Image.new("RGB", (752, 650), "#e9dfcd")
draw = ImageDraw.Draw(canvas)
title = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 24)
label = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 18)
draw.text((22, 16), "Kiếm & khiên · thiết kế mới", fill="#583f21", font=title)

sheet = Image.open(OUT / "icon_sizes_32_48_64_96_128.png").convert("RGB")
for row, x, text in [(0, 220, "Chiến"), (1, 388, "Lính")]:
    canvas.paste(sheet.crop((576, row * 144, 720, (row + 1) * 144)), (x, 58))
    draw.text((x + 72, 210), text, fill="#583f21", font=label, anchor="mt")

draw.text((22, 256), "Trước", fill="#583f21", font=label)
before = Image.open(ROOT / "screens/01_lobby.png").convert("RGB")
canvas.paste(before.crop((0, 1120, 720, 1280)), (16, 284))
draw.text((22, 464), "Sau · trong game", fill="#583f21", font=label)
canvas.paste(Image.open(OUT / "battle_720x1280_nav.png").convert("RGB"), (16, 490))
canvas.save(OUT / "before_after.png")
