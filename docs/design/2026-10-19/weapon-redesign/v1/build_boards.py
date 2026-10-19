"""Assemble approval boards from Godot-rendered SVGs."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
FONT = ROOT / "game/ui/fonts/PaytoneOne-Regular.ttf"
ITEMS = json.loads((HERE / "assets.json").read_text(encoding="utf-8"))["items"]
INK = "#583f21"
BG = "#d8e3df"
PAPER = "#f8f0df"
COLORS = ["#7eab70", "#6da9d0", "#aa88ca", "#e1b455"]
WIDTH, MARGIN, GAP = 1480, 32, 20
CELL = (WIDTH - 2 * MARGIN - 3 * GAP) // 4
ROW_HEIGHT = 314


def font(size):
    return ImageFont.truetype(str(FONT), size)


def centered(draw, text, cx, top, size, fill=INK):
    bounds = draw.textbbox((0, 0), text, font=font(size))
    draw.text((cx - (bounds[2] - bounds[0]) / 2, top), text, font=font(size), fill=fill)


def image_at(canvas, path, box):
    image = Image.open(path).convert("RGBA")
    image.thumbnail(box[2:], Image.Resampling.LANCZOS)
    canvas.alpha_composite(image, (int(box[0] + (box[2] - image.width) / 2),
                                   int(box[1] + (box[3] - image.height) / 2)))


def board(kind):
    height = 160 + 4 * ROW_HEIGHT + 46
    canvas = Image.new("RGBA", (WIDTH, height), BG)
    draw = ImageDraw.Draw(canvas)
    titles = {"icons": "VŨ KHÍ · ĐỀ XUẤT 01", "units": "KHI MÈO CẦM VŨ KHÍ MỚI",
              "comparison": "SO SÁNH VŨ KHÍ CŨ / MỚI"}
    draw.text((MARGIN, 21), titles[kind], font=font(35), fill=INK)
    subtitle = "16 mẫu • Màu phẳng, hình khối gọn, viền nâu • Bản chờ duyệt"
    draw.text((MARGIN, 75), subtitle, font=font(20), fill="#6b6757")
    for col in range(4):
        x = MARGIN + col * (CELL + GAP)
        draw.rounded_rectangle((x, 117, x + CELL, 151), radius=12, fill=COLORS[col])
        centered(draw, ITEMS[col]["rarity"], x + CELL / 2, 119, 19)
    for index, item in enumerate(ITEMS):
        row, col = divmod(index, 4)
        y = 164 + row * ROW_HEIGHT
        x = MARGIN + col * (CELL + GAP)
        if col == 0:
            draw.text((MARGIN, y), item["family"].upper(), font=font(21), fill=INK)
        y += 37
        draw.rounded_rectangle((x, y, x + CELL, y + 257), radius=20, fill=PAPER,
                               outline="#bda98d", width=2)
        key = item["id"]
        if kind == "icons":
            image_at(canvas, HERE / "rendered" / f"new_icon_{key}.png", (x, y + 11, CELL, 192))
        elif kind == "units":
            image_at(canvas, HERE / "rendered" / f"new_unit_{key}.png", (x, y + 2, CELL, 209))
        else:
            centered(draw, "Cũ", x + CELL * .25, y + 7, 17, "#797261")
            centered(draw, "Mới", x + CELL * .75, y + 7, 17)
            image_at(canvas, HERE / "rendered" / f"old_icon_{key}.png", (x + 8, y + 41, 144, 144))
            image_at(canvas, HERE / "rendered" / f"new_icon_{key}.png", (x + CELL - 160, y + 32, 152, 160))
        centered(draw, item["name"], x + CELL / 2, y + 214, 23)
    footer = "Bản thiết kế để duyệt. Vũ khí trong bản game chính hiện chưa được thay."
    draw.text((MARGIN, height - 35), footer, font=font(18), fill="#6b6757")
    filename = {"icons": "weapons-proposal.png", "units": "cats-with-proposal.png",
                "comparison": "weapons-before-after.png"}[kind]
    canvas.convert("RGB").save(HERE / filename)
    print(filename)


if __name__ == "__main__":
    for kind in ("icons", "units", "comparison"):
        board(kind)
