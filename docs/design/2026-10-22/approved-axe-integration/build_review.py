"""Compare the saved pre-integration art with the actual installed PNGs."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
ART = ROOT / "game/ui/art"
FONT = ImageFont.truetype(str(ROOT / "game/ui/fonts/PaytoneOne-Regular.ttf"), 22)
board = Image.new("RGB", (760, 550), "#e4e8e2")
draw = ImageDraw.Draw(board)
for x, label in [(16, "TRƯỚC"), (388, "ĐÃ ÁP DỤNG")]:
    draw.rounded_rectangle((x, 16, x + 356, 534), radius=22, fill="#f5f4ec")
    draw.text((x + 178, 35), label, font=FONT, fill="#583f21", anchor="mt")
for x, previous in [(16, True), (388, False)]:
    def source(name):
        return HERE / ("before-" + name) if previous else ART / name
    icon = Image.open(source("icon_hero_w_riu.png")).convert("RGBA")
    board.paste(icon, (x + 50, 80), icon)
    hero = Image.open(source("hero_cat_heavy.png")).convert("RGBA")
    hero = hero.resize((192, 180), Image.Resampling.LANCZOS)
    board.paste(hero, (x + 82, 330), hero)
board.save(HERE / "production-review.png")
