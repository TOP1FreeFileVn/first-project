"""Geometry and preservation evidence for the accepted equipment icon fit.

No Godot import is required. Before PNGs are captured once, before installation.
"""
from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path
import shutil
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
ART = ROOT / "game/ui/art"
NAMES = ["hero_w_kiem", "hero_w_cung", "hero_w_gay_phep", "hero_w_riu", "hero_w_katana",
         "eq_helmet", "eq_armor", "eq_gloves", "eq_boots", "eq_amulet"]
SIZES = (32, 48, 64, 96, 256)
TARGETS = {f"icon_{name}{'' if size == 256 else '_' + str(size)}.png"
           for name in NAMES for size in SIZES}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def metrics(image):
    a = np.asarray(image.convert("RGBA"))[:, :, 3].astype(float) / 255
    y, x = np.indices(a.shape)
    total = a.sum()
    cx, cy = (x * a).sum() / total, (y * a).sum() / total
    dx, dy = x - cx, y - cy
    covariance = np.array([[(a * dx * dx).sum(), (a * dx * dy).sum()],
                           [(a * dx * dy).sum(), (a * dy * dy).sum()]]) / total
    values, vectors = np.linalg.eigh(covariance)
    vx, vy = vectors[:, -1]
    angle = (math.degrees(math.atan2(vy, vx)) + 90) % 180 - 90
    return {"size": list(image.size), "alpha_bbox": list(image.getchannel("A").getbbox()),
            "centroid": [round(cx, 5), round(cy, 5)], "principal_axis_screen_degrees": round(angle, 5),
            "eigenvalue_ratio": round(float(values[-1] / values[0]), 5)}


def font(size=18):
    return ImageFont.truetype("C:/Windows/Fonts/arial.ttf", size)


def checker(size):
    tile = Image.new("RGBA", size, "#365765")
    d = ImageDraw.Draw(tile)
    for y in range(0, size[1], 12):
        for x in range(0, size[0], 12):
            if (x // 12 + y // 12) % 2:
                d.rectangle((x, y, x + 11, y + 11), fill="#3e606c")
    return tile


def sheet(before=False):
    # Large rows expose geometry; small rows retain exact native pixel sizes.
    w, h = 1480, 1000
    canvas = Image.new("RGB", (w, h), "#142c38")
    d = ImageDraw.Draw(canvas)
    d.text((22, 14), "BEFORE" if before else "AFTER — approved art; orientation and fitting only", font=font(25), fill="#fff0cf")
    directory = HERE / "before" if before else ART
    provenance = {Path(item["asset"]).name: item for item in json.loads((ART / "equipment-sources.json").read_text("utf-8"))["assets"]}
    for index, name in enumerate(NAMES):
        col, row = index % 5, index // 5
        x, y = 20 + col * 292, 68 + row * 460
        d.text((x, y), name, font=font(18), fill="#fff0cf")
        image = Image.open(directory / f"icon_{name}.png").convert("RGBA")
        tile = checker((256, 256))
        preview = image.copy()
        preview.thumbnail((256, 256), Image.Resampling.LANCZOS)
        tile.alpha_composite(preview, ((256 - preview.width) // 2, (256 - preview.height) // 2))
        td = ImageDraw.Draw(tile)
        if not before:
            td.rectangle((20, 20, 235, 235), outline="#7dd7c0", width=1)
            if name not in ("eq_helmet", "eq_armor"):
                axis = provenance[f"icon_{name}.png"]["transform"]["functional_axis"]
                td.line([tuple(point) for point in axis["output_anchors"]], fill="#83d1d1", width=1)
        canvas.paste(tile.convert("RGB"), (x, y + 30))
        m = metrics(image)
        if before:
            caption = f"source {image.width}×{image.height}  PCA {m['principal_axis_screen_degrees']:.2f}°"
        else:
            axis = provenance[f"icon_{name}.png"]["transform"]["functional_axis"]
            main = f"main {axis['output_screen_degrees']:.2f}°" if axis else "authored upright"
            caption = f"{main} | PCA {m['principal_axis_screen_degrees']:.2f}°"
        d.text((x, y + 290), caption, font=font(12), fill="#cee2e4")
        d.text((x, y + 307), f"bbox {m['alpha_bbox']}", font=font(12), fill="#cee2e4")
        offset = 0
        for size in (32, 48, 64, 96):
            icon = Image.open(directory / f"icon_{name}_{size}.png").convert("RGBA")
            thumb = checker((size, size))
            thumb.alpha_composite(icon)
            canvas.paste(thumb.convert("RGB"), (x + offset, y + 331))
            d.text((x + offset, y + 430), str(size), font=font(12), fill="#cee2e4")
            offset += size + 9
    path = HERE / ("before-sheet.png" if before else "after-sheet.png")
    canvas.save(path)
    return path


def baseline():
    path = HERE / "baseline-hashes.json"
    if path.exists():
        raise SystemExit("Baseline exists; refusing to replace pre-edit evidence.")
    files = sorted(ART.glob("*.png"))
    hashes = {p.name: digest(p) for p in files}
    (HERE / "before").mkdir(exist_ok=True)
    for name in TARGETS:
        shutil.copyfile(ART / name, HERE / "before" / name)
    path.write_text(json.dumps(hashes, indent=2) + "\n", encoding="utf-8")
    print(f"Captured {len(hashes)} hashes; {len(TARGETS)} target icons. {sheet(True)}")


def review():
    baseline_hashes = json.loads((HERE / "baseline-hashes.json").read_text("utf-8"))
    now = {p.name: digest(p) for p in sorted(ART.glob("*.png"))}
    modified = [name for name, value in baseline_hashes.items() if now.get(name) != value]
    unexpected = sorted(set(modified) - TARGETS)
    new_files = sorted(set(now) - set(baseline_hashes))
    icon_metrics = {name: metrics(Image.open(ART / name)) for name in sorted(TARGETS)}
    provenance = {Path(item["asset"]).name: item for item in json.loads((ART / "equipment-sources.json").read_text("utf-8"))["assets"]}
    failures = []
    for name, m in icon_metrics.items():
        size = m["size"][0]
        inset = math.ceil(size * .08)
        left, top, right, bottom = m["alpha_bbox"]
        if left < inset or top < inset or right > size - inset or bottom > size - inset:
            failures.append(f"{name}: fails safe8% all-alpha bbox")
        if not name.startswith(("icon_eq_helmet", "icon_eq_armor")):
            axis = provenance[name]["transform"]["functional_axis"]
            m["functional_axis_screen_degrees"] = axis["output_screen_degrees"]
            delta = abs(axis["output_screen_degrees"] + 45)
            if delta > 1:
                failures.append(f"{name}: functional axis differs by {delta:.4f} degrees")
    max_axis_deviation = max(abs(m["functional_axis_screen_degrees"] + 45)
                             for m in icon_metrics.values() if "functional_axis_screen_degrees" in m)
    report = {"installed_png_count": len(now), "target_count": len(TARGETS),
              "modified_target_count": len(set(modified) & TARGETS),
              "unchanged_non_target_count": len(baseline_hashes) - len(TARGETS) - len(unexpected),
              "unexpected_modified_pngs": unexpected, "new_pngs": new_files,
              "geometry_failures": failures,
              "maximum_sampled_functional_axis_deviation_degrees": round(max_axis_deviation, 6),
              "icons": icon_metrics}
    (HERE / "geometry-and-preservation.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({k: v for k, v in report.items() if k != "icons"}, indent=2))
    print(sheet())
    sheet(True)
    if unexpected or new_files or failures:
        raise SystemExit(1)


if __name__ == "__main__":
    baseline() if "--baseline" in sys.argv else review()
