# Gold-tier chest construction

User requested a visibly larger and richer gold chest than the two basic tiers. Wood and silver keep the corrected `../chest-polish/` construction. Gold gains a continuous brass lid cap, broad lower rail, reinforced corner shoes and small side wings on the fixed cat lock. No new silhouette clutter, gradients, shine or shadow; no tab beneath the cat latch. The user rejected the turquoise diamond from `round-1.png`; it is completely removed from the final source and exports in `round-2.png`.

Main/secondary weight remains 9/3 author units. All hardware stays inside the existing horizontal ±104, lid -62 and body +88 bounds. Fine detail is omitted below48 units; lower metal construction and larger plates remain. The lid and cap move as one layer; front and lock remain fixed.

Preview compares planned shop controls 200/200/248, with actual phone-size 100/100/124 px and a64 px gold symbol. This shows the24% size difference alongside construction, while preserving the original basic geometry and reward icons.

Production is exported through `tools/ui/build_chest_paths.mjs`. Native path-data variants use `basic_full_closed/open`, `basic_small_closed/open` for wood/silver and `gold_full_closed/open`, `gold_small_closed/open` for the premium construction. Each keeps body, lid and latch separate; open variants include the mouth. `ChestArt.STYLES` supplies stable `kind` metadata for tier selection and the larger gold opening prop. The gold `gem` metadata is false after the user's correction.

All seven proposal SVGs rendered successfully with the Godot SVG renderer. Final `round-2.png`, native124 px gold and native open256 were visually inspected. `ChestArt.gd` passes Godot check-only. The five generic wood reward SVGs were regenerated from the explicit BASIC source and verified byte-identical by SHA-256 to their pre-premium versions. Final actual Shop/opening captures are maintained by the integration review under `docs/ui_review/2026-10-22/chest-integration/`.
