# Three carton navigation icons — approval study

Scope: replace only Shop / Hero / Battle icon art after selection. Preserve the accepted carton interaction, captions, runtime badges, troop shield and summon portal. No production replacement in this study.

Shared brief: friendly, broad silhouettes with flat fills and warm brown rounded main contours. Secondary construction marks are subordinate; broad material regions have no dividing ink. Avoid stacked outlines at sword intersections. No gloss, gradients, shadows, new icon frames or baked notification dots.

Four alternatives: A familiar shop/hero/crossed-swords, B cat cardboard town, C compact merchant-bag/helmet/battle-axe, D travelling merchant/hero bust/battle standard. Each alternative must read at 26 px closed and 44 px selected. Sources author the same paths through Pen for Canvas and SVG; rendered for review in Godot.

Menu profile (independent of held weapon targets): 7.5 main / 4.2 secondary author units on a 200px canvas. A's compact crossed pair uses a 6.5 main contour after fitting to avoid overly dark guards. Final fitted measurements and observed limitations are recorded in review.json. Colors in common.js. The selected option may require further production polish.

## Review artifacts

- `options.png`: all 12 proposed icons, with 44px / 26px examples.
- `native-sizes.png`: current icons beside all alternatives at actual sizes.
- `in-game.png`: four five-carton strips from the production CartonNav control, with only the first three textures injected. The other tabs, boxes, font and interaction remain unchanged.
- `context/`: all three selected-tab states for each alternative, 12 real control captures.
- `review.json`: fitted widths, clipping check and visual observations.

A is the clearest conventional set. D's red banner is a distinct alternative for the battle tab. B's castle may evoke the summon portal, while C's bag may read wallet; these are semantic tradeoffs for review rather than automatic replacements. C's first sword/shield trial was replaced with an axe because the shield duplicated the troop tab. `round-1.png` preserves the first render review.

## Rebuild

1. `node docs/design/2026-10-23/nav-icon-options/export.mjs`
2. Run Godot headless with `--script res://docs/design/2026-10-23/nav-icon-options/render.gd -- --raw`; wait for completion.
3. `python docs/design/2026-10-23/nav-icon-options/prepare.py`
4. Run the same render script without `--raw`; wait for completion.
5. Run `CartonPreview.tscn` with the compatibility renderer and isolated APPDATA / LOCALAPPDATA. It disables save writes and injects the icon alternatives in preview instances only.
6. `python docs/design/2026-10-23/nav-icon-options/gallery.py`

The SVGs were visually checked in Godot. No browser screenshot or image-generation model was used for these vector alternatives.
