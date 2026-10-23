# Combat power icon candidates

**Production update — 2026-10-23:** the selected crossed swords on a cream
combat-power plaque are now integrated in the Hero UI. Canonical artwork:
`game/ui/art_sources/power_crossed.svg`; regenerate with
`tools/ui/install_currency_art.py`. The notes below record the earlier demo stage.

Review-only, replacing the generic star beside total combat power in the
paperboard equipment demo. Production UI and bottom bar remain unchanged.

**Current selection:** the user chose **Hai kiếm chéo**. After the dark plaque
hid its brown contour, the active demo now uses a light cream `#F6E4B8` insert
with dark brown `#583F21` numerals and a single flat contour. The chosen icon
is displayed at 25px; no white halo or extra strokes are added to the artwork.
The fist stays only as an archived candidate. Both active demo fragments use
the selected sword; the original production game art has not been replaced.

- **Hai kiếm chéo:** two short, broad, symmetric steel blades with gold guards;
  total combat power, distinct from the single sword used for attack.
- **Nắm đấm mèo:** compact warm cat paw with broad knuckles; more characterful,
  with a possible melee-attack interpretation.

Both use flat fills and warm brown `#583F21`. Main contours are 5.8 units on
the 96px source (1.27px at 21px / 1.45px at 24px). Only the fist needs secondary
construction lines: 3.6 units in material-related ochre `#A5763C`. There is no
generic third line class, decorative thin gray ink, gradient, glow or drop shadow.
These UI-symbol profiles are separate from the held-equipment 9px contract.

`icons.js` records Canvas and SVG paths with the shared Pen authoring core.
`canvas.html` shows both silhouettes and exact-size 21/24/32px samples.
`capture.cjs` renders that canvas review. Export is performed after inspection
with `node export.cjs`. Exported assets are review candidates, not approved art.
