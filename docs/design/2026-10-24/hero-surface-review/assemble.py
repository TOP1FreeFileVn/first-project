"""Assemble native Godot alternatives and four natural skeletal idle clips."""
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
PROJECT = ROOT.parents[3]
NATIVE = ROOT / "native"
REPORT = json.loads((NATIVE / "review.json").read_text(encoding="utf-8"))
FONT = ImageFont.truetype(str(PROJECT / "game/ui/fonts/PaytoneOne-Regular.ttf"), 22)
VARIANTS = [("A · Xanh xám", "#354e50"), ("B · Giấy kem", "#654d3b"), ("C · Tím xám", "#54485f")]
WEAPONS = ["kiem_go", "cung_san", "gay_sao", "riu_lua"]
NAMES = ["Kiếm", "Cung", "Trượng", "Rìu"]


def record(name):
    return next(item for item in REPORT["captures"] if item["file"] == name)


def header_height(name):
    item = record(name)
    return round(item["surface"][3] * item["window"][0] / 720)


def make_comparison():
    panels = []
    for variant, (title, ink) in enumerate(VARIANTS):
        name = f"surface-{variant}_450x800.png"
        with Image.open(NATIVE / name) as source:
            crop = source.convert("RGB").crop((0, 0, 450, header_height(name)))
        panel = Image.new("RGB", (450, crop.height + 45), "#f4f0e8")
        ImageDraw.Draw(panel).text((12, 7), title, font=FONT, fill=ink)
        panel.paste(crop, (0, 45))
        panels.append(panel)
    sheet = Image.new("RGB", (450, sum(p.height for p in panels) + 24), "#f4f0e8")
    y = 0
    for panel in panels:
        sheet.paste(panel, (0, y))
        y += panel.height + 12
    sheet.save(ROOT / "comparison.png")


def make_idle_strip():
    frames = []
    for frame in range(12):
        strip = Image.new("RGB", (4 * 170, 206), "#cbddda")
        draw = ImageDraw.Draw(strip)
        for column, (weapon, title) in enumerate(zip(WEAPONS, NAMES)):
            name = f"{weapon}-idle-{frame:02d}_450x800.png"
            item = record(name)
            stage = item["stage"]
            scale = 450 / 720
            center = (stage[0] + stage[2] / 2) * scale
            with Image.open(NATIVE / name) as source:
                crop = source.convert("RGB").crop((round(center - 85), 0, round(center + 85), 174))
            strip.paste(crop, (column * 170, 0))
            box = draw.textbbox((0, 0), title, font=FONT)
            draw.text((column * 170 + (170 - box[2]) / 2, 176), title, font=FONT, fill="#354e50")
        frames.append(strip)
    frames[0].save(ROOT / "four-weapon-idle.gif", save_all=True, append_images=frames[1:], duration=120, loop=0, optimize=True)


def check_equipment_preserved():
    # Compare opaque card interiors. Edge antialiasing correctly blends into
    # each different outer surface, so transparent corners are excluded.
    boxes = [(22, 25, 79, 79), (22, 112, 79, 165), (373, 25, 429, 79), (373, 112, 429, 165)]
    from PIL import ImageChops
    images = [Image.open(NATIVE / f"surface-{i}_450x800.png").convert("RGB") for i in range(3)]
    for index, box in enumerate(boxes):
        first = images[0].crop(box)
        for variant in (1, 2):
            if ImageChops.difference(first, images[variant].crop(box)).getbbox() is not None:
                raise AssertionError(f"Equipment card {index} changed in variant {variant}")
    print("Opaque equipment card interiors are identical across the three alternatives.")


def make_open_review(slug="open"):
    report = json.loads((NATIVE / f"{slug}-review.json").read_text(encoding="utf-8"))
    records = {item["file"]: item for item in report["captures"]}
    name = f"{slug}_450x800.png"
    item = records[name]
    height = round(item["surface"][3] * 450 / 720)
    with Image.open(NATIVE / name) as source:
        source.crop((0, 0, 450, height)).save(ROOT / f"{slug}-detail.png")
    frames = []
    crop_height = 217 if slug == "framed" else 199
    for frame in range(12):
        strip = Image.new("RGB", (4 * 170, crop_height + 32), "#405361")
        draw = ImageDraw.Draw(strip)
        for column, (weapon, title) in enumerate(zip(WEAPONS, NAMES)):
            name = f"{slug}-{weapon}-idle-{frame:02d}_450x800.png"
            stage = records[name]["stage"]
            center = (stage[0] + stage[2] / 2) * 450 / 720
            with Image.open(NATIVE / name) as source:
                crop = source.convert("RGB").crop((round(center - 85), 0, round(center + 85), crop_height))
            strip.paste(crop, (column * 170, 0))
            box = draw.textbbox((0, 0), title, font=FONT)
            draw.text((column * 170 + (170 - box[2]) / 2, crop_height + 2), title, font=FONT, fill="#fff0d5")
        frames.append(strip)
    frames[0].save(ROOT / f"{slug}-four-idle.gif", save_all=True, append_images=frames[1:], duration=120, loop=0, optimize=True)
    print(ROOT / f"{slug}-detail.png")
    print(ROOT / f"{slug}-four-idle.gif")


if __name__ == "__main__":
    if "--framed" in sys.argv:
        make_open_review("framed")
    elif "--open" in sys.argv:
        make_open_review()
    else:
        make_comparison()
        make_idle_strip()
        check_equipment_preserved()
        print(ROOT / "comparison.png")
        print(ROOT / "four-weapon-idle.gif")
