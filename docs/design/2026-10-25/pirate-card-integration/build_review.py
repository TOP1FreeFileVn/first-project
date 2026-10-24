"""Review the actual four pirate cards after integrating the accepted ship."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
PROJECT = ROOT.parents[3]
FONT = PROJECT / "game/ui/fonts/PaytoneOne-Regular.ttf"
OUT = ROOT / "native"


def font(size):
    return ImageFont.truetype(str(FONT), size)


report = json.loads((OUT / "review.json").read_text(encoding="utf-8"))
if report["failures"]:
    raise RuntimeError("Fix the native card review before delivery")
board = Image.new("RGB", (1280, 1100), "#f1eadc")
draw = ImageDraw.Draw(board)
ink, muted = "#583f21", "#74614a"
draw.text((40, 24), "THẺ HẢI TẶC · THUYỀN ĐÃ DUYỆT", font=font(38), fill=ink)
draw.text((42, 84), "Bốn thẻ trong game · Thân tàu phía trước · Buồm và cột phía sau", font=font(22), fill=muted)
hero = Image.open(OUT / "card-cu_kiem@3x.png").convert("RGBA")
board.paste(hero, (42, 152), hero)
draw.text((650, 190), "MÈO ĐỨNG TRONG TÀU", font=font(29), fill=ink)
draw.text((650, 250), "Giữ nguyên dáng thuyền đã duyệt.", font=font(23), fill=ink)
draw.text((650, 293), "Tách lớp để mạn tàu che phía trước.", font=font(23), fill=ink)
draw.text((650, 336), "Mèo nhỏ hơn để nhìn rõ boong và buồm.", font=font(23), fill=ink)
draw.text((650, 420), "VIỀN GIỮ MÀU ĐỘ HIẾM", font=font(27), fill=ink)
for index, (name, color) in enumerate([
    ("Thường", "#b9c3cc"), ("Hiếm", "#5aa9e6"),
    ("Sử thi", "#c28bff"), ("Huyền thoại", "#ffb938"),
]):
    x, y = 652 + (index % 2) * 265, 478 + (index // 2) * 62
    draw.rounded_rectangle((x, y, x + 33, y + 33), radius=7, fill=color, outline=ink, width=3)
    draw.text((x + 47, y - 1), name, font=font(22), fill=ink)
draw.text((42, 721), "CÙNG THUYỀN · BỐN BẢN THỂ", font=font(28), fill=ink)
for index, (troop_id, title) in enumerate([
    ("cu_kiem", "Mướp · Hiếm"), ("gay_phep", "Tro · Thường"),
    ("dai_bac", "Tam · Huyền thoại"), ("dao", "Bơ · Sử thi"),
]):
    x = 42 + index * 300
    draw.text((x + 14, 775), title, font=font(21), fill=ink)
    card = Image.open(OUT / f"card-{troop_id}@3x.png").convert("RGBA")
    card = card.resize((270, 255), Image.Resampling.LANCZOS)
    board.paste(card, (x, 810), card)
draw.text((42, 1070), "Áp dụng trước cho bốn thẻ Hải Tặc · Giữ kéo thả, mở chi tiết và chỉ báo nâng cấp", font=font(17), fill=muted)
board.save(ROOT / "review.png")
print(f"PIRATE_CARD_INTEGRATION_BOARD_COMPLETE {board.width}x{board.height}")
