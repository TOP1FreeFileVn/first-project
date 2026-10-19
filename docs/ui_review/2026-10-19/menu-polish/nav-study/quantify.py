from pathlib import Path
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).parent
INK = (88, 63, 33)
FACE = (232, 192, 154)
records = []
for key in ("default", "nearest", "snap-whole", "snap-half", "snap-nearest",
            "default-720", "snap-whole-720", "default-360", "snap-whole-360"):
    im = Image.open(ROOT / f"{key}.png").convert("RGB")
    y = round(im.height * .9)
    scale = im.width / 720
    sides = {}
    for name, design_x in (("left", 273), ("right", 446)):
        edge = round(design_x * scale)
        samples = [(x, im.getpixel((x, y))) for x in range(edge - 5, edge + 6)]
        weight = 0
        opaque = 0
        for x, color in samples:
            vec = [FACE[i] - INK[i] for i in range(3)]
            t = sum((color[i] - INK[i]) * vec[i] for i in range(3)) / sum(v*v for v in vec)
            error = max(abs(color[i] - (INK[i] + t * vec[i])) for i in range(3))
            if -.01 <= t <= 1.01 and error < 2:
                weight += max(0, 1 - t)
                opaque += color == INK
        sides[name] = {"opaque_pixels": opaque, "equivalent_ink_pixels": round(weight, 3),
                       "row": y, "samples": samples}
    records.append({"variant": key, "size": im.size, "sides": sides})
print(json.dumps([{k: v for k, v in item.items() if k != "sides"} |
                  {"left": item["sides"]["left"]["equivalent_ink_pixels"],
                   "right": item["sides"]["right"]["equivalent_ink_pixels"]}
                 for item in records], indent=2))
(ROOT / "measurements.json").write_text(json.dumps(records, indent=2), encoding="utf-8")

proof = Image.new("RGB", (960, 390), "#ebe1d1")
draw = ImageDraw.Draw(proof)
for i, key in enumerate(("default", "snap-whole")):
    im = Image.open(ROOT / f"{key}.png").convert("RGB")
    crop = im.crop((166, 698, 284, 800)).resize((472, 408), Image.Resampling.NEAREST)
    proof.paste(crop.crop((0, 0, 472, 358)), (i * 480 + 4, 30))
    draw.text((i * 480 + 12, 9), key, fill=INK)
proof.save(ROOT / "border-comparison.png")
