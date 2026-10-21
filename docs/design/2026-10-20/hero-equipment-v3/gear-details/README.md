# Hero equipment v3: gauntlet and boots

Generated on2026-10-20 using Figma `generate_image` with `gpt-image-2.5-sunburst` in authorized draft `2uKzqvXeOSPQqfaow6s7TU`. Prompts and node IDs are in `generation.json`; original1024x1024PNGs are under `raw/`.

Selected single pieces are gauntlet iteration4, node49:2, and boot iteration2, node43:2. The first iterations produced fine contours at worn size. Subsequent prompts authored broader fills and a substantially heavier silhouette. There was no global outline dilation, skeletonization, or segmented-region reconstruction. `build_details.py` removes the white matte and flattens existing painted regions to the accepted palette.

`processed/gauntlet.png` and `processed/boot.png` are transparent crops with16pxsource padding. Pair layers are provided on256x240canvas and3x768x720canvas, with mirrored left pieces and the same fixed pose for every loadout. Root assembly can adjust placement without changing the pieces.

| Item | Fitted size per piece | Left bounds | Right bounds | Main sample |
| --- | --- | --- | --- | --- |
| Gauntlet |38x34|75,149,113,183|141,149,179,183|125sourcepx →5.85nativepx|
| Boot |48x30|60,201,108,231|148,201,196,231|121sourcepx →6.59nativepx|

These are honest local measurements after fitting, not certification of uniform9pxweight. The main-line project target remains9px; the small wearable proposal is provided for optical review beside the cat. The selected gauntlet's lower brass/coral cuff lip meets the silhouette without an enclosing brown base; root assembly has been informed. Iteration5 archived an attempted continuous base but was not selected.

Opened and inspected `processed/details-review.png` after cleanup. Broad gray fill survives, boot material planes meet without an interior stroke, and no added finger cage, microhardware, gradients or shading remains. Production art has not been replaced by this subtree.
