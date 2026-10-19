"""Render review boards from native Godot rasters, including unscaled small icons."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
ITEMS = json.loads((HERE / "assets.json").read_text(encoding="utf-8"))["items"]
FONT = ROOT / "game/ui/fonts/PaytoneOne-Regular.ttf"
INK, MUTED, BG, PAPER = "#583f21", "#70766e", "#d8e5df", "#f8f0df"
WIDTH, MARGIN, GAP, CELL, ROW = 1440, 30, 16, 333, 300


def font(size):
    return ImageFont.truetype(str(FONT), size)


def centered(draw, text, cx, top, size, fill=INK):
    b = draw.textbbox((0, 0), text, font=font(size))
    draw.text((cx - (b[2] - b[0]) / 2, top), text, font=font(size), fill=fill)


def place(canvas, path, box, native=False):
    im = Image.open(path).convert("RGBA")
    if not native:
        im.thumbnail(box[2:], Image.Resampling.LANCZOS)
    canvas.alpha_composite(im, (int(box[0] + (box[2] - im.width) / 2),
                               int(box[1] + (box[3] - im.height) / 2)))


def board(kind):
    height = 135 + 4 * ROW + 42
    canvas = Image.new("RGBA", (WIDTH, height), BG)
    d = ImageDraw.Draw(canvas)
    titles = {"icons": "VŨ KHÍ CASUAL · BẢN 02", "units": "BẢN 02 · KHI MÈO CẦM",
              "comparison": "SO SÁNH BẢN 01 / BẢN 02", "small": "KIỂM TRA Ở KÍCH THƯỚC NHỎ"}
    d.text((MARGIN, 16), titles[kind], font=font(34), fill=INK)
    subtitles = {"icons": "Đầu lớn · Cán gọn · Hình dáng riêng · Màu phẳng theo style mèo",
                 "units": "Cùng nhân vật hiện tại · Vị trí cầm riêng theo từng vũ khí",
                 "comparison": "Cùng kích thước hiển thị để đối chiếu hình dáng và cấu tạo",
                 "small": "48 px và 64 px giữ nguyên kích thước · Silhouette 64 px để nhận diện"}
    d.text((MARGIN, 67), subtitles[kind], font=font(20), fill=MUTED)
    for i, item in enumerate(ITEMS):
        row, col = divmod(i, 4)
        x, y = MARGIN + col * (CELL + GAP), 126 + row * ROW
        if col == 0:
            d.text((MARGIN, y - 15), item["family"].upper(), font=font(19), fill=INK)
        y += 19
        d.rounded_rectangle((x, y, x + CELL, y + 259), radius=22, fill=PAPER, outline="#c2b397", width=2)
        key = item["id"]
        if kind == "icons":
            place(canvas, HERE / "rendered" / f"new_icon_{key}.png", (x + 45, y + 6, CELL - 90, 208))
        elif kind == "units":
            place(canvas, HERE / "rendered" / f"new_unit_{key}.png", (x + 23, y + 3, CELL - 46, 211))
        elif kind == "comparison":
            centered(d, "01", x + CELL * .25, y + 8, 18, MUTED)
            centered(d, "02", x + CELL * .75, y + 8, 18)
            place(canvas, HERE / "rendered" / f"previous_icon_{key}.png", (x + 2, y + 42, 160, 160))
            place(canvas, HERE / "rendered" / f"new_icon_{key}.png", (x + CELL - 162, y + 42, 160, 160))
        else:
            for left, size in ((x + 23, 48), (x + 113, 64)):
                centered(d, str(size) + " px", left + 32, y + 29, 16, MUTED)
                place(canvas, HERE / "rendered" / f"new_{size}_{key}.png", (left, y + 78, 64, 64), native=True)
            small = Image.open(HERE / "rendered" / f"new_64_{key}.png").convert("RGBA")
            silhouette = Image.new("RGBA", small.size, INK)
            silhouette.putalpha(small.getchannel("A"))
            canvas.alpha_composite(silhouette, (x + 227, y + 78))
            centered(d, "Dáng đen", x + 259, y + 29, 16, MUTED)
        centered(d, item["name"], x + CELL / 2, y + 220, 23)
    d.text((MARGIN, height - 31), "Thiết kế để duyệt · Chưa thay vũ khí trong game chính", font=font(17), fill=MUTED)
    filename = {"icons": "weapons-proposal-v2.png", "units": "cats-with-proposal-v2.png",
                "comparison": "v1-vs-v2.png", "small": "native-size-review.png"}[kind]
    canvas.convert("RGB").save(HERE / filename)
    print(filename)


if __name__ == "__main__":
    for kind in ("icons", "units", "comparison", "small"):
        board(kind)
