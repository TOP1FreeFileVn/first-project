# Strongbox B integration review

Native Godot captures of the selected B chest family, including the more detailed and slightly polished gold chest. The review uses the production `DrawnIcon`, Shop, lobby reward counter and opening screen.

Run `./run.ps1 -ImportAssets` once after installing the artwork. Later reruns can use `./run.ps1`; `-GoldOnly` limits opening-screen captures to gold while still reviewing all three Shop tiers and icon routes.

The review renders with `gl_compatibility` at 360 × 640 and 450 × 800. It uses an isolated `output/chest-b-integration-profile`, sets `PlayerData.persist = false`, and mutes both the game preference and master bus. Player saves are never loaded from or written to the regular profile.

`manifest.json` records checks, painted bounds, Shop layout and captures. Boards show native icon sizes and separate lid states; full-screen captures show Shop, the live lobby counter, waiting, opening and card reveal. Earlier captures under `2026-10-22/chest-integration` remain untouched.

## Completed review

The full run completed with **223 checks, 43 captures, and 0 failures** on Godot 4.7.2 / OpenGL compatibility. The only runtime log warning concerns the system certificate store; no GDScript errors remained. Import also reports the existing Android build-tools and nested-project/Unicode warnings, outside this artwork change.

Visually inspected both Shop sizes, small icons, separated lid states, and gold wait/open/card captures. All tiers stay centered and contained. Gold is visibly larger than wood/silver, and its brass highlights and four fasteners remain readable. The flying lid contains no stray lock fragments; the lock and body remain stationary. The front-facing opening has a shallow rim rather than a visible deep interior.

Primary review images: `shop-450x800.png`, `shop-360x640.png`, `separate-lid-states.png`, and `actual-open-gold-450x800.png`. The production layers also reconstruct each closed source exactly (zero RGBA differences), recorded in `docs/design/2026-10-23/chest-b-production/closed-layer-check.json`.
