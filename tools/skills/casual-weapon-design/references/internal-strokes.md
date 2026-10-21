# Cat-defender: stroke reference and authoring

Re-studied on 2026-10-20 after the user stopped the equipment redraw and rejected its stroke treatment. Reference: Figma file `wMtwWaYIiKUchUdq5YdTm5`, page `3443:2`, especially group `3443:119` (KingEquip) and the held-character sprites. Local screenshots, node IDs and a comparison sheet are in `docs/design/2026-10-20/stroke-reference-study/` in the project.

## Observed in the reference

- **An edge against the background is a silhouette edge**, including the inside of the crown opening and the necklace loop. Do not lighten it merely because it is geometrically inside the object.
- **Surface ink responds to the material.** Armor0111 has muted red-brown lines over terracotta; Armor0113 uses gray on steel; Armor0115 uses ochre/brown on gold. These are examples of a relationship to the local fill, not three mandatory swatches. Soft black/gray is useful where appropriate, not one ink for every interior.
- **Overlap, seam and ornament have different visual force.** The boots' contact edges are stronger than their small surface seams. A major contour may continue into an overlap, while a small join can be lighter and thinner. Do not infer weight from the part's name alone.
- **A dark region is not necessarily a stroke.** The sword's gray blade strip, the back plane of the crown and broad gray planes on the wizard are filled regions. Do not skeletonize or thicken them into lines. The reference includes light/shadow treatments; studying its linework does not authorize adding those effects to this project's flat cat art.
- **A color boundary need not have ink.** Retain broad readable fills; use selective seams and open-ended marks rather than a closed thick ring around every material patch. Resolve shared edges once and let foreground parts occlude hidden contours.

Figma screenshots here are displayed at 128 x 128 for equipment and 160 x 160 for heroes. They establish visual relationships, not a measured vector stroke specification.

## Current project decisions

### Main and secondary stroke contract

Apply this contract to weapons and the five hero equipment types, for both generated raster art and authored vectors. Classify a line by its visual function before choosing its width or color.

| Line class | Purpose | Weight and ink |
| --- | --- | --- |
| Main stroke | Defines the silhouette, including openings against the background, or a primary shape-defining overlap. A main line may continue inside the object. | Match the cat: **9 px design target on the 256 × 240 character canvas**, warm brown **`#583f21`**, with rounded joins and caps. Measure after fitting; generated contours can vary locally. |
| Secondary stroke | Describes subordinate construction such as surface seams, grip wraps, small joins, ornament or a bowstring. | Use a thinner, visually quieter line that survives downscaling. Choose width per item and softer ink relative to the local fill: soft gray on steel, muted red-brown on leather, ochre/brown on gold are examples. |
| Filled material plane | Separates broad material/color areas, such as the two steel planes on the accepted spear. | Keep it as a fill; add no separating stroke when the color boundary already reads clearly. |

A plate edge, cuff or sole is not automatically a main line. A hole's exposed edge remains a silhouette edge even when it lies inside the object's bounds. Resolve a shared edge once; foreground parts hide the contours behind them. Preserve broad fills and open gaps instead of outlining every color patch.

The user's bow correction requires a **visible secondary stroke for the string**. In the current v4 bow this is **3 px on the 256 × 240 canvas**, in secondary brown ink, against the 9 px main contour. Keep it continuous between the tips and check it at **128 × 120**. The former 1.4 px line disappeared when reduced. This is a bow-specific choice, not a universal 3 px rule for surface seams.

The earlier recipes assigning every major component boundary 9 px, every other seam 4–5 px / 2–3 px, and every interior `#62656B` were over-prescriptive interpretations. Keep secondary widths item-specific; do not reinstate that fixed ladder or uniform-gray treatment.

## Before the next redraw

1. Compose the item at its intended size on the unchanged cat, or in its standalone icon frame for stat-only gear. Identify silhouette edges (including holes), actual overlaps, surface seams/ornament, and filled material planes. Mark main and secondary lines by function.
2. Record the 9 px main-line target and each secondary line's intended weight/material-related ink in the art brief. Match the reference's hierarchy and open color areas; do not globally recolor all interior pixels or outline every segmented region.
3. Include that hierarchy in the generation prompt or authored vector paths before cleanup. Preserve raw generations and prompts. If broad fills or gaps are missing, revise the design; global dilation or reconstructing label adjacency cannot supply the intended authored linework.
4. Inspect the fitted 256 x 240 composition, native 128 x 120 hero and intended inventory size. Check silhouette continuity, occlusion, stronger versus subordinate lines, material-related ink, fill areas and junctions. Measure claimed main widths after fitting, away from corners; do not claim all strokes are equal from a visual impression.

After this study, the user requested one weapon sample and rated the resulting spear **9/10** on 2026-10-20. Use the [accepted spear and selected prompt](accepted-spear.md) as the current visual baseline. Its 9 px main-line design target is distinct from the measured straight shaft, approximately 8.2 px after fitting; no claim that every generated contour is exactly 9 px is supported.

The earlier `hero-equipment` and `hero-equipment-v2` prototypes remain unapproved. Their mechanical boundary reconstruction and uniform-gray interiors are not superseded into approval by the accepted spear. Keep proposal approval separate from production integration; the spear currently remains a review asset.
