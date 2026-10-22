"""Install the accepted equipment revisions as production raster overrides.

Sources stay versioned in docs/design. Nothing invokes the retired SVG weapon
generators, changes gameplay data, or composites stat-only equipment onto cats.
Run from any directory: python -B tools/ui/install_equipment_art.py
Update equipment icon orientation/fitting without regenerating held sprites:
python -B tools/ui/install_equipment_art.py --icons-only
Update only the upright boots icon variants:
python -B tools/ui/install_equipment_art.py --gear-only boots
Install only the latest bow inventory icons (held sprite unchanged):
python -B tools/ui/install_equipment_art.py --weapon-only cung
Install the approved clean axe icons and held hero together:
python -B tools/ui/install_equipment_art.py --approved-weapon riu
Install the latest silver gear and new bow/staff/katana, preserving sword/axe:
python -B tools/ui/install_equipment_art.py --latest-hero-set
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
APPROVED_AXE = ROOT / "docs/design/2026-10-22/hero-weapons-canvas"
CANVAS_GEAR = ROOT / "docs/design/2026-10-22/hero-gear-canvas"
CANVAS_ARMOR = ROOT / "docs/design/2026-10-22/armor-canvas"
HERO_INTEGRATION = ROOT / "docs/design/2026-10-23/hero-equipment-integration"
CANVAS_WEAPONS = {"cung": ("bow", "ranged"), "gay_phep": ("staff", "magic"), "katana": ("katana", "katana")}
IDS = ["kiem", "riu", "dao", "katana", "cung", "no", "sung", "dai_bac",
       "gay_phep", "thuoc", "sach_phep", "dua_phep", "giao", "cu_kiem", "chuy", "bua"]
GEAR = ["helmet", "armor", "gloves", "boots", "amulet"]
UPRIGHT_GEAR = ("helmet", "armor", "boots")
HERO_WEAPONS = {"melee": "kiem", "ranged": "cung", "magic": "gay_phep", "heavy": "riu"}
records = []


def held_axis(grip: tuple[float, float], clockwise_from_vertical: float, length: float = 300):
    """Authored grip/shaft axis in the accepted 3x held-layer canvas."""
    angle = math.radians(clockwise_from_vertical)
    return [list(grip), [grip[0] + math.sin(angle) * length, grip[1] - math.cos(angle) * length]]


# These functional axes keep an asymmetric axe head or mitten thumb
# from pulling the icon away from the requested 45-degree reading.
# The bow uses its directed firing axis, perpendicular to the string. Aligning
# its bottom-to-top string instead made the bow face down-right.
# User clarification: ONLY the bow aims up-left (-135 screen degrees).
# Helmet, armor and boots preserve their accepted upright source pose.
# Coordinates refer to accepted source PNGs, before alpha cropping.
EQUIPMENT_AXES = {
    "icon_hero_w_kiem": {
        "anchors": held_axis((480, 498), 30),
        "basis": "sword grip to blade centerline; v3 vertical generated sword placed with PIL -30 degrees",
        "reference": "docs/design/2026-10-20/hero-equipment-v3/weapons/processing.json"
    },
    "icon_hero_w_cung": {
        "anchors": [[96, 498], [282, 498]],
        "target_screen_degrees": -135,
        "role": "directed firing axis, string toward grip/outward belly",
        "basis": "string at grip height (x32,y166) toward left-hand bow grip (x94,y166); bow-left.svg mirrored at x127, rendered 3x. The string is perpendicular to aim, not the aiming axis.",
        "reference": "docs/design/2026-10-20/hero-equipment-v4/bow/bow-left.svg"
    },
    "icon_hero_w_gay_phep": {
        "anchors": held_axis((480, 498), 44),
        "basis": "coaxial grip, shaft, socket and crystal; authored 44-degree clockwise carry, rendered 3x",
        "reference": "docs/design/2026-10-20/hero-equipment-v4/staff/staff-right.svg"
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
    non-upright items use their functional shaft/firing/cuff axis, rather
    than PCA mass of asymmetric appendages. Helmet, armor and boots stay upright.
    """
    before = alpha_geometry(image)
    crop = image.crop(before["alpha_bbox"])
    axis = None if upright else EQUIPMENT_AXES[name]
    target_angle = axis.get("target_screen_degrees", -45) if axis else None
    if axis:
        axis_reference = ROOT / axis["reference"]
        if axis_reference not in sources:
            sources = [*sources, axis_reference]
        start, end = axis["anchors"]
        source_angle = math.degrees(math.atan2(end[1] - start[1], end[0] - start[0]))
        rotation = (source_angle - target_angle + 180) % 360 - 180
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
            "revision": ("2026-10-22-bow-firing-direction" if name == "icon_hero_w_cung" else
                         "2026-10-22-upright-boots" if name == "icon_eq_boots" else "2026-10-21-equipment-icon-fit"),
            "source_size": list(image.size),
            "source_alpha_geometry": before,
            "rotation_pil_ccw_degrees": round(rotation, 6),
            "orientation": ("authored upright" if upright else
                            "directed firing axis toward top-left; bowstring perpendicular" if name == "icon_hero_w_cung" else
                            "functional main axis bottom-left to top-right"),
            "functional_axis": None if upright else {
                **axis,
                "source_screen_degrees": round(source_angle, 6),
                "target_screen_degrees": target_angle,
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
            "resampling": ("no source rotation; independent LANCZOS sampling for each size" if upright else
                           "one source-space BICUBIC rigid rotation; independent LANCZOS sampling for each size")
        }
        save(tile, name if size == 256 else f"{name}_{size}", sources,
             "accepted raster; rigid orientation and safe8% alpha-bound fit only; " + paint_operation,
             transform)


def install_equipment_icons(gear_only: str | None = None, weapon_only: str | None = None):
    if gear_only is None:
        for pose, weapon in HERO_WEAPONS.items():
            if weapon_only is not None and weapon_only != weapon:
                continue
            if weapon == "riu":
                install_approved_axe(include_held=False)
                continue
            if weapon in CANVAS_WEAPONS:
                install_canvas_weapon(weapon, include_held=False)
                continue
            source = HERO / f"processed/{pose}-weapon-layer.png"
            equipment_icons(opened(source), f"icon_hero_w_{weapon}", [source])
        if weapon_only is None or weapon_only == "katana":
            install_canvas_weapon("katana", include_held=False)
    for gear in ([] if weapon_only is not None else [gear_only] if gear_only is not None else GEAR):
        if gear in UPRIGHT_GEAR:
            install_canvas_gear(gear)
            continue
        source = HERO / f"processed/{gear}.png"
        equipment_icons(opened(source), f"icon_eq_{gear}", [source], upright=gear in UPRIGHT_GEAR)


def install_canvas_gear(gear: str):
    """Keep the reviewed upright fit and two stroke roles without reprocessing."""
    source_dir = CANVAS_ARMOR if gear == "armor" else CANVAS_GEAR
    authoring = [source_dir / ("item.js" if gear == "armor" else f"{gear}.js"),
                 source_dir / "export.mjs", source_dir / "source-strokes.json",
                 ROOT / ".claude/skills/canvas-vector-art/scripts/pen.js"]
    for size in (32, 48, 64, 96, 256):
        source = source_dir / f"godot/{gear}-icon-{size}.png"
        image = opened(source)
        if image.size != (size, size):
            raise ValueError(f"Unexpected Canvas gear dimensions: {source}")
        destination = OUT / (f"icon_eq_{gear}.png" if size == 256 else f"icon_eq_{gear}_{size}.png")
        shutil.copyfile(source, destination)
        record(destination, [source, source_dir / f"svg/{gear}-icon-{size}.svg", *authoring],
               "user-requested latest silver gear; unchanged native Godot render from Canvas paths", {
                   "revision": "2026-10-23-latest-hero-equipment",
                   "orientation": "authored upright; zero rotation",
                   "composition": "paired boots" if gear == "boots" else "standalone stat-only equipment",
                   "output_alpha_geometry": alpha_geometry(image),
                   "strokes_at_256": {"main": 11.35, "secondary": 7.41},
                   "paint_operation": "two flat steel fills; original main/secondary ink; no repaint",
                   "resampling": "native Godot SVG render; no installer transform"})


def install_canvas_weapon(weapon: str, include_icons: bool = True, include_held: bool = True):
    """Install the latest bow/staff/katana without touching sword or clean axe."""
    family, pose = CANVAS_WEAPONS[weapon]
    authoring = [APPROVED_AXE / f"{family}.js", APPROVED_AXE / "art.js",
                 APPROVED_AXE / "export.mjs", APPROVED_AXE / "source-profiles.json",
                 ROOT / ".claude/skills/canvas-vector-art/scripts/pen.js"]
    profiles = json.loads((APPROVED_AXE / "source-profiles.json").read_text("utf-8"))[family]
    if include_icons:
        for size in (32, 48, 64, 96, 256):
            source = APPROVED_AXE / f"godot/{family}-icon-{size}.png"
            image = opened(source)
            if image.size != (size, size):
                raise ValueError(f"Unexpected Canvas weapon dimensions: {source}")
            destination = OUT / (f"icon_hero_w_{weapon}.png" if size == 256 else f"icon_hero_w_{weapon}_{size}.png")
            shutil.copyfile(source, destination)
            record(destination, [source, APPROVED_AXE / f"svg/{family}-icon-{size}.svg", *authoring],
                   "user-requested latest weapon; unchanged native Godot render from Canvas paths", {
                       "revision": "2026-10-23-latest-hero-equipment",
                       "orientation": profiles["aim"],
                       "output_alpha_geometry": alpha_geometry(image),
                       "strokes_at_256": profiles["iconStrokes"],
                       "paint_operation": "unchanged authored broad material fills and selective secondary lines",
                       "resampling": "native Godot SVG render; no installer transform"})
    if include_held:
        source = HERO_INTEGRATION / f"godot/hero-{family}-768.png"
        if opened(source).size != (768, 720):
            raise ValueError(f"Unexpected Canvas hero dimensions: {source}")
        destination = OUT / f"hero_cat_{pose}.png"
        shutil.copyfile(source, destination)
        record(destination, [source, HERO_INTEGRATION / f"svg/hero-{family}-768.svg",
                             APPROVED_AXE / f"svg/hero-{family}-256.svg",
                             HERO_INTEGRATION / "render_held.ps1", *authoring,
                             HERO_SOURCE / "hero-base.svg", HERO_SOURCE / "hero-paws.svg"],
               "latest Canvas weapon on unchanged front-facing hero and original paws; native production-resolution render", {
                   "revision": "2026-10-23-latest-hero-equipment",
                   "design_canvas": [256, 240], "production_canvas": [768, 720],
                   "hand": profiles["hand"], "socket": profiles["socket"], "pose": profiles["held"],
                   "strokes_on_design_canvas": profiles["heldStrokes"],
                   "rendering": "identical reviewed paths and viewBox at 3x design canvas; no raster upscaling"})


def install_approved_axe(include_icons: bool = True, include_held: bool = True):
    """Copy the user-approved native renders without re-fitting or re-inking.

    Rebuild these versioned sources with export.mjs and render.ps1 -Family axe.
    The 768x720 hero uses the same paths/pose as the approved 256x240 view,
    rendered at production resolution rather than upscaling its raster.
    """
    authoring = [APPROVED_AXE / "axe.js", APPROVED_AXE / "art.js",
                 APPROVED_AXE / "export.mjs", APPROVED_AXE / "source-profiles.json",
                 ROOT / ".claude/skills/canvas-vector-art/scripts/pen.js"]
    if include_icons:
        for size in (32, 48, 64, 96, 256):
            source = APPROVED_AXE / f"godot/axe-icon-{size}.png"
            name = "icon_hero_w_riu" if size == 256 else f"icon_hero_w_riu_{size}"
            destination = OUT / f"{name}.png"
            image = opened(source)
            if image.size != (size, size):
                raise ValueError(f"Unexpected approved axe icon dimensions: {source}")
            shutil.copyfile(source, destination)
            record(destination, [source, APPROVED_AXE / f"svg/axe-icon-{size}.svg", *authoring],
                   "approved clean axe; unchanged native Godot render from Canvas paths", {
                       "revision": "2026-10-22-approved-clean-axe",
                       "orientation": "authored grip-to-head axis -45 screen degrees (up-right)",
                       "functional_axis": {"target_screen_degrees": -45},
                       "centering": "authored uniform geometry-bounds fit centered on icon canvas",
                       "output_alpha_geometry": alpha_geometry(image),
                       "strokes_at_256": {"main": 13, "secondary": None},
                       "paint_operation": "approved smooth wooden handle and two unlined steel fills; no seam marks",
                       "resampling": "Godot SVG renderer at 2x then LANCZOS to native size; no installer transform"})
    if include_held:
        source = APPROVED_AXE / "godot/hero-axe-768.png"
        if opened(source).size != (768, 720):
            raise ValueError(f"Unexpected approved axe hero dimensions: {source}")
        destination = OUT / "hero_cat_heavy.png"
        shutil.copyfile(source, destination)
        record(destination, [source, APPROVED_AXE / "svg/hero-axe-768.svg", *authoring,
                             HERO_SOURCE / "hero-base.svg", HERO_SOURCE / "hero-paws.svg"],
               "approved clean axe at unchanged right-paw socket (160,166), 28-degree carry, scale0.60; original hero/paws and local ginger palm occlusion", {
                   "revision": "2026-10-22-approved-clean-axe",
                   "design_canvas": [256, 240], "production_canvas": [768, 720],
                   "hand": "right", "socket": [160, 166], "pose_degrees": 28,
                   "weapon_uniform_scale": .60, "main_stroke_on_design_canvas": 9,
                   "secondary_strokes": "none; user removed head seam and both handle marks",
                   "rendering": "same accepted SVG paths rendered natively at 3x design canvas; no raster upscaling"})


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
        if weapon == "riu":
            install_approved_axe(include_icons=False)
        elif weapon in CANVAS_WEAPONS:
            install_canvas_weapon(weapon, include_icons=False)
        else:
            copy(HERO / f"processed/hero-{pose}.png", f"hero_cat_{pose}")
    copy(HERO / "processed/hero-melee.png", "cat_hero")
    bare = opened(HERO_SOURCE / "hero-base.png")
    bare.alpha_composite(opened(HERO_SOURCE / "hero-paws.png"))
    save(bare, "hero_cat_bare", [HERO_SOURCE / "hero-base.png", HERO_SOURCE / "hero-paws.png"],
         "unchanged unarmored front-facing hero and original paws")
    install_canvas_weapon("katana", include_icons=False)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    selection = parser.add_mutually_exclusive_group()
    selection.add_argument("--icons-only", action="store_true", help="update only the ten hero equipment icon families, including retained historical icons")
    selection.add_argument("--gear-only", choices=GEAR, help="update only this stat-only gear family's icon variants")
    selection.add_argument("--weapon-only", choices=[*HERO_WEAPONS.values(), "katana"],
                           help="update only this hero weapon's inventory icon variants; preserve all held sprites")
    selection.add_argument("--approved-weapon", choices=["riu"],
                           help="install the approved axe's five icons and held hero; preserve all other art")
    selection.add_argument("--latest-hero-set", action="store_true",
                           help="install latest silver helmet/armor/paired boots and bow/staff/katana icons/held heroes; preserve sword/axe")
    args = parser.parse_args()
    OUT.mkdir(exist_ok=True)
    manifest_path = OUT / "equipment-sources.json"
    scoped = args.icons_only or args.gear_only is not None or args.weapon_only is not None or args.approved_weapon is not None or args.latest_hero_set
    previous = json.loads(manifest_path.read_text("utf-8")) if scoped else None
    if args.latest_hero_set:
        for gear in UPRIGHT_GEAR:
            install_canvas_gear(gear)
        for weapon in CANVAS_WEAPONS:
            install_canvas_weapon(weapon)
    elif args.approved_weapon:
        install_approved_axe()
    elif not scoped:
        install_all_art()
    if not args.approved_weapon and not args.latest_hero_set:
        install_equipment_icons(args.gear_only, args.weapon_only)

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
        "assets": []}
    manifest["display_contract"] = "Front-facing original hero; held weapon only. Helmet, armor and boots affect stats/icons only. Gloves and amulets are retained historical art, removed from active equipment on 2026-10-22."
    approved_selection = "2026-10-22 user-approved clean axe: smooth wooden grip, unlined two-fill steel head, up-right icons and right-paw held pose"
    if approved_selection not in manifest["source_selection"]:
        manifest["source_selection"].append(approved_selection)
    latest_selection = "2026-10-23 user-requested latest Canvas silver helmet/armor/paired boots and bow/staff/katana; original sword and approved clean axe retained"
    has_latest_set = all(
        latest.get(f"game/ui/art/icon_{name}.png", {}).get("transform", {}).get("revision") == "2026-10-23-latest-hero-equipment"
        for name in ("eq_helmet", "eq_armor", "eq_boots", "hero_w_cung", "hero_w_gay_phep", "hero_w_katana"))
    if has_latest_set and latest_selection not in manifest["source_selection"]:
        manifest["source_selection"].append(latest_selection)
    if has_latest_set:
        manifest["latest_integration_date"] = "2026-10-23"
    manifest["icon_transform_contract"] = {
        "revision": "2026-10-23-latest-hero-equipment",
        "scope": "five hero weapon icons and three active stat-only gear icons, with two historical removed families retained; 32/48/64/96/256 variants",
        "orientation": "Bow ONLY: directed string-to-grip firing axis -135 screen degrees (up-left), perpendicular to its string, per user clarification. Other weapon axes remain -45 degrees (up-right); approved axe retains this direction. Helmet, armor and boots remain authored upright (zero rotation). Explicit shaft/firing axes govern asymmetric weapons; alpha PCA is a separate diagnostic. Historical glove/amulet art retains its previous orientation.",
        "padding": "latest Canvas gear/weapons retain reviewed authored fit and independent native renders at each size; unchanged legacy sword/historical raster fits reserve at least8% per side",
        "preservation": "latest silver gear and bow/staff/katana installed by user request; original sword, approved clean axe and all soldier sprites retained. Stat-only gear never changes the cat costume."
    }
    manifest["assets"] = list(latest.values())
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Installed {len(records)} raster outputs; provenance tracks {len(latest)} final overrides in {OUT}")


if __name__ == "__main__":
    main()
