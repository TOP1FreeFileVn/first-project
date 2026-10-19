from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
font = ImageFont.truetype(str(ROOT / "game/ui/fonts/PaytoneOne-Regular.ttf"), 22)
canvas = Image.new("RGB", (948, 880), "#eee8db")
draw = ImageDraw.Draw(canvas)

for x, key, label in [(16, "current", "Hiện tại"), (482, "demo", "Demo · Bầu trời và đảo bay")]:
    preview = Image.open(HERE / f"{key}.png").convert("RGB")
    preview = preview.resize((450, 800), Image.Resampling.LANCZOS)
    canvas.paste(preview, (x, 62))
    draw.text((x + 225, 29), label, font=font, fill="#583f21", anchor="mm")

canvas.save(HERE / "comparison.png")
print(HERE / "comparison.png")
