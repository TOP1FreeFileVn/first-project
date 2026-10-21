"""Check the bed's true alpha entrance and review front-facing native cat only."""
from pathlib import Path
import json
import xml.etree.ElementTree as ET
from PIL import Image, ImageDraw, ImageFont
import numpy as np

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[4]
PARTS = ["shadow", "rear", "interior", "front"]
images = {name: Image.open(HERE / "png" / f"{name}.png").convert("RGBA")
          for name in [*PARTS, "source"]}
assert all(im.size == (768, 720) for im in images.values())
for name in [*PARTS, "source"]:
    assert ET.parse(HERE / f"{name}.svg").getroot().attrib["viewBox"] == "0 0 256 240"

combined = Image.new("RGBA", (768, 720))
for name in PARTS:
    combined.alpha_composite(images[name])
delta = np.abs(np.array(combined).astype(int) - np.array(images["source"]).astype(int))
alpha = np.array(images["front"])[..., 3]
assert all(int(alpha[y * 3, 128 * 3]) == 0 for y in range(144, 240))
assert int(alpha[205 * 3, 45 * 3]) == 255

def clear_run(y):
    row = alpha[y * 3]
    left = right = 128 * 3
    while left > 0 and row[left - 1] == 0:
        left -= 1
    while right < 767 and row[right + 1] == 0:
        right += 1
    return {"left": round(left / 3, 3), "right_exclusive": round((right + 1) / 3, 3),
            "width": round((right - left + 1) / 3, 3)}

report = {
    "render_scale": 3,
    "all_canvas_dimensions": [768, 720],
    "front_centre_column_alpha_y144_to239": 0,
    "front_side_wall_alpha": int(alpha[205 * 3, 45 * 3]),
    "clear_entry_by_local_y": {str(y): clear_run(y) for y in [190, 199, 210, 220, 224]},
    "source_vs_split_composite": {"max_rgba_difference": int(delta.max()),
                                  "mean_abs_difference": float(delta.mean()),
                                  "changed_rgba_components": int(np.count_nonzero(delta))},
    "svg_image_elements": sum(1 for p in HERE.glob("*.svg")
                              for e in ET.parse(p).getroot().iter() if e.tag.endswith("}image")),
    "cat_proof_pose": "unchanged native front only"
}
assert report["svg_image_elements"] == 0
(HERE / "qa.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 17)
small = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 13)
canvas = Image.new("RGBA", (1140, 440), "#f4ebd5")
draw = ImageDraw.Draw(canvas)
titles = ["LOW CARDBOARD BED / ASSEMBLED", "FRONT WALLS / OPEN TO GROUND", "NATIVE FRONT CAT / RESTING"]
for i, title in enumerate(titles):
    x = i * 380
    draw.rounded_rectangle((x + 10, 10, x + 370, 430), radius=14, fill="#ffffff")
    draw.text((x + 25, 23), title, fill="#583f21", font=font)
    for yy in range(62, 392, 16):
        for xx in range(x + 22, x + 358, 16):
            draw.rectangle((xx, yy, min(xx + 15, x + 357), min(yy + 15, 391)),
                           fill=("#e4e9dc" if ((xx - x - 22) // 16 + (yy - 62) // 16) % 2 else "#f2f5ec"))

scale = 1.18
size = (round(256 * scale), round(240 * scale))
def layer(name):
    return images[name].resize(size, Image.Resampling.LANCZOS)

tops = [(39, 87), (419, 87), (799, 87)]
canvas.alpha_composite(layer("source"), tops[0])
canvas.alpha_composite(layer("front"), tops[1])
for name in ["shadow", "rear", "interior"]:
    canvas.alpha_composite(layer(name), tops[2])
cat = Image.open(REPO / "docs/design/2026-10-20/cardboard-castle-lobby-v2/processed/cat_tabby.png").convert("RGBA")
cat = cat.resize((128, 120), Image.Resampling.LANCZOS)
cat_foot = (tops[2][0] + 128 * scale, tops[2][1] + 210 * scale)
canvas.alpha_composite(cat, (round(cat_foot[0] - 64), round(cat_foot[1] - 119)))
canvas.alpha_composite(layer("front"), tops[2])
draw = ImageDraw.Draw(canvas)
draw.text((26, 403), "256 x 240; ground (128,224); main 5px", fill="#6c593e", font=small)
draw.text((406, 403), "Entry x76..180; no front bar across the centre", fill="#6c593e", font=small)
draw.text((786, 403), "Prop scale 1.18; front cat scale 0.5; foot y210", fill="#6c593e", font=small)
canvas.convert("RGB").save(HERE / "bed-review.png")
print(json.dumps(report, indent=2))
