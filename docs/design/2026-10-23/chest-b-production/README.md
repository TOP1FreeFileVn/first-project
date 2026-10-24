# Selected B strongboxes — production preparation

The user selected family B from the generated chest concepts. These assets preserve those generated silhouettes and keyholes. They are raster cleanup and animation splits, not a replacement drawing or the Claude canvas/vector workflow.

The later gold brief explicitly requested a more detailed, slightly glossier shop chest. Gold therefore uses the upgraded one-chest source with its connected brass frame, four large recessed fasteners and restrained cream highlights. On October 24, silver received a separate object redesign with an arched lid, connected steel framing and four inset fasteners; its generated RGB and transparency are preserved. Wood retains its original flat material fills. No top jewel, hanging gold tab or new ornament is added during preparation.

## Sources and recipe

- Wood: `docs/design/2026-10-23/chest-concept-options/png/B1.png`
- Silver upgraded: `output/imagegen/silver-chest-2026-10-24/silver-raw.png`, prepared as `docs/design/2026-10-24/silver-chest-upgrade/silver-source-crop.png`. The earlier `B2.png` stays available as the previous design.
- Original B sheet: `output/imagegen/chest-options-2026-10-23/B-raw.png`
- Upgraded gold: `output/imagegen/chest-options-2026-10-23/B-v2-raw.png`
- Gold source crop: `gold-source-crop.png`, cropped from `[109,55,1426,927]` after removal of only the border-connected pale matte.
- Reproducible preparation: `python tools/ui/build_strongbox_chests.py`

Generation records and prompts remain alongside the untouched imagegen originals. Every production tier records the input SHA256 in `game/ui/art/chests/strongbox-b/manifest.json`. The same data is emitted as `assets.gd` for exported builds.

Wood cleanup uses source RGB samples to choose a few flat material fills. No contour tracing, global outline dilation, new geometry or automatic adjacency reconstruction is used. A half-source-pixel AA pass smooths its palette boundaries, recovering the outer antialias only inside the original alpha boundary. Gold retains a short brass highlight/material ramp, while its coral panel is flattened. Upgraded silver bypasses palette cleanup: generated RGB and alpha are preserved inside the meaningful art crop. Its source measurement and raw crop are recorded independently in the manifest.

## Runtime layer contract

Each `game/ui/art/chests/strongbox-b/{wood,silver,gold}/` folder contains `closed.png`, `body.png`, `lid.png`, and `latch.png`. They share one padded source frame and one normalized `texture_rect`, with the seam at `(0,0)` and author width208. Uniform scaling preserves proportions.

Draw the native cavity/rim, fixed body, moving lid, then fixed latch. Only the lid moves. The lock has not been duplicated onto the lid: its small source-occluded strip is repaired using the adjacent strap colors and existing level seam. Below the seam, body contains the original lock pixels exactly under the fixed latch overlay; it adds no visible detail. Layer-selection masks are saved as `latch-mask.png`.

`manifest.json` records `texture_rect`, `cavity_rect`, `latch_half_width`, nominal `main_width`, and source measurements for every tier. The four textures are not individually cropped and must not be fitted independently.

## Stroke observations

Main ink is warm brown `#583f21`. Secondary wood seams are material brown; silver seams are quiet blue-gray/gray-green. Gold's recessed hardware and structural bevels use related ochre, separate from its main contour. Broad material planes remain fills.

Measured straight source wall/bottom runs away from corner joins, thresholding opaque brown pixels with R<120, G<100, A>240:

| Tier | Source widths sampled | Fitted range at author width208 | Nominal runtime rim |
| --- | --- | --- | --- |
| Wood | 13–15px | 6.52–7.52px | 6.77px |
| Silver upgraded | 26px on sampled straight wall/bottom runs | 4.694px | 4.694px |
| Gold upgraded | 27–30px | 4.32–4.80px | 4.56px |

These are observed ranges, not a claim that all generated contours are exactly9px. The larger premium shop/opening placement increases its on-screen contour weight. No dilation was used to force the source gold contour to match the other tiers.

## Review outputs

- `production-comparison.png`: source, prepared production palette, and separated opening pose. Gold explicitly retains the requested controlled polish.
- `actual-size-icons.png`: untouched128/96/64/48/32px exported icon samples, each fitted to90% width with uniform scale.
- `{wood,silver,gold}-closed-assembled.png`: body+lid+latch composed at closed pose.
- `closed-layer-check.json`: wood and gold reconstruct exactly. Silver has a maximum RGBA residual of `[1,2,2,2]` around partially transparent repaired pixels, with zero pixels differing by more than 3. The runtime closed pose draws the intact `closed.png`.

Native integration and viewport review are performed by the runtime task. This folder's opening board is an art/layer review and does not replace that native check.
