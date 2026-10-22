from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

here = Path(__file__).resolve().parent
root = here.parents[3]
font = ImageFont.truetype(str(root / "game/ui/fonts/PaytoneOne-Regular.ttf"), 22)
board = Image.new("RGB", (1398, 862), "#e4e9e2")
draw = ImageDraw.Draw(board)
for i, (title, file) in enumerate([
    ("THÀNH NGOÀI SẢNH", "after-lobby_450x800.png"),
    ("TRẬN · TRƯỚC", "before-fight_450x800.png"),
    ("TRẬN · DEMO MỚI", "after-fight_450x800.png"),
]):
    x = 12 + i * 462
    draw.text((x + 225, 12), title, font=font, fill="#583f21", anchor="mt")
    board.paste(Image.open(here / file).convert("RGB"), (x, 50))
board.save(here / "comparison.png")
print("Saved lobby/battle comparison from actual game captures.")
