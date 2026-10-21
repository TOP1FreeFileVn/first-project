"""Read-only reference study of the locally recovered Cat Gunner art.

This produces a labelled contact sheet, not a reconstruction of a runtime UI.
"""

import hashlib
import json
from collections import Counter
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


HERE = Path(__file__).resolve().parent
SOURCE = Path(r"C:\Users\dangp\OneDrive\Documents\first-project\reverse_engineering\CatGunner_1.1.64")
SPRITES = SOURCE / "Assets/Sprite/sharedassets0.assets"
FONT = Path(r"C:\Windows\Fonts\arial.ttf")
TITLE = ImageFont.truetype(str(FONT), 27)
LABEL = ImageFont.truetype(str(FONT), 18)
SMALL = ImageFont.truetype(str(FONT), 15)

names = [
    "Map_0__644.png",
    "Map_1__896.png",
    "Map_2__606.png",
    "Road_Forest__497.png",
    "Field_Forest__622.png",
    "Road_up_Forest__590.png",
    "Bush_Yellow_Green_03__839.png",
    "Bush_Yellow_Green_02__841.png",
    "Forest_Grass__864.png",
]

sheet = Image.new("RGB", (1664, 775), "#f2eadb")
d = ImageDraw.Draw(sheet)
d.text((28, 20), "CAT GUNNER 1.1.64 | Background source study", font=TITLE, fill="#583f21")
d.text((28, 59), "Recovered original assets - com.Chodun.CatGunner - reviewed 20 Oct 2026", font=LABEL, fill="#665b48")
d.text((28, 89), "Asset contact sheet; this is not a captured or reconstructed runtime screen.", font=SMALL, fill="#665b48")

for i, name in enumerate(names[:3]):
    img = Image.open(SPRITES / name).convert("RGBA")
    x, y = 28 + i * 544, 130
    sheet.paste(img, (x, y), img)
    d.text((x, y + 298), f"{name} | 512 x 286", font=LABEL, fill="#583f21")

tiles = [
    ("Road_Forest__497.png", 28),
    ("Field_Forest__622.png", 220),
    ("Road_up_Forest__590.png", 412),
    ("Bush_Yellow_Green_03__839.png", 735),
    ("Bush_Yellow_Green_02__841.png", 1050),
    ("Forest_Grass__864.png", 1335),
]
d.text((28, 482), "Separate terrain / prop sprites", font=TITLE, fill="#583f21")
for name, x in tiles:
    img = Image.open(SPRITES / name).convert("RGBA")
    y = 535
    d.rounded_rectangle((x - 5, y - 5, x + max(img.width, 155) + 5, y + 161), radius=8, fill="#d7debf")
    sheet.paste(img, (x, y), img)
    label = name.split("__")[0]
    if len(label) > 20:
        label = label.replace("Yellow_Green", "Y/G")
    d.text((x, 711), label, font=SMALL, fill="#583f21")
    d.text((x, 735), f"{img.width} x {img.height}", font=SMALL, fill="#665b48")

sheet.save(HERE / "cat-gunner-background-sources.png")

records = []
for name in names:
    path = SPRITES / name
    im = Image.open(path)
    records.append({
        "file": str(path),
        "size": list(im.size),
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    })
manifest = {
    "reviewed": "2026-10-20",
    "product": "Cat Gunner",
    "package": "com.Chodun.CatGunner",
    "version": "1.1.64",
    "source_root": str(SOURCE),
    "provenance": str(SOURCE / "input-provenance.json"),
    "scope": "Recovered source sprite study only; no runtime scene/layout verification.",
    "assets": records,
    "palette_samples": {},
    "excluded_after_inspection": {
        "Raid_0__105.png": "Boss/slime character texture atlas, not a background.",
        "Background__449.png": "Generic 32x32 Unity UI sprite, not scene art.",
    },
}
for name in ["Map_0__644.png", "Road_Forest__497.png", "Field_Forest__622.png", "Road_up_Forest__590.png"]:
    im = Image.open(SPRITES / name).convert("RGBA")
    counts = Counter(px[:3] for px in im.get_flattened_data() if px[3] > 240)
    manifest["palette_samples"][name] = [
        {"hex": "#%02x%02x%02x" % rgb, "pixel_count": n}
        for rgb, n in counts.most_common(12)
    ]
(HERE / "sources.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
print(HERE / "cat-gunner-background-sources.png")
print(json.dumps(manifest["palette_samples"], ensure_ascii=False, indent=2))
