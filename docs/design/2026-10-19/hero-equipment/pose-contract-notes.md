# Hero equipment: reusable pose and anchor contract

Status: design proposal for the current review, not a runtime implementation. Coordinates below use the unchanged 256 × 240 cat canvas, with x rightward and y downward. Recheck placements on the actual cleaned hero base before exporting final layers.

## What exists

- `game/core/HeroCat.gd`: six slots, `weapon`, `helmet`, `armor`, `gloves`, `boots`, `amulet`.
- Current hero weapons map naturally to four families: melee (`kiem_go`, `katana_nguyet`), ranged (`cung_san`), magic (`gay_sao`), heavy (`riu_lua`). This classification is visual; it does not change gameplay or item IDs.
- `tools/ui/make_svgs.py::cat_svg("hero")` bakes a helmet/plume, cape and back-mounted sword into the cat. The old sword must be removed from a modular review base so it does not appear alongside every newly equipped weapon. Helmet removal must also restore the cat's original ears, since its current ears are part of the helmet drawing.
- `game/menu/pages/HeroCatPage.gd::_doll()` draws the static `cat_hero` texture, independently of the six equipped item values. The proposal cannot claim that equipped appearance already works in game.
- `SpriteLib.gd` currently bakes a whole `cat:<coat>:<weapon>` texture with a 64 px icon at one global position. This is not a suitable future equipment-mount contract. It also uses a different 128 × 104 canvas from `art:*`'s 128 × 120.
- `Unit.gd::_animate_cat()` rotates the entire baked cat during attack. Four new reference poses are not four attack animation clips.

## Shared base and stationary equipment

Keep the ginger coat, white muzzle/chest, eye positions, head contour and body silhouette. Warm-brown outline `#583f21`, round caps/joins, 9 px at 256 × 240; 4.5 px at native 128 × 120. Main internal component boundaries also use 9 px to match the character; secondary seams and small details are thinner. Bowstring is an explicit exception, 1.5 px at 256 × 240.

| Anchor or protected region | Coordinate / bounds | Purpose |
| --- | --- | --- |
| Canvas centre | (128, 120) | Fixed export origin, never auto-crop a worn layer |
| Floor contact | (128, 232) | Same floor in all poses |
| Head centre | (128, 92) | Head and helmet orientation remain fixed |
| Face protected box | x 86–170, y 78–127 | No weapon or equipment crossing eyes, brows, muzzle, mouth |
| Helmet fit anchor | (128, 62) | Symmetric front-facing helmet; brim must clear brows |
| Helmet fit region | x 46–210, y 12–80 | Space for ear-shaped cups; add plume only if it fits canvas |
| Armor anchor | (128, 175) | Front-facing vest/chest plate; centred on torso, not head |
| Armor core region | x 64–192, y 140–207 | Broad main plate, one central construction cue |
| Amulet anchor | (128, 159) | Small pendant below chin, above chest plate centre |
| Amulet maximum box | x 114–142, y 146–177 | Avoid replacing most of the white chest with a large medallion |
| Resting left-paw anchor | (94, 166) | Shared fixed glove/paw centre for all four poses |
| Resting right-paw anchor | (160, 166) | Matches accepted sword grip reference |
| Left boot anchor | (84, 216) | Pair exported in a single fixed front-facing icon pose |
| Right boot anchor | (172, 216) | Same baseline and visual size as left boot |
| Boot regions | left x 50–115, right x 141–206, y 201–232 | Preserve visible gap between feet |

The five isolated item designs use one permanent display pose each: helmet front view, armor front view, matched glove pair at equal angle, matched boot pair at equal angle, amulet hanging vertically. Additional variants change design/material, not these presentation angles.

For this review, all five worn item layers are literally fixed full-canvas transforms: head/torso/feet/amulet and both glove/paw sockets are identical in all four poses. The body, face and limbs do not change. The four poses vary the weapon mount direction and balance. The cape remains part of the base; remove its old slung sword and old helmet. The paired glove layer uses centres (94,166) and (160,166), and covers the weapon at the main right-paw grip. New weapons must be designed for these sockets, rather than moving the paw to suit each source image.

A fully drawn two-handed bow attack would require changing a hand and its glove, and is outside this fixed-base proposal. The bow reference is a carry/ready pose. The review labels can say “pose cầm / ra đòn”, but must not imply that four complete animations have been produced.

## Four reusable weapon-family mounts

These are four clear reference/carry keyposes with future weapon swaps, rather than four fully animated attacks. All use the same main grip (160,166), same left paw (94,166), and the same fixed body/equipment transforms. Place the source grip at the socket before choosing a prop's angle and optical size.

| Mount | Paw and support coordinates | Principal direction and allowed region | Reuse rule |
| --- | --- | --- | --- |
| M1 · melee | main grip (160,166); free paw (94,166) | Blade points upper-right, about 32° clockwise from vertical. Above y 135, keep metal outside the cheek/head silhouette. Tip may approach (238,36). Pommel stays above y 218. | Sword/dao/katana share the grip and pose. Design new grip-to-tip length and guard width around this socket; do not refit every item to a bounding box. |
| M2 · ranged | main grip (160,166); free paw (94,166) | A ready/carry bow has a near-vertical main mass on the right, with its grip returning to the common paw. A horizontal ranged variant uses an aim line at y 166, below the muzzle. Keep limb/string and muzzle gaps distinct. | New ranged variants retain the main socket. Bow is not shown fully drawn; do not invent a floating second grip or call the fixed resting paw a drawing hand. |
| M3 · magic | main grip (160,166); free paw (94,166) | Staff/wand casts upper-right; choose a diagonal around 35–40° from vertical so the crown clears the wide cat head. The head is around x 224–240, y 66–110. Keep the lower shaft above y 220. | Staff/wand share the grip and cast direction. The crown may be more upright within the prop itself, but do not relocate the hand. A tome is an accessory variant, not a fake shaft. |
| M4 · heavy | main grip (160,166); free paw (94,166) | Lower, more horizontal balance than melee: tool head to the right of the face, around x 220–248, y 118–160. The handle returns diagonally to the common grip. | Axe/hammer share the main socket and carry pose. Author handle geometry and broad head spacing for that point. Do not fake a two-handed support by moving either glove. |

Coordinates are intentional starting anchors for the review kit, not measurements of existing finished poses. Art must respect these sockets or the contract must be revised once and versioned; do not silently change sockets per individual weapon.

For a source asset, record `source_grip`, `source_support` where relevant, `source_axis`, `scale`, `rotation`, `mount_id`, and source outline-to-canvas scale. Transform the grip into the declared paw socket. Rotate around the grip, never the image centre. Native outline measurement happens after placement.

## Layer order

1. Tail and optional cape behind the body.
2. Clean base body.
3. Boots, armor, collar/amulet.
4. Fixed rear paw/glove.
5. Weapon rear section and main weapon silhouette.
6. Front paw/glove, covering the centre of the grip.
7. Unchanged head/face and helmet where the prop passes behind them.
8. Only deliberately foreground weapon parts that stay outside the protected face region.

Export front and rear weapon parts separately if a prop needs an interleaving effect, while keeping both paws fixed. Do not fake a grip by dropping an opaque paw sticker over an arbitrary part of a blade. Keep visible handle above/below the glove and preserve trigger, guard, string and support gaps.

## Review gates

- Four hero previews at identical scale and floor, five isolated fixed-pose item icons, plus native 128 × 120 hero thumbnails.
- No permanent old sword or hidden helmet ears remain on the base.
- Worn armor and charm clear the lower edge of the head; large shoulder plates must not look like a second face outline.
- Helmet/brim clear both brows and eyes; plume does not clip the top canvas edge.
- At least a small unambiguous grip segment remains visible on both sides of the front glove when the design permits.
- Bowstring retains the accepted thinner treatment and does not merge with bow limbs.
- All 9 px structural outlines are evaluated at final display size; do not give glove seams, cloth folds and amulet cord the same weight automatically.
- Keep each original source and transform metadata. Match pairs optically and mirror the entire assembled sprite for left-facing display; do not independently mirror equipment layers around unrelated local origins.

No production files were edited by this audit.

## Interior-stroke pipeline status (2026-10-20)

Follow the [current interior-stroke contract](../../../../tools/skills/casual-weapon-design/references/internal-strokes.md) before the next artwork revision: main shape-defining lines and major internal component boundaries at 9 px, matching the character; secondary seams at 4–5 px; small details at 2–3 px; unlined color boundaries where appropriate. Use one line per shared boundary and measure after fitting on the 256 x 240 canvas. Inside/outside position alone does not determine line weight.

The current `build_review.py::normalize()` only normalizes the exterior and keeps generated interior seams; it does not implement this hierarchy. Existing review PNGs still need an interior-line pass. This documentation update does not resume art generation, uploads or production integration.
