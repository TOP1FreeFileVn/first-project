"""Check alignment/alpha and make an art-only review, with native cat separate."""
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
    root = ET.parse(HERE / f"{name}.svg").getroot()
    assert root.attrib["viewBox"] == "0 0 256 240"

combined = Image.new("RGBA", (768, 720))
for name in PARTS:
    combined.alpha_composite(images[name])
delta = np.abs(np.array(combined).astype(int) - np.array(images["source"]).astype(int))
front_alpha = np.array(images["front"])[..., 3]
assert int(front_alpha[157 * 3, 128 * 3]) == 0
assert int(front_alpha[180 * 3, 128 * 3]) == 0
assert int(front_alpha[224 * 3, 128 * 3]) == 0
assert int(front_alpha[100 * 3, 50 * 3]) == 255

def opening_clear_at(y):
    # Use the contiguous alpha-zero run around the centre, excluding AA pixels.
    row = front_alpha[round(y * 3)]
    mid = 128 * 3
    assert row[mid] == 0
    left = mid
    right = mid
    while left > 0 and row[left - 1] == 0:
        left -= 1
    while right < 767 and row[right + 1] == 0:
        right += 1
    return {"left": round(left / 3, 3), "right_exclusive": round((right + 1) / 3, 3),
            "width": round((right - left + 1) / 3, 3)}

report = {
    "render_scale": 3,
    "all_canvas_dimensions": [768, 720],
    "front_centre_alpha": int(front_alpha[157 * 3, 128 * 3]),
    "front_face_alpha": int(front_alpha[100 * 3, 50 * 3]),
    "front_ground_centre_alpha": int(front_alpha[224 * 3, 128 * 3]),
    "clear_opening_by_local_y": {str(y): opening_clear_at(y) for y in [110, 122, 140, 157, 180, 200, 210, 220]},
    "source_vs_split_composite": {"max_rgba_difference": int(delta.max()),
                                  "changed_rgba_components": int(np.count_nonzero(delta)),
                                  "mean_abs_difference": float(delta.mean())},
    "svg_image_elements": sum(1 for p in HERE.glob("*.svg")
                              for e in ET.parse(p).getroot().iter()
                              if e.tag.endswith("}image")),
    "main_stroke_at_parent_scale": {"prop_5x1.18": 5 * 1.18, "native_cat_12x0.5": 12 * 0.5}
}
assert report["svg_image_elements"] == 0
(HERE / "qa.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

font_path = Path("C:/Windows/Fonts/segoeui.ttf")
font = ImageFont.truetype(str(font_path), 17)
small = ImageFont.truetype(str(font_path), 13)
canvas = Image.new("RGBA", (1140, 440), "#f4ebd5")
draw = ImageDraw.Draw(canvas)
titles = ["ASSEMBLED / NO EMBEDDED CAT", "FRONT / TRANSPARENT OPENING", "NATIVE CAT BETWEEN LAYERS"]

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
draw.text((26, 403), "256 x 240; ground (128,224); main contour 5px", fill="#6c593e", font=small)
draw.text((406, 403), "Open to ground; no horizontal doorway sill", fill="#6c593e", font=small)
draw.text((786, 403), "Prop scale 1.18; native cat scale 0.5; foot y=210", fill="#6c593e", font=small)
canvas.convert("RGB").save(HERE / "art-review.png")
print(json.dumps(report, indent=2))
