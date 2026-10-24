"""Package v2 native review evidence without touching the v1 images or animation."""
import json
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
report = json.loads((OUT / "manifest-450x800.json").read_text(encoding="utf-8"))
recording = report.get("recording")
if recording:
    frames_dir = ROOT / recording["directory"].removeprefix("res://")
    frames = []
    for index in range(recording["frames"]):
        with Image.open(frames_dir / f"frame-{index:04d}.png") as source:
            frames.append(source.convert("RGB").resize((360, 640), Image.Resampling.LANCZOS))
    if frames:
        samples = frames[::max(1, len(frames) // 10)]
        palette_board = Image.new("RGB", (360 * len(samples), 640))
        for index, frame in enumerate(samples):
            palette_board.paste(frame, (360 * index, 0))
        palette = palette_board.quantize(colors=256)
        indexed = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in frames]
        indexed[0].save(OUT / "summon-preview.gif", save_all=True, append_images=indexed[1:],
                        duration=round(1000 / recording["fps"]), loop=0, optimize=True)
        print(f"Packaged {len(frames)} native frames into summon-preview.gif")
    portal_recording = recording.get("portal")
    if portal_recording:
        portal_dir = ROOT / portal_recording["directory"].removeprefix("res://")
        portal_frames = []
        for index in range(portal_recording["frames"]):
            with Image.open(portal_dir / f"frame-{index:04d}.png") as source:
                portal_frames.append(source.convert("RGB").crop((20, 230, 430, 570)))
        portal_palette_board = Image.new("RGB", (410 * len(portal_frames), 340))
        for index, frame in enumerate(portal_frames):
            portal_palette_board.paste(frame, (410 * index, 0))
        portal_palette = portal_palette_board.quantize(colors=256)
        portal_indexed = [frame.quantize(palette=portal_palette, dither=Image.Dither.NONE)
                          for frame in portal_frames]
        portal_indexed[0].save(OUT / "portal-preview.gif", save_all=True,
                               append_images=portal_indexed[1:], duration=80, loop=0, optimize=True)
        print(f"Packaged {len(portal_frames)} native circle frames into portal-preview.gif")

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

# Cropping preserves native rendered pixels. Four unobstructed states expose the
# circle itself rather than judging it through the source card or troop art.
states = ["portal-energy-0", "portal-energy-1", "portal-energy-2", "portal-release"]
for width, height in [(450, 800), (360, 640)]:
    crop_top, crop_bottom = round(height * 0.13), round(height * 0.76)
    strip = Image.new("RGB", (width * 4, crop_bottom - crop_top), "#30263f")
    for index, filename in enumerate(states):
        with Image.open(OUT / f"{filename}_{width}x{height}.png") as source:
            strip.paste(source.convert("RGB").crop((0, crop_top, width, crop_bottom)), (index * width, 0))
    strip.save(OUT / f"portal-strip-{width}x{height}.png")
print("Wrote overview.png and both native portal strips")
