# Authored bow refinement

The GPT Image2.5 bow4 source is `../raw/bow-iteration-4.png`, generated node54:2 in file2uKzqvXeOSPQqfaow6s7TU. It produced a useful recurve silhouette but failed lineweight:21–26sourcepx at the wooden edges, far below the desired final9px. The user correctly rejected the mismatch.

Following authorization from the parent task, `bow-refined.svg` hand-authors the recurve silhouette, broad fill and openings together with cubic Beziers. It preserves the generated direction—recurved shoulders, compact brass tip sockets and a coral grip—while changing the proportions to support a native9px main contour. It is not the untouched generated raster and is not labeled as one.

- Main structural/silhouette line:9px on256×240.
- Functional string:1.4px, outside the face, relaxed carry/ready pose.
- Leather surface seams:1.8px muted red-brown.
- Fixed paw/grip:160,166; no character/body changes.
- Full native bounds after the centered-handle correction:143.333,87.667,229.667,238.333; no clipping.

The user then identified that the separately outlined leather pad looked attached to the side of the bow. The previous SVG is preserved as `bow-refined-before-handle-fix.svg`. The current SVG has one continuous wooden riser bounded by x148..172 and centered at x160. Its joins at y151 and181 are symmetric about the fixed grip/paw y166. Coral leather is a clipped material fill inside the riser, with the main body edge drawn once. The actual raster coral center at native y166 measures x160.0. See `bow-handle-center-check.png` for the isolated guide proof.

Reproduce the raster with Godot4.7.2:

`Godot --headless --path . --script docs/design/2026-10-20/hero-equipment-v3/weapons/authored/render_bow.gd`

Then run `python docs/design/2026-10-20/hero-equipment-v3/weapons/authored/proof_bow.py` to rebuild the review sheet and measurements. Godot renders SVG directly at3×, yielding transparent768×720 PNG. The current upper-shoulder normal sample measures8.75nativepx of opaque ink; antialias coverage surrounds it and the authored SVG stroke is9px.

No morphology, dilation, skeletonization, segmented-edge rebuilding or production integration occurred.
