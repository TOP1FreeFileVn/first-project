"""Standalone ship approval sheet using the Godot-rendered vector asset."""
from pathlib import Path
import json
import sys
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
PROJECT = ROOT.parents[3]
FONT = PROJECT / "game/ui/fonts/PaytoneOne-Regular.ttf"


def font(size):
    return ImageFont.truetype(str(FONT), size)


version = sys.argv[1] if len(sys.argv) > 1 else "v2"
ship = Image.open(ROOT / f"ship-cute-{version}.png").convert("RGBA")
assert ship.size == (960, 840), ship.size
assert ship.getbbox() is not None
# Inspect the raster joins that were visibly open in v1, not just SVG paths.
if version == "v2":
    alpha = ship.getchannel("A")
    joins = {
        "fore_mast_into_hull": [(186, y) for y in range(270, 306)],
        "aft_mast_into_hull": [(302, y) for y in range(270, 306)],
        "cabin_into_hull": [(350, y) for y in range(248, 306)],
    }
    checks = {name: all(alpha.getpixel((x * 2, y * 2)) >= 250 for x, y in points)
              for name, points in joins.items()}
    if not all(checks.values()):
        raise ValueError(f"An opaque structural join is still open: {checks}")
    (ROOT / "review-v2.json").write_text(json.dumps({
        "raster_size": list(ship.size), "structural_join_checks": checks,
        "sail_direction": "left edge convex, right edge concave; toward bow at left",
        "production_changed": False,
    }, indent=2) + "\n", encoding="utf-8")
board = Image.new("RGB", (1080, 1040), "#f2ecdf")
draw = ImageDraw.Draw(board)
ink = "#583f21"
draw.text((42, 26), "THUYỀN HẢI TẶC · BẢN CUTE", fill=ink, font=font(38))
draw.text((44, 86), "Thân tròn · Hai cột · Ba buồm đen · Dáng gọn theo ảnh mẫu", fill="#74614a", font=font(21))

large = ship.resize((768, 672), Image.Resampling.LANCZOS)
board.paste(large, (156, 115), large)
draw.text((44, 805), "XEM KHI THU NHỎ", fill=ink, font=font(24))
for x, width in [(80, 180), (420, 140), (770, 100)]:
    thumb = ship.resize((width, round(width * 420 / 480)), Image.Resampling.LANCZOS)
    board.paste(thumb, (x, 852), thumb)
    draw.text((x + width + 12, 905), f"{width}px", fill="#74614a", font=font(18))
board.save(ROOT / f"preview-{version}.png")
print("CUTE_SHIP_PREVIEW_COMPLETE 1080x1040")
