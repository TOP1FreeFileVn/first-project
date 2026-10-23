"""Promote approved V4/pilot assets; remove only duplicate baked live props."""
from pathlib import Path
import hashlib
import json
import shutil
from PIL import Image, ImageDraw, ImageFilter
import numpy as np

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
DOCS = REPO / "docs/design/2026-10-20"
V4 = DOCS / "cardboard-castle-lobby-v4"
PILOT = DOCS / "cardboard-tunnel-svg-pilot"
CAT_PARTS = DOCS / "cat-spine-parts/svg"
REVIEW = HERE / "review"
REVIEW.mkdir(exist_ok=True)
(REVIEW / ".gdignore").write_text("", encoding="utf-8")
(HERE / "source").mkdir(exist_ok=True)
(HERE / "source/.gdignore").write_text("", encoding="utf-8")

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

copies = []
def copy(source, relative):
    target = HERE / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    # Rebuilding the older V4 extraction must retain the newer editable SVG
    # designs already installed in production. Their current bytes are recorded.
    preserve_vector = (HERE / "props/manifest.json").is_file() and relative.split("/")[0] in {"tunnel", "bed"} and target.is_file()
    if preserve_vector:
        source = target
    else:
        shutil.copyfile(source, target)
    assert sha(source) == sha(target)
    copies.append({"asset": relative, "source": source.relative_to(REPO).as_posix(),
                   "sha256": sha(target), "exact_copy": True, "preserved_current_vector": preserve_vector})

copy(V4 / "processed/terrain-background.png", "source/terrain-approved-v4.png")
copy(V4 / "processed/castle-layer.png", "castle-layer.png")
copy(V4 / "processed/castle-crop.png", "castle-crop.png")
for source_folder, target_folder in [(PILOT / "art", "tunnel"), (PILOT / "bed-art", "bed")]:
    for name in ["source.svg", "shadow.svg", "rear.svg", "interior.svg", "front.svg", "geometry.json"]:
        copy(source_folder / name, f"{target_folder}/{name}")
for kind in ["cat_cream", "cat_tabby", "cat_calico"]:
    for name in ["assembled", "tail", "foot_L_image", "foot_R_image", "body", "paw_L_image", "paw_R_image", "head"]:
        copy(CAT_PARTS / kind / f"{name}.svg", f"cats/{kind}/{name}.svg")

original = Image.open(V4 / "processed/terrain-background.png").convert("RGB")
pixels = np.asarray(original).astype(np.float32)
height, width = pixels.shape[:2]

def polygon(points):
    mask = Image.new("L", original.size)
    ImageDraw.Draw(mask).polygon(points, fill=255)
    return mask

# Masks include each old prop's own contact shadow. Nearby approved decorative
# yarn/pillow silhouettes are protected before any replacement is composited.
tunnel_points = [(48,665),(90,645),(108,633),(149,635),(195,630),(222,630),
                 (238,636),(240,726),(260,738),(265,754),(258,773),(242,786),
                 (202,793),(102,796),(58,783),(28,768),(27,744),(47,731)]
bed_points = [(445,795),(469,791),(493,774),(509,769),(523,774),(589,779),
              (612,778),(626,784),(631,817),(638,830),(637,851),(626,874),
              (603,886),(565,890),(484,880),(439,866),(429,852),(432,823)]
ball_points = [(207,785),(222,785),(236,792),(244,807),(247,823),(242,839),
               (230,851),(213,855),(196,850),(184,838),(180,823),(184,805),(194,793)]
pillow_points = [(631,830),(653,831),(675,838),(691,849),(699,863),(698,880),
                 (689,893),(673,901),(651,907),(622,908),(599,902),(579,892),
                 (571,879),(570,865),(576,851),(589,841),(608,833)]
post_shadow = Image.new("L", original.size)
ImageDraw.Draw(post_shadow).ellipse((518,735,662,784), fill=255)
protected = np.maximum(np.maximum(np.asarray(polygon(ball_points)), np.asarray(polygon(pillow_points))), np.asarray(post_shadow))

def grass_field(context):
    # Fit only quiet bright lawn. Path, props, shadows and grass-tuft strokes
    # are excluded so no isolated decoration becomes a horizontal colour band.
    yy, xx = np.indices((height, width))
    rr, gg, bb = pixels.transpose(2,0,1)
    valid = (rr>170)&(gg>185)&(gg<225)&(rr<gg*.995)&(rr>gg*.88)&(bb<gg*.8)&(bb>gg*.5)
    x0,y0,x1,y1 = context
    valid &= (xx>=x0)&(xx<x1)&(yy>=y0)&(yy<y1)
    nx = (xx-(x0+x1)/2)/(x1-x0)
    ny = (yy-(y0+y1)/2)/(y1-y0)
    features = np.stack([np.ones_like(nx), nx, ny, nx*nx, nx*ny, ny*ny], axis=-1)
    design = features[valid]
    targets = pixels[valid]
    keep = np.ones(len(targets), dtype=bool)
    for _ in range(4):
        coeff = np.linalg.lstsq(design[keep], targets[keep], rcond=None)[0]
        residual = np.max(np.abs(design@coeff-targets), axis=1)
        keep = residual < max(2.5, float(np.median(residual))*2.8)
    return (features@coeff).astype(np.float32)

clean = pixels.copy()
union = np.zeros((height, width), dtype=np.float32)
cleanup = []
for label, points, context in [
    ("tunnel", tunnel_points, (0,610,330,865)),
    ("bed", bed_points, (380,700,720,950))
]:
    mask = polygon(points).filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.GaussianBlur(3))
    weight = np.asarray(mask, dtype=np.float32) / 255
    weight[protected > 0] = 0
    if label == "tunnel":
        weight[:634] = 0  # Preserve the approved castle contact shadow.
    field = grass_field(context)
    clean = clean * (1-weight[..., None]) + field * weight[..., None]
    union = np.maximum(union, weight)
    Image.fromarray(np.uint8(weight*255)).save(REVIEW / f"cleanup-{label}-mask.png")
    cleanup.append({"id": label, "polygon": points, "sample_context": context,
                    "method": "robust quadratic fit to observed bright lawn only; excludes path/props/shadows/tufts; 4px mask expansion, 3px feather; protected yarn, pillow and post base",
                    "mask": f"review/cleanup-{label}-mask.png"})

clean_image = Image.fromarray(np.uint8(np.clip(np.rint(clean), 0, 255)))
clean_image.save(HERE / "terrain-clean.png")

# Restore the existing teal pillow above the live bed where V4 intended it to
# overlap. Its pixels remain unchanged in terrain too; this static layer only
# restores foreground ordering and is not another live prop.
rgb = np.asarray(original)
r, g, b = [rgb[..., i].astype(float) for i in range(3)]
grass = (g >= r*.98) & (r >= g*.87) & (b < g*.82) & (g > 120)
pillow_candidate = (np.asarray(polygon(pillow_points)) > 0) & ~grass
pillow_alpha = Image.fromarray(np.uint8(pillow_candidate)*255).filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(.3))
pillow_overlay = original.convert("RGBA")
pillow_overlay.putalpha(pillow_alpha)
pillow_overlay.save(HERE / "pillow-foreground.png")

# The original yarn ball is also a sortable static foreground object. Its
# approved RGB pixels are copied verbatim; only an alpha silhouette is derived.
yarn_candidate = (np.asarray(polygon(ball_points)) > 0) & ~grass
yarn_alpha = Image.fromarray(np.uint8(yarn_candidate)*255).filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(.3))
yarn_overlay = original.convert("RGBA")
yarn_overlay.putalpha(yarn_alpha)
yarn_overlay.save(HERE / "yarn-foreground.png")

scene = clean_image.convert("RGBA")
scene.alpha_composite(Image.open(HERE / "castle-layer.png").convert("RGBA"))
prop_placements = [
    {"id":"tunnel", "ground":[165,790], "scale":0.82, "source_folder":"tunnel", "proof_source":PILOT/"art/png/source.png"},
    {"id":"bed", "ground":[530,866], "scale":0.86, "source_folder":"bed", "proof_source":PILOT/"bed-art/png/source.png"}
]
for placement in prop_placements:
    scale = placement["scale"]
    prop = Image.open(placement["proof_source"]).convert("RGBA").resize((round(256*scale), round(240*scale)), Image.Resampling.LANCZOS)
    pos = (round(placement["ground"][0]-128*scale), round(placement["ground"][1]-224*scale))
    scene.alpha_composite(prop, pos)
scene.alpha_composite(pillow_overlay)
scene.alpha_composite(yarn_overlay)
scene.convert("RGB").save(REVIEW / "scene-proof.png")
clean_image.save(REVIEW / "clean-terrain-proof.png")

unchanged = np.asarray(clean_image)[union == 0] == rgb[union == 0]
assert unchanged.all()
assert (np.asarray(clean_image)[protected > 0] == rgb[protected > 0]).all()
assert len(copies) == 39

manifest = {
    "date": "2026-10-20", "status": "approved_design_assets_promoted_for_live_game_integration",
    "screen": [720,1280],
    "asset_root": "res://game/assets/lobby/cardboard/",
    "design_sources": {
        "v4": "docs/design/2026-10-20/cardboard-castle-lobby-v4/README.md",
        "v4_figma": "https://www.figma.com/design/2uKzqvXeOSPQqfaow6s7TU?node-id=66-2",
        "tunnel": "docs/design/2026-10-20/cardboard-tunnel-svg-pilot/art/README.md",
        "tunnel_figma": "https://www.figma.com/design/2uKzqvXeOSPQqfaow6s7TU?node-id=77-2",
        "bed": "docs/design/2026-10-20/cardboard-tunnel-svg-pilot/bed-art/README.md",
        "bed_figma": "https://www.figma.com/design/2uKzqvXeOSPQqfaow6s7TU?node-id=82-2",
        "cats": "docs/design/2026-10-20/cat-spine-parts/manifest.json"
    },
    "terrain": {"file":"terrain-clean.png", "position":[0,0], "size":[720,1280],
                "sha256":sha(HERE/"terrain-clean.png"), "source":"source/terrain-approved-v4.png",
                "derived_only_to_remove_duplicate_baked_live_props":True,
                "remaining_static_bitmap_props":["scratching post","yarn ball","teal pillow"],
                "no_baked_castle_or_cats":True, "cleanup":cleanup},
    "castle": {"layer":"castle-layer.png", "layer_position":[0,0], "layer_size":[720,1280],
               "painted_bounds":[156,290,591,647], "preview_crop":"castle-crop.png", "crop_size":[435,357],
               "crop_top_left":[156,290], "doorway_bottom":[365,595],
               "ramp_entry_approx":[337,644], "bitmap":True, "exact_approved_v4_copy":True,
               "original_raw_source_region":[100,225,790,780], "raw_to_approved_scale":0.646},
    "props":[{k:v for k,v in p.items() if k!="proof_source"} | {"canvas":[256,240], "ground_local":[128,224],
              "layer_order":["shadow","rear","interior","cat","front"], "vector":True} for p in prop_placements],
    "cats": {"kinds":["cat_cream","cat_tabby","cat_calico"], "source_root":"cats/", "pose":"original_front_only_all_states",
             "canvas":[256,240], "ground_local":[128,238], "foot_pivots":{"foot_L_image":[82,203],"foot_R_image":[174,203]},
             "layer_order":["tail","foot_L_image","foot_R_image","body","paw_L_image","paw_R_image","head"],
             "suggested_visual_scale":0.37,
             "v4_original_review_image_boxes":[{"kind":"cat_cream","xywh":[115,682,96,90]},
                                              {"kind":"cat_tabby","xywh":[323,686,108,101]},
                                              {"kind":"cat_calico","xywh":[496,772,96,90]}],
             "review_boxes_are_not_feet_anchors":True},
    "foreground":{"file":"pillow-foreground.png","position":[0,0],"size":[720,1280],
                  "purpose":"static approved pillow pixel restoration over live bed; not a second live entity"},
    "yarn_foreground":{"file":"yarn-foreground.png","position":[0,0],"size":[720,1280],
                       "depth_ground":[214,854],"painted_alpha_bounds":list(yarn_alpha.getbbox()),
                       "source":"source/terrain-approved-v4.png","rgb_exact_source_pixels":True,
                       "purpose":"static approved yarn pixel restoration, foot-sorted over cats behind the yarn; not a second live entity"},
    "qa":{"exact_copy_files":len(copies),"all_copy_sha256_match":True,
          "pixels_outside_cleanup_unchanged":bool(unchanged.all()),"protected_yarn_pillow_pixels_unchanged":True,
          "scene_proof":"review/scene-proof.png"},
    "copies":copies,
    "runtime_scope":"Assets and placement data only; Home/BattlePage/LobbyWorld implementation owned elsewhere."
}
(HERE/"integration-manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
print(json.dumps({"root":str(HERE),"copies":len(copies),"terrain_sha256":manifest["terrain"]["sha256"],"outside_cleanup_unchanged":bool(unchanged.all())}))
