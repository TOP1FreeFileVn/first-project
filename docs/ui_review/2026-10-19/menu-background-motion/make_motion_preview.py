"""Build the native motion GIF and pixel audit from a passing Godot capture."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageStat


ROOT = Path(__file__).resolve().parent
manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
assert manifest["failures"] == 0
assert all(route["passed"] for route in manifest["routes"])


def image(name: str) -> Image.Image:
    result = Image.open(ROOT / name).convert("RGB")
    assert result.size == (450, 800)
    return result


def difference(first: Image.Image, last: Image.Image) -> dict:
    diff = ImageChops.difference(first, last)
    changed = sum(any(pixel) for pixel in diff.get_flattened_data())
    return {
        "changed_pixels": changed,
        "changed_percent": round(changed * 100 / (450 * 800), 4),
        "mean_absolute_rgb_difference": ImageStat.Stat(diff).mean,
        "bounding_box": diff.getbbox(),
    }


frames = [image(frame["file"]) for frame in manifest["motion_frames"]]
palette = frames[0].quantize(colors=256, method=Image.Quantize.MEDIANCUT)
indexed = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in frames]
# GIF duration uses centiseconds. Alternate 120/130 ms to average exactly 8 fps.
durations = [120 if i % 2 == 0 else 130 for i in range(len(indexed))]
indexed[0].save(
    ROOT / "lobby_motion.gif",
    save_all=True,
    append_images=indexed[1:],
    duration=durations,
    loop=0,
    disposal=2,
    optimize=False,
)

foregrounds = [image(f"foreground_t{t:02d}_450x800.png") for t in [0, 5, 10]]
foreground_hashes = [hashlib.sha256(frame.tobytes()).hexdigest() for frame in foregrounds]
assert len(set(foreground_hashes)) == 1

with Image.open(ROOT / "lobby_motion.gif") as gif:
    gif_frames = gif.n_frames

audit = {
    "native_size": [450, 800],
    "gif": "lobby_motion.gif",
    "gif_frames": gif_frames,
    "gif_duration_ms": sum(durations),
    "requested_fps": 8,
    "real_time_source_frames": len(frames),
    "real_time_first_ms": manifest["motion_frames"][0]["elapsed_ms"],
    "real_time_last_ms": manifest["motion_frames"][-1]["elapsed_ms"],
    "background_0_to_5": difference(image("background_t00_450x800.png"), image("background_t05_450x800.png")),
    "background_5_to_10": difference(image("background_t05_450x800.png"), image("background_t10_450x800.png")),
    "real_time_first_to_last": difference(frames[0], frames[-1]),
    "foreground_sha256_at_0_5_10": foreground_hashes,
    "castle_background_difference_from_lobby_at_5": difference(
        image("background_t05_450x800.png"), image("castle_background_t05_450x800.png")
    ),
}
(ROOT / "pixel-audit.json").write_text(json.dumps(audit, indent=2) + "\n", encoding="utf-8")
print(json.dumps(audit, indent=2))
