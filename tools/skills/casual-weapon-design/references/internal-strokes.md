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

The user accepted **9 px for the cat and weapon main lines on the 256 x 240 character canvas**. Keep that scale for lines actually designated as main, including an internal line when it performs the same primary shape-defining role. This does not make every plate edge, cuff, sole or material boundary a main line. Retain the accepted warm-brown main contour `#583f21`; choose softer surface ink in relation to the material and reference. Keep rounded joins and caps.

The earlier recipes assigning every major component boundary 9 px, every other seam 4–5 px / 2–3 px, and every interior `#62656B` were over-prescriptive interpretations, not a reference-derived or user-approved complete system. They must not drive the next generation. Secondary/detail widths remain item-specific until checked in context. The previously accepted thin bowstring is a functional exception; do not bulk it up with the contour.

## Before the next redraw

1. Place the item at its intended worn size on the unchanged cat. Identify silhouette edges (including holes), actual overlaps, surface seams/ornament, and filled material planes. Mark which lines are truly main.
2. Choose each surface line's weight and color beside the local fill. Match the reference's hierarchy and open color areas; do not globally recolor all interior pixels or outline every segmented region.
3. Prompt or author this construction directly. Preserve raw generations and prompts. If broad fills or gaps are missing, revise the design; global dilation or reconstructing label adjacency cannot supply the intended authored linework.
4. Inspect the fitted 256 x 240 composition, native 128 x 120 hero and intended inventory size. Check silhouette continuity, occlusion, stronger versus subordinate lines, material-related ink, fill areas and junctions. Measure claimed main widths after fitting, away from corners; do not claim all strokes are equal from a visual impression.

After this study, the user requested one weapon sample and rated the resulting spear **9/10** on 2026-10-20. Use the [accepted spear and selected prompt](accepted-spear.md) as the current visual baseline. Its 9 px main-line design target is distinct from the measured straight shaft, approximately 8.2 px after fitting; no claim that every generated contour is exactly 9 px is supported.

The earlier `hero-equipment` and `hero-equipment-v2` prototypes remain unapproved. Their mechanical boundary reconstruction and uniform-gray interiors are not superseded into approval by the accepted spear. Keep proposal approval separate from production integration; the spear currently remains a review asset.
