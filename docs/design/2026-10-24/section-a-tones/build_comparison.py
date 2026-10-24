"""Native in-game A header: accepted flat treatment beside a two-tone preview."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
PROJECT = ROOT.parents[3]
FONT = PROJECT / "game/ui/fonts/PaytoneOne-Regular.ttf"
title_font = ImageFont.truetype(str(FONT), 27)
label_font = ImageFont.truetype(str(FONT), 23)
note_font = ImageFont.truetype(str(FONT), 17)

padding, gap, width, height, title_height, label_height = 24, 24, 450, 800, 100, 48
board = Image.new("RGB", (padding * 2 + width * 2 + gap, title_height + label_height + height + padding), "#eeede5")
draw = ImageDraw.Draw(board)
draw.text((padding, 12), "A · MẢNG MÀU SÁNG–TỐI", font=title_font, fill="#3e493b")
draw.text((padding, 55), "Cùng lề, viền và kích thước · So sánh trong game", font=note_font, fill="#626650")
samples = [("flat", "A · Màu phẳng"), ("two-tone", "A · Mảng sáng–tối")]
probes = []
for index, (file_name, title) in enumerate(samples):
    native = Image.open(ROOT / "native" / f"{file_name}.png").convert("RGB")
    if native.size != (450, 800):
        raise ValueError(f"Unexpected native dimensions for {file_name}: {native.size}")
    x = padding + index * (width + gap)
    draw.text((x, title_height + 4), title, font=label_font, fill="#3e493b")
    board.paste(native, (x, title_height + label_height))
    probes.append({"sample": file_name, "upper_fill_pixel": list(native.getpixel((50, 77))),
                   "lower_fill_pixel": list(native.getpixel((50, 95)))})
if probes[0]["upper_fill_pixel"] != probes[0]["lower_fill_pixel"]:
    raise ValueError("Flat sample contains an unexpected color split at the probe points")
if probes[1]["upper_fill_pixel"] == probes[1]["lower_fill_pixel"]:
    raise ValueError("Two-tone sample does not contain a visible color split")
board.save(ROOT / "comparison.png")
(ROOT / "pixel-review.json").write_text(json.dumps(probes, indent=2) + "\n", encoding="utf-8")
print(f"SECTION_A_COMPARISON_COMPLETE {board.size[0]}x{board.size[1]}")
