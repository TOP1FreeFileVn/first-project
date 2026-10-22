# Cat-defender: standalone equipment working baseline

Use this reference when drawing this project's hero helmet, armor or boots icons. The shared [main/secondary contract](internal-strokes.md) remains authoritative; this file records the narrower decisions from the 2026-10-22 trials. The armor received **6/10**. The user said the helmet and boots were looking reasonable, then requested **a pair of boots** and consolidation into the skill. This establishes a working direction, not a perfect benchmark or permission to replace production art.

## Visual and source references

Open the [current review image](../assets/equipment-icon-baseline.png) before extending the set. It shows the paired-boots revision; the earlier single-boot proposal is superseded.

The [armor working image](../assets/equipment-armor-working.png) shows the same current fill/line profile. Its 6/10 review is useful evidence of the requested hierarchy, not an example to treat as finished illustration quality.

The reference for material grouping is Figma [KingEquip, node 3443:119](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3443-119), particularly [Armor0113, node 3447:7569](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3447-7569). The observed lesson is one dominant material family with restrained accents, not a universal two-swatch limit. Related lighter/darker fills can describe a material without introducing several competing accent colors.

Repository sources:

- `docs/design/2026-10-22/armor-canvas/item.js`: armor geometry and named line profiles; Canvas and SVG use the same paths.
- `docs/design/2026-10-22/hero-gear-canvas/helmet.js` and `boots.js`: helmet and paired-boots geometry, with matching Canvas/SVG paths.
- Each folder's `preview.html`, round screenshots, `svg/` and `godot/` hold the review evidence. The armor folder also contains the Figma screenshots.

## Current standalone profile

These are the current silver set's values on a **256 × 256 standalone icon**, before reducing to the display resolution:

| Role | Value | Use in this trial |
| --- | --- | --- |
| Main | **11.35 px**, `#583f21` | Coherent silhouette and exposed openings; round joins/caps |
| Secondary | **7.41 px**, `#9b7f58` | Subordinate construction, including armor armpit joins |
| Steel fill | `#d9e0e8` | Dominant broad material area |
| Steel plane fill | `#a8b4c7` | Broad unlined region of the same material family |

The secondary width follows the user's explicit adjustments: **3.8 → 4.94 (+30%) → 7.41 (+50%)**. Do not fall back to the older 4.94 value or add a third hairline style. These values are a profile for this current set, not a universal main/secondary ratio for all equipment. Keep secondary marks visibly subordinate through their role, ink and amount of detail as well as width.

The main width was calibrated against the accepted sword in the real card: sword source main approximately **13 px**, sword art fit **0.68**, gear fit **0.78**; `13 × 0.68 / 0.78 ≈ 11.33`. This explains 11.35. It does **not** replace the held-art target of 9 px on the 256 × 240 cat canvas. If the card fit or composition changes, inspect and recalibrate the rendered comparison.

## Construction choices to preserve

- Helmet, armor and boots are **stat-only icons**. Keep them upright and separate from the cat. Boots do not use the weapon's 45-degree presentation.
- Draw boots **as a pair**. Establish both boots' positions, overlap and overall fit before choosing final line widths. Shrinking a fully stroked single boot twice can make the set's lines too weak. Retain two readable cuffs and toes without turning the overlap into a dark knot; hide rear edges behind the front boot.
- Main ink defines the outside and real openings, including the helmet's face opening or boot cuff. The armor shoulder-to-body join at the armpit is explicitly **secondary**. Do not infer that every component overlap deserves main weight.
- Use broad flat fills to separate material planes. Leave their readable shared boundaries unlined. Resolve each visible edge once; remove hidden contours.
- Retain construction marks that explain the item. Do not restore the rejected thin gray chest/flank curves, outline every panel, or add seams merely to demonstrate two line classes.
- Keep this silver trial in its material family. Do not justify extra gold collars, colored shoulders or gems by matching the cat's fur. Other materials or accents require an actual design reason and reference; this is not a ban on color in unrelated equipment.

## Evidence before extending or integrating

Capture and **open an actual Canvas screenshot** after changing the source. Export those same paths and inspect the native Godot renders at **32/48/64/96 px**, plus 256 px for line-role checks. Inspect silhouette, clipping, openings, toe/cuff separation, seams, occlusion and paired-boots negative space. Check the clean art and a marked main/secondary view; a valid SVG or successful export proves neither hierarchy nor readability.

Keep previous/new comparisons at equal perceived size and show the final pair in its intended slot fit. Record source widths separately from measured raster cores, which exclude some antialias pixels. Preserve earlier review rounds. Keep proposals separate from production until integration is authorized; the 6/10 armor review and the instruction to strengthen the skill do not approve every draft for installation.
