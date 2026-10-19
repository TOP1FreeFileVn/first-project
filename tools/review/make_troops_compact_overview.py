"""Arrange native production captures of the four-column roster and compact nav."""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2] / "docs/ui_review/2026-10-19"
OUT = ROOT / "troops-compact"
canvas = Image.new("RGB", (760, 918), "#e9dfcd")
draw = ImageDraw.Draw(canvas)
title = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 24)
caption = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 17)
small = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 16)
ink = "#583f21"


def paste(path, at, expected):
    shot = Image.open(path).convert("RGB")
    assert shot.size == expected, (path, shot.size)
    canvas.paste(shot, at)


draw.text((12, 10), "Lính · lưới 4 cột và bottom bar gọn hơn", font=title, fill=ink)
for x, label, filename in [
    (12, "Đội 3/3 · xem và chọn lính", "starter_all_360x640.png"),
    (388, "Đội 5/5 · cuộn xem tên dài", "late_all_scrolled_360x640.png"),
]:
    draw.text((x, 46), label, font=caption, fill=ink)
    paste(OUT / filename, (x, 74), (360, 640))

draw.text((12, 735), "Bottom bar trước · chân kem 35%", font=caption, fill=ink)
draw.text((388, 735), "Sau · chân kem 27%", font=caption, fill=ink)
paste(ROOT / "nav-footer-compact/before/hero_360x640_nav.png", (12, 765), (360, 87))
paste(ROOT / "nav-footer-compact/hero_360x640_nav.png", (388, 765), (360, 87))
draw.text((12, 877), "Ảnh game thật 360 px · chạm thẻ để xem chi tiết và nâng cấp", font=small, fill=ink)
canvas.save(OUT / "overview.png")
