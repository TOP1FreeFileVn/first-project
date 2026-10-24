"""Review board from native Godot renders; no replacement cat art or text."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
PROJECT = ROOT.parents[3]
FONT = PROJECT / "game/ui/fonts/PaytoneOne-Regular.ttf"
OUT = ROOT / "native"


def font(size):
    return ImageFont.truetype(str(FONT), size)


board = Image.new("RGB", (1280, 1100), "#f1eadc")
draw = ImageDraw.Draw(board)
ink, muted = "#3e3528", "#6d695c"
draw.text((40, 25), "HẢI TẶC · KHUNG THEO PHẨM CHẤT", font=font(39), fill=ink)
draw.text((42, 86), "Tàu trọn đầu–đuôi · Sàn cùng màu gỗ · Thông tin ở đáy khung", font=font(22), fill=muted)

hero = Image.open(OUT / "card-cu_kiem@3x.png").convert("RGBA")
board.paste(hero, (42, 157), hero)
draw.text((650, 177), "VIỀN NHẬN DIỆN ĐỘ HIẾM", font=font(27), fill=ink)
rarities = [
    ("Thường", "#b9c3cc"),
    ("Hiếm", "#5aa9e6"),
    ("Sử thi", "#c28bff"),
    ("Huyền thoại", "#ffb938"),
]
for index, (name, color) in enumerate(rarities):
    y = 237 + index * 58
    draw.rounded_rectangle((652, y, 691, y + 37), radius=8, fill=color, outline="#583f21", width=4)
    draw.text((711, y - 1), name, font=font(25), fill=ink)

draw.text((650, 505), "Nét ngoài nâu 4 px", font=font(23), fill=ink)
draw.text((650, 543), "Dải màu phẩm chất 7 px", font=font(23), fill=ink)
draw.text((650, 597), "Hai đầu tàu nằm gọn trong khung.", font=font(20), fill=muted)
draw.text((650, 629), "Bỏ mảng ván sáng riêng dưới chân.", font=font(20), fill=muted)

draw.text((42, 721), "CÙNG THẾ GIỚI · BỐN BẢN THỂ", font=font(28), fill=ink)
cards = [
    ("cu_kiem", "Mướp · Hiếm"),
    ("gay_phep", "Tro · Thường"),
    ("dai_bac", "Tam · Huyền thoại"),
    ("dao", "Bơ · Sử thi"),
]
for index, (troop_id, title) in enumerate(cards):
    x = 42 + index * 300
    draw.text((x + 14, 775), title, font=font(21), fill=ink)
    card = Image.open(OUT / f"card-{troop_id}@3x.png").convert("RGBA")
    card = card.resize((270, 255), Image.Resampling.LANCZOS)
    board.paste(card, (x, 810), card)

draw.text((42, 1070), "Bản thử để duyệt · Giữ art mèo hiện có · Chưa áp dụng vào game", font=font(17), fill=muted)
board.save(ROOT / "demo.png")
board.save(ROOT / "demo-complete-boat-v6.png")

report = json.loads((OUT / "review.json").read_text(encoding="utf-8"))
if report["failures"]:
    raise RuntimeError("Native review reports failures")
if len(report["cards"]) != 4:
    raise RuntimeError("Expected four pirate identities")
print(f"PIRATE_DEMO_BOARD_COMPLETE {board.width}x{board.height}")
