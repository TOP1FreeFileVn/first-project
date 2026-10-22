# Production UI integration

The game now uses five-column troop collection cards, upper-right upgrade cues,
lower-right equipped markers, white captions with black outlines, and a standing
five-cat formation with numeric levels beneath the cats. Individual formation
cards and ground circles are removed. Team taps open the dedicated upgrade
screen; swap and drag interactions are preserved.

The layered chest is installed in the shop, opening animation, and reward icons.
The later construction polish adds broad inset panels, folded metal corners and
subordinate fasteners while retaining the flat palette and main/secondary stroke
hierarchy. The user's final correction removes the gold tab beneath the cat
latch. The latch and body remain fixed as the lid moves. Closed seam light runs
around the latch instead of painting over it.

The premium gold chest has its own reinforced construction, rather than only a
different palette. Its shop stage is 248 design pixels wide versus 200 for wood
and silver; its opening prop is 300 wide versus 250. The smaller tiers retain
their existing construction. Reward symbols use the basic wood design.

Production sources are `game/menu/pages/TroopsPage.gd`, `game/ui/ChestArt.gd`,
`game/ui/ChestOpening.gd`, and the accepted-art texture routing in `game/ui/Ui.gd`.
Rebuild chest geometry and reward SVGs with `node tools/ui/build_chest_paths.mjs`;
the shared canvas sources are in `docs/design/2026-10-22/chest-polish/` and
`docs/design/2026-10-22/chest-premium/`. The gold lid has no gemstone, following
the user's final correction.

Native review artifacts:

- [Five-column collection](troops-five-column/README.md): 1,194 checks, no failures.
- [Standing formation](troops-standing-formation/README.md): 360 checks, no failures.
- [Dedicated upgrade screen](troop-upgrade-screen/README.md): 230 checks, no failures.
- [Final captions and compact stars](troop-caption-stars/README.md): actual
  360/450-pixel captures and 1,010 layout/content checks, no failures.
- [Chest integration](chest-integration/README.md): tier, small-symbol, shop,
  reward routing and opening-animation verification at 360×640 and 450×800.
- [Four-slot hero equipment](hero-four-slots/README.md): gloves and amulets
  removed from active equipment; two slots per side, safe legacy-save migration,
  and native equipment/detail review at 360×640 and 450×800.
- [Centered equipment icons](hero-four-slots/centered-icons/README.md): weapons
  centered in equipment and comparison cards; boots keep their upright pose.
- [Flat UI frames](flat-frames/README.md): panels, cards, feature shortcuts and
  popups have no lower shadow; action buttons retain their raised base.

Review fixtures use in-memory player changes and workspace-owned disposable
profiles. The live player's save and progression are not part of these changes.
