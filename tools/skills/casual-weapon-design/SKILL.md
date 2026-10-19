---
name: casual-weapon-design
description: Design and redraw readable weapons, wearable gear and magical equipment for casual mobile games, including cohesive icon sets and character-held props. Use for equipment art direction, silhouette redesign, small-size reviews, or production assets; not combat balancing or general UI layout.
---

# Casual weapon design

Create weapons that are recognizable at the size players see, have a playful personality, and belong to the game's characters. A redraw changes the object design, not just its stroke or palette.

## Establish the art contract

Inspect several current characters, weapons, and one real inventory or troop screen. Identify the actual display size, visual weight, camera angle, material palette, line style, and whether equipment is flat, shaded, or rendered. Carry forward the user's accepted style and requested scope. Do not assume every casual game needs glossy loot icons.

For the Godot cat-defender project containing `tools/ui/make_units.py`, read [references/cat-defender.md](references/cat-defender.md). That profile is project-specific; do not apply its palette or rendering restrictions to unrelated games.

For that project's stroke treatment, use the [accepted spear sample](references/accepted-spear.md) as the visual baseline. It records the user's 9/10 review, the selected generation prompt, actual fitted measurement and cleanup limits; the older hero-equipment prototypes are not the baseline.

Choose the pipeline from the intended art and the user's direction. For new illustrated weapon concepts, image generation can establish expressive silhouettes faster than assembling geometry in code. Do not default to SVG merely because the previous assets are SVG. Use existing vector generators for native vector edits when that is the requested deliverable. A generated mockup is a proposal, not automatically a production-ready transparent asset.

For a raster-generation workflow, inspect current character references, generate a few representative assets with one shared art brief, then review and extend the accepted direction. Preserve the original generated files and prompts. Clean backgrounds, alpha, palette and optical sizing without replacing the accepted generated silhouette with a crude geometric reconstruction. Use the available image-generation workflow; do not claim a model was used unless its run actually succeeded.

## Design the object before decorating it

- Give each weapon one defining contour: curved belly, deep beard, stepped slab, trumpet muzzle, crescent cradle, squat flask. The functional head should carry the identity.
- Casual proportions often benefit from a larger head, thicker grip, softer corners, and fewer mechanical pieces. Adapt these to the existing characters rather than imposing a fixed ratio.
- Distinguish close relatives through length, curve, balance, and guard shape. A sword, dao, katana, and greatsword should remain different when filled solid black.
- Build a visual hierarchy: recognizable main mass, readable grip or support, then one signature material or emblem. Place small wraps, rivets, and runes only where they survive downscaling.
- Retain enough craft and material cues to avoid generic pictograms. Simplifying means removing visual noise, not reducing everything to a stick plus triangle.
- Establish set identity with repeated construction choices such as a brass socket or cloth wrapping. Avoid stamping a mascot face or gem on every item.
- Rarity may add a stronger contour or richer material combination, but gameplay identity must survive without a rarity-colored frame. Do not invent progression rules.

Before drawing a set, record a short design brief: visual thesis, shared construction, and a contour cue for each item. Choose enough representatives to expose differences between families; extend the direction once they hold together.

## Compose for actual use

Draw icons with optical centering and safe room for their outline. Keep comparable perceived size without forcing a spear, book, and cannon into the same bounding-box ratio. Review thin strings, trigger spaces, and handle gaps after rasterization.

For held props, check the character too: align the grip with a paw or hand, keep eyes and mouth clear, avoid merging weapon lines with the head outline, and keep the silhouette inside the sprite bounds. Horizontal weapons and ground-supported artillery may need individual poses. Do not change the character design merely to fit an icon.

Establish the whole-character composition and hand occlusion before polishing the isolated item. Use the current character as an unchanged scale/placement template. Show a meaningful part of the grip or support and give each weapon family an appropriate pose; one reused diagonal transform is rarely enough for a sword, spear, crossbow and book.

Scale interior detail and line weight for the final held size. Enlarging an icon on a presentation sheet can hide unreadable knots in the real game.

Distinguish silhouette edges (including holes), overlaps, surface seams, ornament and filled material planes before assigning strokes. An internal line can carry the character's main weight when it performs the same primary role; a component boundary is not automatically a main line. Choose surface ink relative to the material and reference rather than using one gray for every interior. Use one line per shared edge, leave readable color boundaries unlined, and preserve broad fills and openings at the final display scale. Do not turn facets or shadow regions into thick strokes. Global outline dilation or rebuilding segmented boundaries cannot substitute for authored linework. For this cat-defender project, follow the observed examples and current decisions in [references/internal-strokes.md](references/internal-strokes.md).

Treat line weight, component proportions and negative space as one design decision. A fixed-width dilation of generated art is not a substitute for authoring broad fills and readable openings. Distinguish menu symbols from detailed held equipment even when they share a palette. Retain deliberate construction modules; remove incidental marks that do not explain the object.

## Make the redesign reviewable

When revising rejected art, write down the visual differences you intend to introduce. Change meaningful construction or contour; recoloring or adding an outline is not enough.

Deliver views that answer the user's decision:

- Clean weapon set, consistently sized and labeled.
- Previous and new art side by side at equal perceived size.
- Unenlarged thumbnails at the intended display sizes and, when relevant, the weapons held by characters in context.

Use the project's render engine for a final compatibility check when it differs from the illustration renderer. Open and inspect the rendered images. Revise observed failures before delivery; an attractive source SVG alone does not prove it works in game.

Useful rejection signals: near-identical silhouettes between roles, a dark tangle replacing the functional head, lost negative space, clipped tips, a floating grip, a face covered by equipment, or a set whose only new feature is color/stroke. Fix the object or pose responsible instead of decorating the presentation.

Keep proposals in versioned locations. If the user asked to review first, leave production weapon art intact and identify the proposed version clearly. If implementation is already authorized, integrate the approved source and regenerate only the affected assets. Preserve unrelated work.
