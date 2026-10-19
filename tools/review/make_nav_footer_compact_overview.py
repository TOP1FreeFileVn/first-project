"""Native 360px before/after crops; product art is never resized."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/ui_review/2026-10-19/nav-footer-compact"
FONT = Path("C:/Windows/Fonts/arial.ttf")
title_font = ImageFont.truetype(str(FONT), 19)
small_font = ImageFont.truetype(str(FONT), 14)
tabs = ["shop", "hero", "battle", "troops", "summon"]
canvas = Image.new("RGB", (756, 681), "#f7f1e7")
draw = ImageDraw.Draw(canvas)
draw.text((12, 12), "Selected nav: compact caption band", font=title_font, fill="#583f21")
draw.text((12, 43), "Before: 27px / 35.1%", font=small_font, fill="#79684f")
draw.text((384, 43), "After: 21px / 27.3%", font=small_font, fill="#79684f")
for index, tab in enumerate(tabs):
    y = 72 + index * 120
    draw.text((12, y), tab.title(), font=small_font, fill="#583f21")
    for x, prefix in [(12, "before"), (384, "")]:
        crop = Image.open(OUT / prefix / f"{tab}_360x640_nav.png").convert("RGB")
        canvas.paste(crop, (x, y + 21))
canvas.save(OUT / "overview.png")
