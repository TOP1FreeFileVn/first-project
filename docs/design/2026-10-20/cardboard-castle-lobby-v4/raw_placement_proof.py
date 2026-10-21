"""Temporary composition proof; final processing is in build_review.py."""
from pathlib import Path
from PIL import Image

BASE = Path(__file__).resolve().parent
V2 = BASE.parent / "cardboard-castle-lobby-v2"
scene = Image.open(BASE / "courtyard-raw.png").convert("RGBA").resize((720, 1280), Image.Resampling.LANCZOS)
for name, x, y, width in [
    ("cat_cream", 115, 682, 96),
    ("cat_tabby", 323, 686, 108),
    ("cat_calico", 496, 780, 96),
]:
    cat = Image.open(V2 / "processed" / f"{name}.png").convert("RGBA")
    cat = cat.resize((width, round(width * 240 / 256)), Image.Resampling.LANCZOS)
    scene.alpha_composite(cat, (x, y))
overlay = Image.open(V2 / "ui-overlay-ground-lobby-with-title.png").convert("RGBA")
Image.alpha_composite(scene, overlay).convert("RGB").save(BASE / "raw-ui-placement-proof.png")
