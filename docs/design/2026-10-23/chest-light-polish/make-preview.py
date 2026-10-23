"""Package actual native viewport captures; no art is generated here."""
from pathlib import Path
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
report = json.loads((ROOT / "review.json").read_text(encoding="utf-8"))
records = report["frames"]
if records:
    images = [Image.open(ROOT / row["file"]).convert("RGB") for row in records]
    durations = [max(35, min(350, records[i + 1]["time_ms"] - row["time_ms"]))
                 if i + 1 < len(records) else 650 for i, row in enumerate(records)]
    images[0].save(ROOT / "opening-preview.gif", save_all=True,
                   append_images=images[1:], duration=durations, loop=0, disposal=2)
    print(f"Saved opening-preview.gif from {len(images)} actual native viewport frames")

names = ["common-wait", "common-open-mouth", "common-card", "epic-card"]
sheet = Image.new("RGB", (360 * 4, 680), "#243a4b")
draw = ImageDraw.Draw(sheet)
for index, name in enumerate(names):
    image = Image.open(ROOT / f"{name}_360x640.png").convert("RGB")
    sheet.paste(image, (360 * index, 40))
    draw.text((360 * index + 16, 15), name, fill="#fff4d8")
sheet.save(ROOT / "native-states.png")
print("Saved native-states.png")
