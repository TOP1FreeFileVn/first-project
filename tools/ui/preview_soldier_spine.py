"""Render frames of a soldier skeleton from make_soldier_spine.py, for review.
    python -I tools/ui/preview_soldier_spine.py [rig_folder] [anim]

Only what that rig uses: bone translate/rotate/scale keys with linear interpolation, no setup
rotations, region attachments. Writes <spine>/preview/<anim>-strip.png and <anim>.gif.
    python -I tools/ui/preview_soldier_spine.py [soldier_id] [anim]
"""
import json
import math
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs" / "design" / "2026-10-23" / "soldier-rig"

def sample(track, t, default):
    if not track:
        return default
    times = [k.get("time", 0.0) for k in track]
    if t <= times[0]:
        return track[0]
    for i in range(len(track) - 1):
        if times[i] <= t <= times[i + 1]:
            a, b = track[i], track[i + 1]
            u = (t - times[i]) / (times[i + 1] - times[i])
            return {k: a.get(k, default.get(k, 0)) + (b.get(k, default.get(k, 0)) - a.get(k, default.get(k, 0))) * u
                    for k in set(a) | set(b) if k != "time"}
    return track[-1]

def pose(skel, anim, t):
    bones = {b["name"]: b for b in skel["bones"]}
    timeline = skel["animations"][anim]["bones"] if anim else {}
    world = {}
    for b in skel["bones"]:
        tl = timeline.get(b["name"], {})
        tr = sample(tl.get("translate"), t, {"x": 0, "y": 0})
        rot = sample(tl.get("rotate"), t, {"value": 0})
        sc = sample(tl.get("scale"), t, {"x": 1, "y": 1})
        lx, ly = b.get("x", 0) + tr.get("x", 0), b.get("y", 0) + tr.get("y", 0)
        r = math.radians(rot.get("value", 0))
        sx, sy = sc.get("x", 1), sc.get("y", 1)
        local = (math.cos(r) * sx, -math.sin(r) * sy, math.sin(r) * sx, math.cos(r) * sy, lx, ly)  # a b c d tx ty
        if "parent" in b:
            pa, pb, pc, pd, px, py = world[b["parent"]]
            a, bb, c, d, x, y = local
            world[b["name"]] = (pa * a + pb * c, pa * bb + pb * d, pc * a + pd * c, pc * bb + pd * d,
                                pa * x + pb * y + px, pc * x + pd * y + py)
        else:
            world[b["name"]] = local
    return world

def main(rig, anim, name="soldier_kiem"):
    folder = Path(rig) / "spine"
    skel = json.loads((folder / f"{name}.json").read_text(encoding="utf-8"))
    page = Image.open(folder / f"{name}.png").convert("RGBA")
    regions, cur = {}, None
    for line in (folder / f"{name}.atlas").read_text(encoding="utf-8").splitlines()[3:]:
        if line.startswith("bounds:"):
            x, y, w, h = map(int, line[7:].split(","))
            regions[cur] = page.crop((x, y, x + w, y + h))
        elif line.strip() and ":" not in line:
            cur = line.strip()
    att = skel["skins"][0]["attachments"]
    dur = max(k.get("time", 0) for tl in skel["animations"][anim]["bones"].values() for ch in tl.values() for k in ch)
    frames = []
    W, H, ox, oy = 300, 290, 150, 268   # canvas and where skeleton origin lands
    for i in range(12):
        t = dur * i / 12
        world = pose(skel, anim, t)
        canvas = Image.new("RGBA", (W, H), (216, 228, 222, 255))
        for slot in skel["slots"]:
            a = att[slot["name"]][slot["attachment"]]
            img = regions[slot["attachment"]]
            wa, wb, wc, wd, wx, wy = world[slot["bone"]]
            # attachment centre in skeleton space -> canvas (y down)
            cx = wa * a["x"] + wb * a["y"] + wx
            cy = wc * a["x"] + wd * a["y"] + wy
            angle = math.degrees(math.atan2(wc, wa))
            sx, sy = math.hypot(wa, wc) * a.get("scaleX", 1), math.hypot(wb, wd) * a.get("scaleY", 1)
            im = img.resize((max(1, round(img.width * sx)), max(1, round(img.height * sy))), Image.LANCZOS)
            im = im.rotate(angle, resample=Image.BICUBIC, expand=True)
            canvas.alpha_composite(im, (round(ox + cx - im.width / 2), round(oy - cy - im.height / 2)))
        frames.append(canvas)
    out = folder / "preview"
    out.mkdir(exist_ok=True)
    strip = Image.new("RGBA", (W * 6, H * 2))
    for i, f in enumerate(frames):
        strip.paste(f, ((i % 6) * W, (i // 6) * H))
    strip.save(out / f"{anim}-strip.png")
    frames[0].save(out / f"{anim}.gif", save_all=True, append_images=frames[1:], duration=round(dur * 1000 / 12), loop=0, disposal=2)
    print(out / f"{anim}-strip.png")

if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else str(BASE.parent / "soldier-rig-v2"), sys.argv[2] if len(sys.argv) > 2 else "run")
