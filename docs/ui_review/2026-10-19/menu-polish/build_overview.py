from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
font = ImageFont.truetype(str(ROOT / "game/ui/fonts/DejaVuSans.ttf"), 22)
board = Image.new("RGB", (938, 854), "#eee8dc")
draw = ImageDraw.Draw(board)
for x, name, title in [
    (12, "lobby_450x800.png", "Menu chính"),
    (476, "battle_prepare_450x800.png", "Trong trận"),
]:
    draw.text((x, 10), title, font=font, fill="#583f21")
    board.paste(Image.open(HERE / name).convert("RGB"), (x, 42))
board.save(HERE / "overview.png")
