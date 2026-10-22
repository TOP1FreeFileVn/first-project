"""Label direct Godot renders of the production B gear palette."""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

here = Path(__file__).resolve().parent
root = here.parents[3]
out = here / "godot"
font_path = root / "game/ui/fonts/PaytoneOne-Regular.ttf"
title = ImageFont.truetype(str(font_path), 22)
font = ImageFont.truetype(str(font_path), 16)
small = ImageFont.truetype(str(font_path), 13)
tones = ["tier_1", "tier_2", "tier_3", "tier_4", "tier_5", "idle"]
rims = ["#ead5ac", "#80bfd7", "#b49cd6", "#eead6c", "#aec778", "#aaa995"]
sheet = Image.new("RGB", (1008, 354), "#e8dcc4")
draw = ImageDraw.Draw(sheet)
draw.text((22, 14), "B · 5 màu cấp + bánh không được dẫn động", font=title, fill="#583f21")
draw.text((22, 48), "Raster trực tiếp 6 SVG production · lòng màu phẳng, không viền phụ", font=small, fill="#785a31")
checks = {}
for index, (tone, rim) in enumerate(zip(tones, rims)):
    x = 12 + index * 166
    image = Image.open(out / f"B-production-{tone}.png").convert("RGBA")
    center = "#d2cbb8" if tone == "idle" else "#f4dfb4"
    rgb = lambda value: tuple(bytes.fromhex(value.lstrip("#")))
    checks[tone] = {"rim_pixel": image.getpixel((102, 73))[:3] == rgb(rim),
                    "center_pixel": image.getpixel((64, 64))[:3] == rgb(center),
                    "rim": rim, "center": center}
    assert checks[tone]["rim_pixel"] and checks[tone]["center_pixel"], checks[tone]
    sheet.paste(image, (x + 19, 84), image)
    draw.text((x + 83, 215), "Chưa nối trục" if tone == "idle" else f"Cấp {index + 1}", font=font, fill="#583f21", anchor="mt")
    native = image.resize((80, 80), Image.Resampling.LANCZOS)
    sheet.paste(native, (x + 43, 247), native)
draw.text((504, 331), "Hàng dưới: kích thước thật 80 px trên màn rộng 450", font=small, fill="#785a31", anchor="mt")
sheet.save(out / "B-production-palette.png")
(out / "B-production-palette-checks.json").write_text(json.dumps(checks, indent=2) + "\n", encoding="utf-8")
print("Saved B-production-palette.png; 12 native fill-color checks passed.")
