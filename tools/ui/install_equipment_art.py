"""Install the accepted equipment revisions as production raster overrides.

Sources stay versioned in docs/design. Nothing invokes the retired SVG weapon
generators, changes gameplay data, or composites the five stat-only gear slots.
Run from any directory: python -B tools/ui/install_equipment_art.py
Update equipment icon orientation/fitting without regenerating held sprites:
python -B tools/ui/install_equipment_art.py --icons-only
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import shutil

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "game/ui/art"
ROLLOUT = ROOT / "docs/design/2026-10-19/weapon-rollout"
HERO = ROOT / "docs/design/2026-10-20/hero-equipment-v4"
SPEAR = ROOT / "docs/design/2026-10-20/spear-stroke-sample"
HERO_SOURCE = ROOT / "docs/design/2026-10-19/hero-equipment/sources"
IDS = ["kiem", "riu", "dao", "katana", "cung", "no", "sung", "dai_bac",
       "gay_phep", "thuoc", "sach_phep", "dua_phep", "giao", "cu_kiem", "chuy", "bua"]
GEAR = ["helmet", "armor", "gloves", "boots", "amulet"]
HERO_WEAPONS = {"melee": "kiem", "ranged": "cung", "magic": "gay_phep", "heavy": "riu"}
records = []


def held_axis(grip: tuple[float, float], clockwise_from_vertical: float, length: float = 300):
    """Authored grip/shaft axis in the accepted 3x held-layer canvas."""
    angle = math.radians(clockwise_from_vertical)
    return [list(grip), [grip[0] + math.sin(angle) * length, grip[1] - math.cos(angle) * length]]


# These functional axes keep an asymmetric axe head, bow belly, mitten thumb or
# boot upper from pulling the icon away from the requested 45-degree reading.
# Coordinates refer to accepted source PNGs, before alpha cropping.
EQUIPMENT_AXES = {
    "icon_hero_w_kiem": {
        "anchors": held_axis((480, 498), 30),
        "basis": "sword grip to blade centerline; v3 vertical generated sword placed with PIL -30 degrees",
        "reference": "docs/design/2026-10-20/hero-equipment-v3/weapons/processing.json"
    },
    "icon_hero_w_cung": {
        "anchors": [[96, 693], [96, 291]],
        "basis": "bottom to top string attachment; bow-left.svg mirrored x=254-222, y=231 to 97, rendered 3x",
        "reference": "docs/design/2026-10-20/hero-equipment-v4/bow/bow-left.svg"
    },
    "icon_hero_w_gay_phep": {
        "anchors": held_axis((480, 498), 44),
        "basis": "coaxial grip, shaft, socket and crystal; authored 44-degree clockwise carry, rendered 3x",
        "reference": "docs/design/2026-10-20/hero-equipment-v4/staff/staff-right.svg"
    },
    "icon_hero_w_riu": {
        "anchors": held_axis((480, 498), 27),
        "basis": "shaft center x=40 through grip y=128; authored 27-degree clockwise carry, rendered 3x",
        "reference": "docs/design/2026-10-20/hero-equipment-v3/weapons-heavy/processed/heavy-axe-held.svg"
    },
    "icon_hero_w_katana": {
        "anchors": [[637.5, 978], [647.5, 300]],
        "basis": "measured grip midpoint y=978,x=637.5 to straightened blade midpoint y=300,x=647.5; small authored bend retained",
        "reference": "docs/design/2026-10-19/weapon-rollout/processed/katana.png"
    },
    "icon_eq_gloves": {
        "anchors": [[406, 650], [406, 120]],
        "basis": "authored upright cuff to fingers; rotate clockwise45 so cuffSW and fingertipsNE",
        "reference": "docs/design/2026-10-20/hero-equipment-v4/processed/gloves.png"
    },
    "icon_eq_boots": {
        "anchors": [[100, 550], [760, 550]],
        "basis": "horizontal sole heel to toe; toe pointsNE after counterclockwise45 rotation",
        "reference": "docs/design/2026-10-20/hero-equipment-v4/processed/boots.png"
    },
    "icon_eq_amulet": {
        "anchors": [[331, 750], [331, 100]],
        "basis": "pendant body to top hanging loop, authored upright",
        "reference": "docs/design/2026-10-20/hero-equipment-v4/processed/amulet.png"
    }
}


def opened(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def relative(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def record(destination: Path, sources: list[Path], action: str, transform: dict | None = None):
    entry = {"asset": relative(destination), "sha256": sha(destination),
             "sources": [{"path": relative(p), "sha256": sha(p)} for p in sources],
             "operation": action}
    if transform is not None:
        entry["transform"] = transform
    records.append(entry)


def copy(source: Path, name: str):
    destination = OUT / f"{name}.png"
    shutil.copyfile(source, destination)
    record(destination, [source], "unchanged final review PNG")


def save(image: Image.Image, name: str, sources: list[Path], action: str, transform: dict | None = None):
    destination = OUT / f"{name}.png"
    image.save(destination)
    record(destination, sources, action, transform)


def icons(image: Image.Image, name: str, sources: list[Path], action="alpha crop, optical fit only", sizes=(32, 48, 64, 96, 256)):
    image = image.crop(image.getchannel("A").getbbox())
    for size in sizes:
        ratio = min((size - max(4, round(size * .06))) / image.width,
                    (size - max(4, round(size * .06))) / image.height)
        thumb = image.resize((round(image.width * ratio), round(image.height * ratio)), Image.Resampling.LANCZOS)
        tile = Image.new("RGBA", (size, size))
        tile.alpha_composite(thumb, ((size - thumb.width) // 2, (size - thumb.height) // 2))
        save(tile, name if size == 256 else f"{name}_{size}", sources, action)


def alpha_geometry(image: Image.Image) -> dict:
    """Describe the painted silhouette, with +Y pointing down as on screen.

    Alpha-weighted PCA treats the outline and fill as one silhouette. Angles are
    unoriented axes modulo 180 degrees, normalized to [-90, 90).
    """
    alpha = np.asarray(image.getchannel("A")).astype(np.float64) / 255
    y, x = np.indices(alpha.shape)
    mass = alpha.sum()
    if mass == 0:
        raise ValueError("Cannot fit an empty equipment icon")
    cx, cy = (x * alpha).sum() / mass, (y * alpha).sum() / mass
    dx, dy = x - cx, y - cy
    covariance = np.array([[(alpha * dx * dx).sum(), (alpha * dx * dy).sum()],
                           [(alpha * dx * dy).sum(), (alpha * dy * dy).sum()]]) / mass
    values, vectors = np.linalg.eigh(covariance)
    vx, vy = vectors[:, -1]
    angle = (math.degrees(math.atan2(vy, vx)) + 90) % 180 - 90
    return {"alpha_bbox": list(image.getchannel("A").getbbox()),
            "alpha_centroid": [round(float(cx), 6), round(float(cy), 6)],
            "principal_axis_screen_degrees": round(float(angle), 6),
            "principal_axis_eigenvalue_ratio": round(float(values[-1] / values[0]), 6)}


def equipment_icons(image: Image.Image, name: str, sources: list[Path], upright: bool = False,
                    paint_operation: str = "unchanged accepted colors"):
    """Fit accepted artwork; never repaint, re-ink, deform, or touch held poses.

    Each output is sampled from the same rotated high-resolution source. The
    non-upright items use their functional shaft/string/cuff/sole axis, rather
    than PCA mass of asymmetric appendages. Helmet and armor stay upright.
    """
    before = alpha_geometry(image)
    crop = image.crop(before["alpha_bbox"])
    axis = None if upright else EQUIPMENT_AXES[name]
    if axis:
        axis_reference = ROOT / axis["reference"]
        if axis_reference not in sources:
            sources = [*sources, axis_reference]
        start, end = axis["anchors"]
        source_angle = math.degrees(math.atan2(end[1] - start[1], end[0] - start[0]))
        rotation = (source_angle + 225) % 360 - 180
    else:
        source_angle, rotation = None, 0.0
    oriented = crop.rotate(rotation, Image.Resampling.BICUBIC, expand=True) if rotation else crop
    rotated_bounds = oriented.getchannel("A").getbbox()
    rotated_size = oriented.size
    oriented = oriented.crop(rotated_bounds)
    oriented_geometry = alpha_geometry(oriented)
    oriented_anchors = []
    if axis:
        radians = math.radians(rotation)
        for px, py in axis["anchors"]:
            dx = px - before["alpha_bbox"][0] - crop.width / 2
            dy = py - before["alpha_bbox"][1] - crop.height / 2
            oriented_anchors.append([
                math.cos(radians) * dx + math.sin(radians) * dy + rotated_size[0] / 2 - rotated_bounds[0],
                -math.sin(radians) * dx + math.cos(radians) * dy + rotated_size[1] / 2 - rotated_bounds[1]])
    for size in (32, 48, 64, 96, 256):
        # Ceiling gives at least 8% transparent space at each raster resolution.
        inset = math.ceil(size * .08)
        available = size - 2 * inset
        ratio = available / max(oriented.size)
        dimensions = tuple(max(1, round(value * ratio)) for value in oriented.size)
        thumb = oriented.resize(dimensions, Image.Resampling.LANCZOS)
        tile = Image.new("RGBA", (size, size))
        offset = ((size - thumb.width) // 2, (size - thumb.height) // 2)
        tile.alpha_composite(thumb, offset)
        output_anchors = [[px * dimensions[0] / oriented.width + offset[0],
                           py * dimensions[1] / oriented.height + offset[1]] for px, py in oriented_anchors]
        output_angle = None if upright else math.degrees(math.atan2(
            output_anchors[1][1] - output_anchors[0][1], output_anchors[1][0] - output_anchors[0][0]))
        transform = {
            "revision": "2026-10-21-equipment-icon-fit",
            "source_size": list(image.size),
            "source_alpha_geometry": before,
            "rotation_pil_ccw_degrees": round(rotation, 6),
            "orientation": "authored upright" if upright else "functional main axis bottom-left to top-right",
            "functional_axis": None if upright else {
                **axis,
                "source_screen_degrees": round(source_angle, 6),
                "target_screen_degrees": -45,
                "rotated_screen_degrees": round(source_angle - rotation, 6),
                "output_screen_degrees": round(output_angle, 6),
                "output_anchors": [[round(value, 6) for value in point] for point in output_anchors],
                "raster_rounding_note": "integer thumbnail dimensions can shift sampled main axis by less than one degree at32px"
            },
            "rotated_alpha_geometry": oriented_geometry,
            "safe_rect_normalized": [.08, .08, .92, .92],
            "safe_inset_pixels": inset,
            "safe_rect_pixels": [inset, inset, size - inset, size - inset],
            "resized_dimensions": list(dimensions),
            "paste_offset": list(offset),
            "centering": "painted alpha bounds centered; at most one pixel rounding difference",
            "output_alpha_geometry": alpha_geometry(tile),
            "paint_operation": paint_operation,
            "resampling": "one source-space BICUBIC rigid rotation; independent LANCZOS sampling for each size"
        }
        save(tile, name if size == 256 else f"{name}_{size}", sources,
             "accepted raster; rigid orientation and safe8% alpha-bound fit only; " + paint_operation,
             transform)


def install_equipment_icons():
    for pose, weapon in HERO_WEAPONS.items():
        source = HERO / f"processed/{pose}-weapon-layer.png"
        equipment_icons(opened(source), f"icon_hero_w_{weapon}", [source])
    source = ROLLOUT / "processed/katana.png"
    equipment_icons(brighten_once(opened(source)), "icon_hero_w_katana", [source],
                    paint_operation="existing approved single 10% paint brightening; original ink preserved")
    for gear in GEAR:
        source = HERO / f"processed/{gear}.png"
        equipment_icons(opened(source), f"icon_eq_{gear}", [source], upright=gear in ("helmet", "armor"))


def brighten_once(image: Image.Image) -> Image.Image:
    pixels = np.array(image)
    colors = pixels[:, :, :3].astype(float)
    ink = np.linalg.norm(colors - np.array([88, 63, 33]), axis=2) < 30
    pixels[:, :, :3] = np.where(ink[:, :, None], pixels[:, :, :3],
                               np.clip(np.round(colors * 1.1), 0, 255).astype(np.uint8))
    return Image.fromarray(pixels, "RGBA")


def katana_hero():
    """Use the final straightened katana's already-reviewed pose and source grip.

    No new silhouette, outlines or costume: same registered base/palm/paws as v4.
    """
    source = ROLLOUT / "processed/katana.png"
    metadata = json.loads((ROLLOUT / "processed/katana.json").read_text("utf-8"))
    pose = metadata["placement"]
    padding = metadata["processing"]["padding_source"]
    weapon = brighten_once(opened(source))
    ratio = pose["scale"] * 3
    scaled = weapon.resize((round(weapon.width * ratio), round(weapon.height * ratio)), Image.Resampling.LANCZOS)
    grip = [(v + padding) * ratio for v in pose["grip"]]
    rotated = scaled.rotate(pose["angle"], Image.Resampling.BICUBIC, expand=True)
    dx, dy = grip[0] - scaled.width / 2, grip[1] - scaled.height / 2
    angle = math.radians(pose["angle"])
    gx = math.cos(angle) * dx + math.sin(angle) * dy + rotated.width / 2
    gy = -math.sin(angle) * dx + math.cos(angle) * dy + rotated.height / 2
    layer = Image.new("RGBA", (768, 720))
    layer.alpha_composite(rotated, (round(160 * 3 - gx), round(166 * 3 - gy)))
    base = opened(HERO_SOURCE / "hero-base.png")
    base.alpha_composite(layer)
    palm = Image.open(HERO / "processed/right-palm-mask.png").convert("L")
    fur = Image.new("RGBA", base.size, opened(HERO_SOURCE / "hero-base.png").getpixel((555, 540)))
    base = Image.composite(fur, base, palm)
    base.alpha_composite(opened(HERO_SOURCE / "hero-paws.png"))
    save(base, "hero_cat_katana", [source, ROLLOUT / "processed/katana.json",
        HERO_SOURCE / "hero-base.png", HERO_SOURCE / "hero-paws.png", HERO / "processed/right-palm-mask.png"],
        "final katana pose/grip on unchanged bare hero; single 10% paint brightening; v4 palm occlusion")


def install_all_art():
    for identifier in IDS:
        if identifier == "giao":
            # This later sample is the explicit 9/10 approved spear. Keep the
            # cavalry cat's original coat, clothing and rarity underneath it.
            cat_source = ROLLOUT / "sources/cat_giao.png"
            weapon_source = SPEAR / "processed/spear-held-layer.png"
            paw_source = ROLLOUT / "sources/front-paw.png"
            cat = opened(cat_source)
            cat.alpha_composite(opened(weapon_source))
            cat.alpha_composite(opened(paw_source))
            save(cat, "unit_giao", [cat_source, weapon_source, paw_source],
                 "accepted 9/10 spear layer on unchanged final cavalry cat; same right-paw grip")
            icons(opened(SPEAR / "processed/spear.png"), "icon_w_giao", [SPEAR / "processed/spear.png"])
        else:
            copy(ROLLOUT / f"processed/unit_{identifier}.png", f"unit_{identifier}")
            copy(ROLLOUT / f"processed/{identifier}-cropped.png", f"weapon_{identifier}")
            for size in (32, 48, 64, 96):
                copy(ROLLOUT / f"processed/icon_w_{identifier}_{size}.png", f"icon_w_{identifier}_{size}")
            icons(opened(ROLLOUT / f"processed/{identifier}-cropped.png"), f"icon_w_{identifier}",
                  [ROLLOUT / f"processed/{identifier}-cropped.png"], sizes=(256,))
    copy(SPEAR / "processed/spear.png", "weapon_giao")

    for pose, weapon in HERO_WEAPONS.items():
        copy(HERO / f"processed/hero-{pose}.png", f"hero_cat_{pose}")
    copy(HERO / "processed/hero-melee.png", "cat_hero")
    bare = opened(HERO_SOURCE / "hero-base.png")
    bare.alpha_composite(opened(HERO_SOURCE / "hero-paws.png"))
    save(bare, "hero_cat_bare", [HERO_SOURCE / "hero-base.png", HERO_SOURCE / "hero-paws.png"],
         "unchanged unarmored front-facing hero and original paws")
    katana_hero()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--icons-only", action="store_true", help="update only the ten hero equipment icon families")
    args = parser.parse_args()
    OUT.mkdir(exist_ok=True)
    manifest_path = OUT / "equipment-sources.json"
    previous = json.loads(manifest_path.read_text("utf-8")) if args.icons_only else None
    if not args.icons_only:
        install_all_art()
    install_equipment_icons()

    # Last occurrence wins for icons which have both native and generated-base entries.
    latest = {item["asset"]: item for item in previous["assets"]} if previous else {}
    latest.update({item["asset"]: item for item in records})
    manifest = previous or {
        "integration_date": "2026-10-20",
        "authorization": "User requested applying yesterday/today's approved work into the actual game; final corrected revisions selected.",
        "source_selection": [
            "weapon-rollout final 15 weapons plus accepted V6 sword; reduced dao/katana bend preserved",
            "spear-stroke-sample selected iteration3/node32:2, user rated 9/10, replaces older soldier spear",
            "hero-equipment-v4 corrected weapon-only poses, left bow with 3 px string, coaxial right staff, original ginger palm",
            "hero-equipment-v4 final five +10% brightened stat-only icons, no wearable layers"
        ],
        "display_contract": "Front-facing original hero; held weapon only. Five other slots affect stats/icons only. No gameplay/balance edits.",
        "assets": []}
    manifest["icon_transform_contract"] = {
        "revision": "2026-10-21-equipment-icon-fit",
        "scope": "five hero weapon icons and five stat-only gear icons; 32/48/64/96/256 variants",
        "orientation": "functional main axis -45 degrees in screen coordinates; helmet and armor remain upright. Explicit shaft/string/cuff/sole anchors govern asymmetric icons; alpha PCA is recorded as a separate diagnostic.",
        "padding": "at least 8% transparent safe space on all four sides, ceiling to integer pixels",
        "preservation": "accepted silhouette, colors and strokes retained; held hero/soldier sprites unchanged"
    }
    manifest["assets"] = list(latest.values())
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Installed {len(records)} raster outputs; provenance tracks {len(latest)} final overrides in {OUT}")


if __name__ == "__main__":
    main()
