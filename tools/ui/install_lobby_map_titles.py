"""Build unframed lobby panoramas from the approved regional image originals.

No image generation or game layout mutation. The original artwork is preserved;
only the production PNGs and their provenance manifest are regenerated.
"""
from pathlib import Path
import hashlib
import json

from PIL import Image, ImageDraw, ImageOps

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "game/assets/lobby/map-titles"
SIZE = (476, 90)
RADIUS = 10
STROKE_COLOR = "#583f21"
STROKE_WIDTH = 3
SCALE = 4


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    manifest_path = DEST / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    for entry in manifest["maps"]:
        # Older manifests point to the framed proof. Always render from the
        # untouched raw panorama so no carton frame can survive.
        source = (ROOT / entry["source"]).with_name("landscape-raw.png")
        if not source.is_relative_to(ROOT) or not source.is_file():
            raise ValueError(f"Missing project-local source: {source}")
        target = DEST / entry["file"]
        if target.parent != DEST or target.suffix != ".png":
            raise ValueError(f"Unexpected target: {target}")
        scaled = tuple(dimension * SCALE for dimension in SIZE)
        with Image.open(source) as original:
            image = ImageOps.fit(original.convert("RGBA"), scaled, Image.Resampling.LANCZOS)
        alpha = Image.new("L", scaled)
        ImageDraw.Draw(alpha).rounded_rectangle(
            (0, 0, scaled[0] - 1, scaled[1] - 1), radius=RADIUS * SCALE, fill=255,
        )
        image.putalpha(alpha)
        # One inside contour only: no carton lip and no added outer padding.
        ImageDraw.Draw(image).rounded_rectangle(
            (0, 0, scaled[0] - 1, scaled[1] - 1), radius=RADIUS * SCALE,
            outline=STROKE_COLOR, width=STROKE_WIDTH * SCALE,
        )
        image.resize(SIZE, Image.Resampling.LANCZOS).save(target, optimize=True)
        entry.update(source=source.relative_to(ROOT).as_posix(), source_sha256=sha256(source),
                     size=list(SIZE), sha256=sha256(target))
    manifest.update(draw_rect=[122, 136, *SIZE], text_is_separate=True,
                    title_center=[360, 181], frame=False, shadow=False,
                    corner_radius=RADIUS,
                    stroke={"color": STROKE_COLOR, "width": STROKE_WIDTH, "alignment": "inside"},
                    transform="Centered crop from approved original, rounded alpha, brown outline; no carton lip or shadow",
                    builder="tools/ui/install_lobby_map_titles.py")
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Built {len(manifest['maps'])} {SIZE[0]}x{SIZE[1]} lobby panoramas with a {STROKE_WIDTH}px brown outline.")


if __name__ == "__main__":
    main()
