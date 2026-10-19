# User-selected weapon detail reference

Inspected 2026-10-19 after the user rejected mismatched GPT raster styling and an indiscriminate stroke-thickening pass.

Source: [Asset bổ sung · Kho PNG](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3470-2), Cat Gunner 1.1.64 reference catalogue. These are third-party references for designing the game's own assets, not approved replacements to copy into production.

## Reference anchors

| Reference | Figma image node | What to study |
| --- | --- | --- |
| Pistol sprite, source ID931 | `3471:289` | Broad metal body, clearly separate grip, a few intentional slots/cutouts |
| Rotary gun, source ID876 | `3471:437` | Repeated barrel modules with space between them; readable grip and support |
| Shotgun, source ID581 | `3471:578` | Long steel/wood masses; sparse construction boundaries |
| Scoped rifle, source ID635 | `3471:1053` | Scope, receiver, stock, barrel and grip remain separately readable |
| Cat sprite, source ID666 | `3471:252` | Warm rounded cartoon contour and broad coat fills |
| Cat_Gun illustration, source ID831 | `3471:2283` | Rifle components remain legible beside the cat; face remains a focal point |
| Icon_Gun menu symbol, source ID492 | `3471:3011` | Intentionally simpler symbol with a much heavier rim; a different use case |

The local study with extracted examples and sheet screenshots is at `docs/design/2026-10-19/weapon-redesign/reference-study/`.

## Detail grammar

1. **Primary mass:** the silhouette and largest parts establish weapon family. A scoped rifle, rotary gun and launcher remain different without their colors.
2. **Material blocks:** broad steel, wood and colored housing regions explain the construction. Every outlined part has enough fill area to read. A broad flat light strip or second material plane is acceptable when supported by the game's art; avoid soft rendering and photoreal texture.
3. **Functional modules:** preserve an oversized scope, barrel collar, magazine, guard or socket where it explains the object. Detail is organized structure, not a scatter of grain, scratches and tiny rivets.
4. **Open space:** trigger holes, barrel gaps and spaces between attachments are designed alongside stroke width. Thickening an existing thin-line image cannot create this room.
5. **Line hierarchy:** exterior contour is strongest, essential part separations are lighter, small cues are sparse. Match optical weight beside a cat, rather than using the same pixel width on every edge and hole.
6. **Set development:** related guns repeat a recognizable receiver/stock/barrel layout while progressing material colors, attachments and mass. Preserve family construction instead of inventing unrelated decorative symbols for every tier. Do not infer gameplay progression from art alone.

The page mixes flat cat equipment, glossy fish/gems, effects, dragons and UI symbols. Sample the relevant weapon subset. Do not apply a fish's glossy rendering, a currency highlight, or a menu symbol's heavy border to detailed held equipment.

## Correct the rejected pipeline

The rejected V3 combined thin realistic woodgrain and small mechanical marks with an enlarged outer brown band. The band closed the trigger hole, compressed the staff bead into a dot, and turned guard/grip junctions into brown knots. Neither the thin original nor the blanket thickened version matches the reference's designed part hierarchy.

For the next generated proposal, design wider component fills and deliberately open negative spaces at generation time. Request one shared family treatment and a small number of specific construction modules. Retouch local boundaries only when needed; reject an output requiring global morphological dilation to become stylistically compatible. Compare the proposal to the relevant reference at equal apparent size, then with the current game cat at native display size.

The examples on page 3470:2 are primarily firearms. The user subsequently supplied main-library page 3443:2, which DOES contain direct sword, axe, spear, staff and other held-weapon examples. Read [held-character-study.md](held-character-study.md) and prioritize those for melee/magic composition. Do not invent gun motifs on a sword or switch to glossy crossed-sword menu styling.

The user's selected generation route remains GPT Image 2.5. Study and improve the design brief before spending on another batch; do not replace the requested illustration workflow with crude geometric SVG reconstruction.
