# Equipment UI native integration review

Integrated in production on 2026-10-23: the approved paperboard Hero layout and
item sheets in `game/menu/pages/HeroCatPage.gd`, with flat surfaces provided by
`game/ui/PaperboardFrame.gd`. The original five-carton navigation is retained.
The shared currency artwork uses the selected bright classic gold coin, wide
purple brilliant gem, and crossed-swords power icon; see
`game/ui/art_sources/currency_art.md` for canonical sources and installation.

Follow-up: the Hero tab hides the shared avatar/currency header and reclaims its
height. Its paperboard background now belongs to `Home.gd` and covers the entire
screen behind the existing carton navigation, removing both exposed green strips.
Other tabs retain their shared header and their own backgrounds.

The Hero overview now runs flush to the screen edges with internal content
padding, without the former folder tab/title or repeated worn captions on the
four cards. Detail comparisons retain their explicit above-card captions.
Combat power uses a rounded cream paper label with a flat gold sword seal;
the entire label stays centered as the formatted value changes width.

Inventory rows are left aligned, including short filtered rows. Category badges
on equipped, inventory and comparison cards use a white glyph in a cream-rimmed
square, with its inset color derived from the same `HeroCat.tone()` rarity as the
card. Glyphs are centered using cropped alpha bounds; the approved staggered
boots pair uses `game/ui/art/equipment_badge_boots.svg`. Badges protrude 2 logical
pixels above/left of each card after a total 6-pixel diagonal shift down/right. The
8-pixel scroll padding and card hit areas are retained. Empty-slot artwork is
unchanged. The category glyph shader preserves
canvas fades and leaves the shared grey source icons untouched.

Final native review: **281 checks, 18 screenshots, 0 failures**, at both window
sizes below. The currency verifier separately passed all **30 loader checks**.
`python -B tools/ui/install_currency_art.py --check` also confirms all 25 runtime
SVG overrides match the accepted sources. The review profile was not saved.

`ReviewEquipmentIntegration.tscn` mounts the actual production `Home.tscn` and opens
its Hero tab through the original five-carton navigation. It adds no visual
overrides, duplicate UI, or player-facing inventory fixtures.

Run `./run-review.ps1` after production edits and imports finish. The script uses a
hidden rendering window and isolated `APPDATA` / `LOCALAPPDATA` under
`output/equipment-ui-native-profile`. Godot must not be running another import or
review process against the project concurrently.

The review sets `PlayerData.persist = false`, snapshots the original in-memory
profile, and restores it and the original default tab when finished. It hashes the
isolated save before and after and checks there were no review save writes.

At 360×640 and 450×800 it captures the fresh profile, all 13 supported equipment
items, an empty inventory, both category filters, ascending rarity, upgrade and
comparison sheets, and the result of equipping a bow. It checks:

- Four gameplay slots; two controls on each side, including dedicated empty-slot
  glyphs. Fresh starts with three worn items and one empty slot.
- Five inventory columns, data-derived item counts, centered and contained item
  artwork, level labels and category badges.
- Category glyph/frame centering, approved boots source, rarity color matching,
  protruding badge placement and first-card scroll clearance, including detail
  and comparison sheets.
- Native mouse taps on category filters, rarity ordering, item cards, popup close,
  equip and upgrade actions. Upgrading spends the exact gold cost; equipping
  returns the previously worn weapon to the spare inventory.
- Rejected API calls for an invalid UID and insufficient gold leave inventory
  unchanged; their in-memory fixture state is restored.
- The original `CartonNav` instance survives those actions with five cells and the
  Hero tab selected.

`review.json` records each assertion and geometry measurement. Screenshot names
include their native window dimensions. This review deliberately asserts no exact
card-frame filename or theme style, allowing locally drawn paperboard frames.

UI targeting contract: `HeroInventoryGrid`, `HeroInventoryScroll`,
`EquipmentFilter_all`, `EquipmentFilter_weapon`, `EquipmentFilter_gear`,
`EquipmentSort`, and existing `_open_detail(uid)` card hit connections.
