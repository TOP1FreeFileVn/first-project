# Chest concept options — 2026-10-23

Raster concepts for the existing wood, silver and gold chests. The user selected family B; its production follow-up is in `../chest-b-production/`.

## Art brief

- Four construction families, three tiers in each: A domed treasure chest; B fortified flat-lid strongbox; C cardboard treasure parcel; D travelling coffer.
- Clean frontal 2D, chunky rounded masses, broad flat opaque colors. The gold chest gains size and structural richness, not a gem or many decorative marks.
- Main contour: warm brown `#583f21`, round caps/joins. Secondary seams are thinner and quieter, related to the material; color planes do not all receive outlines. Target approximately 16 px main / 7 px secondary on a 360 px-wide concept, checked after fitting. These are concept targets, not certified generated measurements.
- Restrained tier colors: honey wood, pale blue/silver, coral/brass. No gradient, glossy light, tiny gray edging, random scratches, cast shadow, top gem, or extra golden tab below the lock.
- Reference images establish the game's flat shapes, line hierarchy and materials. Do not copy the old chest silhouette. Raw generations and exact prompts are preserved.

## Workflow

The user chose image-generation concepts first. `canvas-vector-art` is Claude's separate vector workflow and is not used to author these concepts. The imagegen skill's standard fallback CLI was attempted with `gpt-image-2` and two references; the local router's images/edit endpoint returned HTTP 500 and produced no image. The user then explicitly authorized reusing the established **9Router Responses image-generation route** from the map artwork. `generate.ps1` uses that route with requested image model `gpt-image-2.5-sunburst`; per-family generation metadata records the returned result and transport. This is a custom authorized route, not a successful standard CLI generation.

The comparison board will label each proposal A1–D3 so the user can choose a family or mix individual chests. Integration follows selection.

## Review deliverables

- `overview.png`: all 12 proposals, with wood / silver / gold columns.
- `family-A.png` through `family-D.png`: larger views of each family.
- `small-size-proof.png`: each design in 96 and 64 pixel boxes.
- `preview.html`: local gallery with enlargement and original-sheet links.
- `png/A1.png` through `png/D3.png`: non-destructive background-removed crops, for review only.
- Exact input prompts are in `prompts/`. Untouched raw generations and per-call metadata are in `output/imagegen/chest-options-2026-10-23/` at the repository root. `generation.json` records the selected revisions.

## Visual review

A has a high domed lid and broad twin straps; B has the most compact low armored construction; C uses rigid taped carton panels; D has a tall travel-trunk profile with side handles. No proposed chest has a top gemstone or dangling gold tab beneath its lock. All silhouettes are complete in the assembled board, with no neighboring object fragments. Small-size views retain the lock and family outline.

C revision 1 read as a soft padded bag. C revision 2 replaces the rounded hanging flap and wrinkles with straight carton walls, flat top and sparse fold cues, and is selected for the board. Both raw generations remain available.

The original boards remain selection concepts, with generated tonal variation and locally varying line weights. They do not demonstrate the finished opening animation.

## Selected B and gold polish

The user selected B, then requested a more detailed, slightly shinier gold chest in the shop. `prompts/B-v2.txt` records that focused follow-up, generated through the same authorized 9Router Responses route. Its untouched result is `output/imagegen/chest-options-2026-10-23/B-v2-raw.png` at the repository root. The gold now has connected brass framing, broad corner guards, four readable fasteners and restrained cream/gold highlights. This explicit gold gloss request supersedes the initial flat-only brief for that tier; wood and silver remain flat.

Production preserves the generated silhouettes without retracing or widening their contours. `tools/ui/build_strongbox_chests.py` prepares alpha, palettes and aligned body/lid/lock textures under `game/ui/art/chests/strongbox-b/`. `game/ui/ChestArt.gd` uses these layers for both the closed shop art and the existing opening animation. `node tools/ui/build_chest_paths.mjs` rebuilds the layers and publishes the five small wood chest counters. See `docs/ui_review/2026-10-23/chest-b-integration/` for native review evidence.
