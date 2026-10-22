"""Compare native captures under one label; retain every previous review."""
import argparse
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

here = Path(__file__).resolve().parent
root = here.parents[3]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--label", default="layers-v2", choices=["layers-v2", "layers-v3"])
args = parser.parse_args()
label = args.label
tag = label.removeprefix("layers-").upper()
font_path = root / "game/ui/fonts/PaytoneOne-Regular.ttf"
font = ImageFont.truetype(str(font_path), 20)
small = ImageFont.truetype(str(font_path), 15)

panels = [
    ("THÀNH NGOÀI SẢNH", f"{label}-lobby_450x800.png"),
    ("TRẬN · TƯỜNG ĐÁ CŨ", "before-fight_450x800.png"),
    (f"{tag} · TRẬN ĐANG CHẠY", f"{label}-fight_450x800.png"),
    (f"{tag} · CHUẨN BỊ GEAR", f"{label}-prepare_450x800.png"),
]
board = Image.new("RGB", (1860, 896), "#e4e9e2")
draw = ImageDraw.Draw(board)
for index, (title, filename) in enumerate(panels):
    x = 12 + index * 462
    draw.text((x + 225, 12), title, font=font, fill="#583f21", anchor="mt")
    capture = Image.open(here / filename).convert("RGB")
    assert capture.size == (450, 800), (filename, capture.size)
    board.paste(capture, (x, 50))
draw.text(
    (930, 865),
    ("Ảnh chụp Godot thật · Cổng bỏ mái tam giác · Bàn sát mép · Đủ viền hai cạnh thành"
     if label == "layers-v3" else
     "Ảnh chụp Godot thật · Cổng mở, bỏ dốc · Bàn carton giữ nguyên lưới gear 6 × 4"),
    font=small, fill="#583f21", anchor="mt",
)
board.save(here / f"{label}-comparison.png")

# The enlarged join is taken from the live fight, without drawing over pixels.
fight = Image.open(here / f"{label}-fight_450x800.png").convert("RGB")
if label == "layers-v3":
    # Native crop for the user: no annotation, redrawing or resampling.
    fight.crop((0, 310, 450, 750)).save(here / "layers-v3-castle-board.png")
detail = fight.crop((0, 330, 450, 555)).resize((900, 450), Image.Resampling.NEAREST)
crop_board = Image.new("RGB", (924, 514), "#e4e9e2")
crop_draw = ImageDraw.Draw(crop_board)
crop_draw.text((462, 12), "CỔNG MỞ + MÉP BÀN CARTON · PHÓNG 2×", font=font, fill="#583f21", anchor="mt")
crop_board.paste(detail, (12, 50))
crop_board.save(here / f"{label}-gate-table-detail.png")
print(f"Saved {label} comparison and gate/table detail; previous labels preserved.")
