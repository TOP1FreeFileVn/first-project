# Equipment UI — paperboard review

**Production update — 2026-10-23:** the selected paperboard Hero UI is now
integrated in `game/menu/pages/HeroCatPage.gd`, preserving the original five
bottom cartons. The notes below record the earlier demo stage.

The user rejected the two previous presented directions and asked for a paperboard
version while preserving the existing bottom bar. The active preview now contains
only **Bìa giấy**. Earlier carton/workshop screenshots are superseded.

This is a review-only proposal; no production game script, asset, or theme changes.

- Single kraft folder for the four actual slots: weapon, helmet, armor, boots.
- Die-cut board cards with broad green/blue/purple/orange rarity paper inserts.
- Original game font and approved production equipment and hero artwork.
- Warm dark board inventory with five columns, compact filters and native buttons.
- Flat panels and cards, with the original raised action-button textures.
- Header and bottom bar are literal crops from the production native capture
  `../weapon-frame-options/integration/full-bag_450x800.png`; footer crop is
  `(0,690)–(450,800)`, trimming only the empty area above the cartons. They
  preserve their existing artwork and proportions. The preview adds no empty
  stage space below the bottom bar.
  The footer is a visual reference in this demo, not a reimplementation of its
  live carton animation. Its five hit targets give a preview acknowledgement.
- Clicking an item opens details; filtering, ordering, equipping a weapon, and
  upgrading run locally in the demo. Fixture values are illustrative and do not
  read or write the player's save.

`demo.template.html` is the editable source. `python -B build.py` embeds the
unchanged production art and a restrained flat paper grain into the self-contained
`equipment-ui-demos.html` fragment (under 1 MB). `preview.html` wraps the fragment
for local browser review. `review.cjs` checks interactions and responsive layout
using the installed Playwright runtime and headless Edge.
