"""Package the native --record frames into a compact animation and contact sheet."""
import json
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
report = json.loads((OUT / "manifest-450x800.json").read_text(encoding="utf-8"))
recording = report["recording"]
frames_dir = ROOT / recording["directory"].removeprefix("res://")
frames = []
for index in range(recording["frames"]):
    with Image.open(frames_dir / f"frame-{index:04d}.png") as source:
        frames.append(source.convert("RGB").resize((360, 640), Image.Resampling.LANCZOS))

# Use a shared palette so the flat colours stay steady throughout the clip.
samples = frames[::max(1, len(frames) // 10)]
palette_board = Image.new("RGB", (360 * len(samples), 640))
for index, frame in enumerate(samples):
    palette_board.paste(frame, (360 * index, 0))
palette = palette_board.quantize(colors=256)
indexed = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in frames]
indexed[0].save(OUT / "summon-preview.gif", save_all=True, append_images=indexed[1:],
                duration=round(1000 / recording["fps"]), loop=0, optimize=True)

stages = [("banner", "Banner"), ("x10-charge", "Gather"), ("x10-burst", "Release"),
          ("x10-special", "Rare reveal"), ("x10-showcase", "Meet the troop"), ("x10-done", "Results")]
board = Image.new("RGB", (3 * 225, 2 * 426), "#30263f")
draw = ImageDraw.Draw(board)
for index, (filename, caption) in enumerate(stages):
    x, y = (index % 3) * 225, (index // 3) * 426
    with Image.open(OUT / f"{filename}_450x800.png") as source:
        board.paste(source.convert("RGB").resize((225, 400), Image.Resampling.LANCZOS), (x, y + 26))
    draw.text((x + 10, y + 6), caption, fill="#fff0c7")
board.save(OUT / "overview.png")
print(f"Wrote {len(frames)} native frames to {OUT / 'summon-preview.gif'}")
