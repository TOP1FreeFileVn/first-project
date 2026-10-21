from pathlib import Path
import json
import sys
from PIL import Image, ImageDraw, ImageFont

sys.stdout.reconfigure(encoding="utf-8")

root = Path(__file__).resolve().parent
before = root.parent / "menu-pattern-background"
font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 18)
small = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 14)
items = [
    ("Shop", "shop", "shop"),
    ("Hero", "hero", "hero"),
    ("Troops", "troops", "troops"),
    ("Castle", "battle-castle", "castle"),
    ("Patrol", "battle-patrol", "patrol"),
    ("Events", "battle-events", "events"),
]
sheet = Image.new("RGB", (1140, 802), "#e8eeee")
draw = ImageDraw.Draw(sheet)
draw.text((12, 10), "MENU PANELS - Before / After", font=font, fill="#253e42")
draw.text((12, 36), "Actual native game captures at 360 x 640; each preview shown at half size", font=small, fill="#435a5b")
for index, (title, old_name, new_name) in enumerate(items):
    x = 12 + index % 3 * 380
    y = 70 + index // 3 * 366
    draw.text((x, y), title, font=font, fill="#253e42")
    for column, (folder, name, caption) in enumerate([(before, old_name, "Before"), (root, new_name, "After")]):
        image = Image.open(folder / f"{name}_360x640.png").convert("RGB")
        image = image.resize((180, 320), Image.Resampling.LANCZOS)
        cx = x + column * 184
        draw.text((cx, y + 24), caption, font=small, fill="#435a5b")
        sheet.paste(image, (cx, y + 44))
sheet.save(root / "menu-panels-before-after.png")

manifest = json.loads((root / "manifest.json").read_text(encoding="utf-8"))
for entry in manifest["readability"]:
    if entry["window"] != [360, 640]:
        continue
    print(entry["screen"], "panels=", entry["panels"])
    for row in entry["text"]:
        print(" ", row["contrast"], "outline", row["outline"], row["text"].replace("\n", " | "))
