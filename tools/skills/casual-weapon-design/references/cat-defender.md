# Cat-defender art profile

Apply in the Godot repository with `project.godot`, `tools/ui/make_svgs.py`, and `tools/ui/make_units.py`.

## Established art and user preferences

The game uses plump cartoon cats, rounded outlines, and flat color. Weapons and equipment belong to the cat art layer, not the glossy currency/UI icon layer. Preserve flat opaque fills: no gradients, glow, glossy shine, cast shadows, or simulated 3D shading. Separate broad flat material regions are useful; do not turn them into lighting effects. Do not alter faces, coats, outfits, rarity, or roster while redesigning weapons.

The shared main outline is warm brown `#583f21`, with round joins and caps. Surface ink is chosen relative to the material and reference: softer gray on steel, muted red-brown on leather, ochre/brown on gold are observed examples. The user rejected the subsequent uniform-gray interior treatment; do not apply `#62656B` to every internal boundary. Gray material planes are not automatically lines. This reference study does not authorize shading, gradients or realistic/3D rendering on the flat cats. Steel, honey brass, warm wood, coral cloth, turquoise and purple accents fit the set. Sample current fill colors rather than treating these examples as mandatory swatches. Give open interiors enough fill area to remain readable beside the cats' heavy line.

Match stroke at the final held size, not at the common source-image size. The user's accepted redesign uses a 9 px main outline on the 256 x 240 unit canvas for both cats and weapons. Legacy production generators still contain 12 px cat outlines, 13 px paws and 10 px weapon treatment; these are compatibility facts, not targets for new proposals. Do not globally regenerate production to reconcile them. Author proportions, spacing and line hierarchy together; do not accept a brown halo that swallows a grip, trigger opening or staff bead. Check icon and held-art treatments separately.

For weapons and active hero gear (helmet, armor, boots), read [internal-strokes.md](internal-strokes.md) before prompting, drawing or cleanup. It is the authoritative main/secondary contract for all authoring routes. Keep the accepted 9 px held-art main target and calibrate standalone icons separately; do not automatically assign main weight to every internal component boundary. Distinguish silhouette (including holes), overlap, seam/ornament and filled material plane, then choose weight and ink in context. The earlier fixed secondary-width ladder and all-gray recipe were rejected interpretations. A 9 px outer-contour pass does not certify interior strokes.

The subsequent spear sample was rated **9/10** by the user on 2026-10-20. Read [accepted-spear.md](accepted-spear.md) and view its included review image before extending that direction: broad unlined steel planes, quiet material-colored seams, authored open fill areas, and the unchanged cat in context. The fitted straight-shaft measurement is approximately 8.2 px, not a certification of exact 9 px contours everywhere. Earlier `hero-equipment` and `hero-equipment-v2` remain unapproved. The accepted spear was subsequently installed; `game/ui/art/equipment-sources.json` records its source.

The user's subsequent explicit detail reference is Figma page `3470:2`, **Asset bổ sung · Kho PNG**, in file `wMtwWaYIiKUchUdq5YdTm5`. Read [figma-weapon-study.md](figma-weapon-study.md) before the next redesign. It distinguishes detailed weapon sprites from menu symbols and records the specific reference nodes. Preserve functional construction details at readable scale; removing all detail is as wrong as retaining realistic grain and micro screws.

The user then added the main library on page `3443:2`, **Asset chính · Kho PNG**, specifically for characters holding weapons. Read [held-character-study.md](held-character-study.md): it supplies direct sword/axe/spear/staff/crossbow/book references and establishes grip, occlusion, pose, scale and broad material planes. Compose the weapon on the unchanged cat before polishing the isolated icon. Do not apply sticker white borders or badge frames to held sprites, and do not assume every visual tier requires a new weapon silhouette.

Read `.claude/skills/cat-sprite-art/SKILL.md` if character construction must change. Existing production art is authoritative for compatibility; old documentation may describe layouts the user has since replaced.

The user has rejected changes that only add stroke. For a new direction, give weapons visibly different mass, head geometry, grip proportions, and material construction. Keep their functional identity immediately clear. A giant equipment head must still leave the cat's face visible.

The user previously chose GPT Image 2.5 for generated weapon concepts. That route applies when raster concepts are requested; preserve raw generations and processed transparent versions separately, without replacing the generated design with crude paths. On 2026-10-21 the user also adopted [Canvas-first](canvas-first.md) for authored vectors. Select the route from the current task; both follow the same main/secondary contract. Use current cats and the accepted stroke references, choose representatives for the requested scope, and preserve approved families. Generated shading may be flattened to the cat palette while preserving construction.

When using Figma generation, the available confirmed model identifier is `gpt-image-2.5-sunburst`. A file can allow editing while refusing AI generation. If the requested destination refuses AI, a user-authorized draft file may generate the images, which can then be uploaded to the requested page. State that route accurately; do not imply the destination itself generated the image. Honor current tool capabilities and spending requirements rather than assuming this route always works.

## Current hero equipment display contract

The 2026-10-20 correction replaced the proposal in which all five gear items were worn and every weapon shared the right paw. Preserve the original ginger cat's face, body, coat and blue cape. **Only the held weapon changes the hero's visible appearance.** As of 2026-10-22 the active slots are weapon, helmet, armor and boots. Helmet, armor and boots are **stat-only equipment with standalone icons**; do not composite them onto the hero preview. Gloves and amulets remain historical assets removed from active slots. All active icon designs follow the same main/secondary contract.

For the current standalone redesign, read [equipment-icon-baseline.md](equipment-icon-baseline.md) and open its review image. Helmet, armor and boots stay upright; boots are shown **as a pair**, not a single rotated shoe. The current silver set uses a separately fitted 11.35/7.41 px profile at 256 px, with broad unlined material planes. The armor's 6/10 score and subsequent helmet/boots feedback establish a working direction, not blanket production approval.

On the fixed 256 × 240 hero canvas, the bow uses the **image-left paw socket (94, 166)**. Sword, staff and axe use the **image-right paw socket (160, 166)**. Keep the body and both original paws fixed; align the actual grip centre to the correct socket and rotate the weapon around that grip. Mirror or refit the bow layer without mirroring the cat or cape. A carrying pose is not a drawn bow attack or a completed animation. Keep the face clear and check exposed grip, string clearance and source bounds at native 128 × 120 size.

The bowstring must use a **visible secondary stroke**. The current v4 refinement uses 3 px on the 256 × 240 canvas against the 9 px main contour, in secondary brown (`#8a6240` before the requested single 10% paint brightening). The former 1.4 px string became nearly invisible when reduced. Keep it continuous between the tips, behind the sockets, and inspect it at 128 × 120; do not remove it or replace it with a filled sliver. This item-specific decision does not set all surface seams to 3 px.

The original `hero-paws.svg` layer contains two open C-shaped strokes, not filled hands. Compositing these strokes over a weapon does not hide the shaft within the palm. Use a small rounded palm mask inside the relevant C, then composite the unchanged paw contour above it. Restoring chest-white base pixels made the held palm look like a white glove; the current v4 refinement uses a local ginger-fur fill sampled from the original coat instead, without a cuff or added glove outline. Keep this local to the palm and leave readable grip segments immediately above and below. For the bow, fit the occlusion to the left socket rather than reusing the right-hand mask unchanged.

The straight crystal staff must keep the crystal base, brass socket and wooden shaft on one shared axis. The user explicitly rejected an upright crystal independently counter-rotated on a diagonal shaft: the join attached to the crystal's side. Rotate those connected components together around the real grip centre, then check both the connector close-up and the full held pose. A mathematically aligned hand alone does not certify the head-to-shaft connection.

The selected v4 composition was subsequently installed, as recorded in `game/ui/art/equipment-sources.json`. On 2026-10-22 the user requested reworking equipment other than the accepted sword for inconsistent strokes. Production presence does not certify the set's line hierarchy. The accepted spear remains a stroke reference; its 9/10 review does not approve every later equipment design or override this display contract.

The 2026-10-22 icon correction uses the bow's **directed firing axis**, from the string at grip height to the grip/curved body. The user explicitly chose **up-left** for the bow icon, -135° in screen coordinates; this clarification was about the bow, not the axe. The string is perpendicular to aim, so rotating the string itself to -45° caused the prior downward-facing icon. Keep inventory orientation separate from the left-paw held pose. See `docs/design/2026-10-22/bow-icon-orientation/` for before/after evidence and the installer regression.

## Current roster

| Family | IDs | Contour considerations |
| --- | --- | --- |
| Infantry | `kiem`, `riu`, `dao`, `katana` | Broad straight blade; bearded axe; belly-heavy curved blade; long swept blade |
| Ranged | `cung`, `no`, `sung`, `dai_bac` | Bow arc; crossbow T; flared firearm; short barrel and wheel carriage |
| Magic | `gay_phep`, `thuoc`, `sach_phep`, `dua_phep` | Staff cradle; liquid flask; thick tome; star wand |
| Heavy | `giao`, `cu_kiem`, `chuy`, `bua` | Leaf spear; massive slab; flanged head; broad hammer block |

These contour descriptions are starting points, not locked designs. Preserve the ID-to-function mapping and current rarity data.

## Asset pipeline

- `tools/ui/make_svgs.py::make_weapons()` defines standalone equipment; `Icon.flat_svg(size)` renders flat SVGs. Use equal light/dull colors for parts whose fill must remain exact. Optional `raw` elements marked as gloss are discarded by the flat renderer.
- `tools/ui/make_units.py` embeds the weapon in `unit_<id>.svg`. Replacing `icon_w_<id>.svg` alone does not change troops.
- `game/ui/skin/icon_w_<id>*.svg` and `unit_<id>.svg` are generated production assets. Inspect `game/ui/skin_overrides` before integrating changes so existing overrides are respected.
- Troops use `art:<id>` through `SpriteLib`. The unit canvas is 256 x 240, usually baked to 128 x 120 and displayed smaller in four-column cards. Review both icons and held units; use a per-item placement where needed.
- `make_units.weapon()` is also used outside ordinary troops. Review callers before changing production placement or line weight globally.

Approval proposals can reuse the isolated fixture pattern under `docs/design/2026-10-19/weapon-redesign/v1/`: local generators, `build_assets.py`, native `WeaponReview` scene, and comparison boards. Build new versions alongside earlier ones. Preview texture substitutions must remain in the disposable scene's memory, with `PlayerData.persist = false` and an isolated profile.

The project runner is `node tools/review/mcp_ui_review.mjs <plan.json>`. Find the Godot executable from existing review plans or local config. Inspect its output and native screenshots; do not claim MCP verification when only Python rendering ran.
