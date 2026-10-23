# Diamond currency — review proposals

**Production update — 2026-10-23:** the selected wide brilliant purple diamond
is now integrated throughout the game via the accepted `icon_gem` artwork.
Canonical source: `game/ui/art_sources/currency_gem.svg`; regenerate with
`tools/ui/install_currency_art.py`. The notes below record the earlier demo stage.

User requested replacing the diamond icon after choosing the crossed-swords
combat-power icon. Three different silhouettes retain the purple currency identity:
wide brilliant diamond (recommended), rounded oblique cushion, and short hex crystal.

**Selected by the user:** Kim cương bè / `brilliant`. The gold-icon proposals
keep this exact shape and palette beside every gold alternative.

Art brief: flat lavender facets, warm `#583F21` outline, readable beside the gold
coin at 24–32px. Main profile 5.8 units on the 96px symbol source (1.45px at 24px).
Facet boundaries are broad color fills, not extra strokes. These versions need
no secondary ink; no gray hairlines, white gloss, gradient, offset extrusion,
glow or drop shadow. Keep currency contrast on both mint and kraft backgrounds.

Authoring: `icons.js` uses the project's shared Pen core for Canvas and identical
SVG paths. Inspect `canvas-review.png`, then run `export.cjs` and native render.
Proposals remain here for review; production currency, economy, and save data
are untouched. The full UI preview retains the chosen sword power plaque and
the five original bottom cartons.
