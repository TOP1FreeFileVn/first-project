"""Assemble real-time production Hero idle captures; never transforms the hero."""
from pathlib import Path
from PIL import Image


root = Path(__file__).resolve().parent / "native"
for size in ("360x640", "450x800"):
    frames = [Image.open(root / f"idle-{i}_{size}.png").convert("RGB") for i in range(16)]
    frames[0].save(
        root / f"hero-idle_{size}.gif",
        save_all=True,
        append_images=frames[1:],
        duration=120,
        loop=0,
        optimize=True,
    )
    for frame in frames:
        frame.close()
    print(root / f"hero-idle_{size}.gif")
