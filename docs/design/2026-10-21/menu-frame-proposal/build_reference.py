"""Small original-sprite board for the Cat Gunner UI shape study."""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
SOURCE = Path(r"C:/Users/dangp/OneDrive/Documents/first-project/reverse_engineering/CatGunner_1.1.64")
SPRITES = SOURCE / "Assets/Sprite/sharedassets0.assets"
FILES = [
    "Panel_0 (Outline)__882.png", "Panel_0__647.png", "Panel_0 2__562.png",
    "Panel_1 (Outline)__744.png", "Panel_1__723.png", "Panel_2__548.png",
    "Panel_3__540.png", "Panel_4__634.png", "Frame_TableFrame01_Line__799.png",
    "ui 1__577.png", "ui 1 (Outline)__617.png", "ui 1 (Fill)__948.png",
    "ui 2__545.png", "ui 2 (Outline)__975.png", "ui 2 (inside)__505.png",
    "ui 7__710.png", "ui 1 (Small) 3__504.png", "Title_Ribbon_Bg_Green__473.png",
]
FONT = "C:/Windows/Fonts/arial.ttf"
font = ImageFont.truetype(FONT, 15)
title = ImageFont.truetype(FONT, 26)
sheet = Image.new("RGB", (1200, 1230), "#e8ebeb")
d = ImageDraw.Draw(sheet)
d.text((24, 18), "CAT GUNNER 1.1.64 — ORIGINAL UI SPRITES", font=title, fill="#2e4147")
d.text((24, 56), "Extracted source assets • preserved aspect ratio • not an original full-screen layout", font=font, fill="#51666c")
records = []
for i, name in enumerate(FILES):
    source = SPRITES / name
    im = Image.open(source).convert("RGBA")
    x = 20 + (i % 3) * 395
    y = 94 + (i // 3) * 187
    d.rounded_rectangle((x, y, x + 380, y + 173), 12, fill="#ced9da")
    original_size = im.size
    im.thumbnail((350, 126), Image.Resampling.LANCZOS)
    sheet.paste(im, (x + (380 - im.width) // 2, y + 8 + (126 - im.height) // 2), im)
    d.text((x + 12, y + 137), name, font=font, fill="#243b41")
    d.text((x + 12, y + 155), f"{original_size[0]} × {original_size[1]}", font=font, fill="#5b6f73")
    records.append({"source": str(source), "size": original_size, "sha256": hashlib.sha256(source.read_bytes()).hexdigest()})
sheet.save(HERE / "cat-gunner-frame-sources.png")
(HERE / "sources.json").write_text(json.dumps({"reviewed": "2026-10-21", "product": "Cat Gunner", "package": "com.Chodun.CatGunner", "version": "1.1.64", "scope": "Original extracted UI sprites; not a verified runtime screen.", "assets": records}, ensure_ascii=False, indent=2), encoding="utf-8")
print(HERE / "cat-gunner-frame-sources.png")
