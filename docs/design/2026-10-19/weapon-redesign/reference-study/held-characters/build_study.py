"""Inspect unchanged source characters indexed on Figma page 3443:2."""
from pathlib import Path
import hashlib
import json
import re

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[5]
FONT = ROOT / "game/ui/fonts/PaytoneOne-Regular.ttf"
INK, BG, CARD = "#583f21", "#d8e5df", "#f8f0df"


def font(size):
    return ImageFont.truetype(str(FONT), size)


def place(canvas, source, box):
    im = Image.open(source).convert("RGBA")
    im = im.crop(im.getchannel("A").getbbox())
    im.thumbnail((box[2], box[3]), Image.Resampling.LANCZOS)
    canvas.alpha_composite(im, (round(box[0] + (box[2]-im.width)/2),
                               round(box[1] + (box[3]-im.height)/2)))


def main():
    data = json.loads((ROOT / "docs/asset_reference/figma_assets.json").read_text(encoding="utf-8-sig"))
    assets = {}
    for x in data["assets"]:
        match = re.search(r"/Unit/(Hero\d+)$", x.get("sourcePath", ""))
        if match:
            assets[match[1], x["name"]] = x
    records = []
    for variant in ("1", "6"):
        board = Image.new("RGBA", (1400, 1000), BG)
        draw = ImageDraw.Draw(board)
        draw.text((26, 16), f"NHÂN VẬT & VŨ KHÍ · BIẾN THỂ {variant}", font=font(32), fill=INK)
        draw.text((26, 66), "21 nhóm Hero · PNG tham chiếu giữ nguyên màu · Cắt phần alpha để xem rõ", font=font(18), fill=INK)
        for i in range(1, 22):
            a = assets[f"Hero{i}", variant]
            p = Path(a["file"])
            x, y = 24 + ((i-1) % 7)*196, 116 + ((i-1)//7)*290
            draw.rounded_rectangle((x, y, x+180, y+272), radius=16, fill=CARD)
            place(board, p, (x+10, y+10, 160, 218))
            draw.text((x+36, y+232), f"Hero{i} / {variant}", font=font(18), fill=INK)
            records.append({"hero": f"Hero{i}", "variant": variant, "figma_node": a["pngNode"],
                            "file": str(p), "sha256": hashlib.sha256(p.read_bytes()).hexdigest()})
        board.convert("RGB").save(HERE/f"heroes-variant-{variant}.png")
    chosen = [("Hero2", "1", "Kiếm"), ("Hero6", "1", "Rìu"), ("Hero4", "6", "Giáo"),
              ("Hero8", "6", "Gậy phép"), ("Hero9", "4", "Nỏ"), ("Hero16", "6", "Sách phép")]
    (HERE/"samples").mkdir(exist_ok=True)
    board = Image.new("RGBA", (1440, 590), BG)
    draw = ImageDraw.Draw(board)
    draw.text((28, 16), "TƯ THẾ CẦM · MẢNG MÀU · KHOẢNG HỞ", font=font(32), fill=INK)
    draw.text((28, 68), "Mẫu gốc từ trang 3443:2 · Ảnh lớn để xem cấu tạo / bên dưới là PNG ở 128 × 128", font=font(18), fill=INK)
    for i, (hero, variant, label) in enumerate(chosen):
        a = assets[hero, variant]
        p = Path(a["file"])
        (HERE/"samples"/f"{hero}_{variant}.png").write_bytes(p.read_bytes())
        x = 24 + i*236
        draw.rounded_rectangle((x, 118, x+216, 562), radius=16, fill=CARD)
        place(board, p, (x+8, 134, 200, 230))
        draw.text((x+20, 372), label, font=font(22), fill=INK)
        im = Image.open(p).convert("RGBA").resize((128,128), Image.Resampling.LANCZOS)
        board.alpha_composite(im, (x+44, 413))
        draw.text((x+20, 535), f"{hero} / {variant}", font=font(16), fill=INK)
        records.append({"hero": hero, "variant": variant, "role": label, "figma_node": a["pngNode"],
                        "file": str(p), "sha256": hashlib.sha256(p.read_bytes()).hexdigest()})
    board.convert("RGB").save(HERE/"held-weapon-examples.png")
    (HERE/"sources.json").write_text(json.dumps({"file_key":"wMtwWaYIiKUchUdq5YdTm5",
        "page":"3443:2", "records": records, "source_art_modified":False}, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Built two 21-character overviews and six held-weapon examples; {len(records)} source records.")


if __name__ == "__main__":
    main()
