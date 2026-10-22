# Selected navigation icons

User choice: C knight helmet for Hero; preserve the original Battle icon and original Shop stall. Shop's paw becomes a blue fish. The latest clarification removes the gold sign board behind the fish, not the helmet's gold nasal guard.

Hero fixes: material planes meet the outer contour and draw before it; no pale inset sliver, no fill covering half the ink on the right. The gold nasal guard is shorter so it reads as part of the helmet rather than a tie. The chosen palette and helmet silhouette remain intact.

Sources: `hero.js` and `fish.js` author shared Pen paths. `export.mjs` also writes the canonical regeneration sources `game/ui/art_sources/nav_hero.svg` and `nav_shop_fish.svg`. `build_shop.py` changes only the paw and sign-board elements of the frozen `shop-original-source.svg`, producing `shop-source.svg`. Production reads the installed PNGs through the unchanged CartonNav control. The larger cyan fish uses a 43-unit broad silhouette, a 1.8-unit secondary outline and a 1.4-unit eye; no fine decoration is added.

Rebuild: run `export.mjs`, `build_shop.py`, Godot `render.gd`, then `install.py`, waiting for each step. The installer verifies that a native render of the original source matches the old shop pixel for pixel and confines every changed shop pixel to the former sign board. It refreshes only the shared Shop/Hero tab SVGs at 32/48/64/96/128px, using the same helpers as a full skin rebuild. `manifest.json` records the sources, bounding region and unchanged battle/troop/summon hashes. `shop-before.png` and `hero-before.png` preserve the preceding production images; `shop-small-fish.png` preserves the first blue-fish revision.

Refresh the changed PNG imports in Godot before inspecting the production control. `ProductionPreview.tscn` captures its default textures, without alternate icon injection or player-save writes.
