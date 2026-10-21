# Approved art rollout into the game

Integrated on 2026-10-20–21 into the production `Home.tscn`, rather than an isolated preview.

## What is live

- Battle tab: the approved V4 cardboard castle courtyard, with the approved SVG tunnel and bed replacing their baked background versions. Stage title is live text above the castle; symmetric previous/next arrows, swipe, rewards, locked stages and battle CTA remain functional.
- Three original front-facing cats: cream uses the tunnel, calico uses the bed, tabby walks along the central path. Each prop has one assigned resident. Outside actors sort by their feet; inside actors sit between the interior and front shell. No rear pose, face flipping, shrinking or fading.
- Home keeps one lobby world across page/resource refreshes. Other tabs and full-page overlays hide and pause it; returning resumes the same actors and clock. The original sky remains behind the HUD when an overlay is open.
- Castle upgrade page uses the same approved cardboard castle illustration.
- Hero equipment: final corrected weapon poses and icons; helmet, armor, gloves, boots and amulet remain stat-only equipment. The existing fifth katana item is also covered.
- Sixteen soldier weapon looks and icons, including the accepted spear and final bow/dao/katana corrections. The separate battle general identity is preserved.
- Existing shop awning, scrolling patterned shop background, UI sounds and earlier accepted UI remain in use.

Production art and provenance: [lobby assets](../../../game/assets/lobby/cardboard/README.md), [equipment assets](../../../game/ui/art/README.md).

## Validation

- `CardboardLobbyIntegration`: 85 checks, seven native screenshots, zero failures. Real mouse routes at 720×1280, 450×800 and 360×640; refresh continuity, castle-level synchronization, tab/overlay pause, previous/next, locked CTA, hero equipment preview.
- `CardboardInteractionReview`: 561 samples across a full 28-second cycle, four layer handoffs, zero failures. Stable actor scale/identity/front pose, exclusive prop occupancy, complete textures and continuous positions; native contact sheets cover entry, rest and exit. The yarn has its own foreground depth root, and the calico's lane clears the bed rim.
- `EquipmentArtTest`: 103 checks, zero failures; runtime routing and stat-only appearance contract. Source hashes match the accepted assets.
- `UiTapRoutingTest`, `PopupCloseTest`, `DeploymentTest`: pass, including real soldier deployment and castle damage.
- [Production captures and integration manifest](../2026-10-20/approved-integration/manifest.json).
- [Equipment runtime report](../../design/2026-10-20/equipment-production-check/runtime.json).

All test runs use isolated profiles inside the workspace; production save files are not test fixtures.

## Current art limits

The castle has one approved V4 illustration. Castle upgrades still change their existing game stats, but new tier illustrations and a layered castle doorway are not included. Terrain, clouds, scratching post, yarn and pillow still use the approved bitmap scene. Tunnel, bed and cat parts use SVG. Foot motion is the simple approved pilot animation, without a Spine runtime.
