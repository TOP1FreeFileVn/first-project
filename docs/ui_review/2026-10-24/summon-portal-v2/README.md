# Summon portal refinement — 2026-10-24

Status: discarded at the user's request. Production has been restored to the
previous portal (`portal-before.gd.txt`) and its original banner position.
The files here are historical proposal evidence.

The solid oval platform is now an open seal assembled from eight floating sectors.
Broad lilac faces, short darker sidewalls and rounded corners give each piece a
clear construction. Open gaps and the transparent centre keep the design light.
Four mint crystals are seated in alternating sectors; a larger cream paw floats
inside the aperture.

Cream inlays follow the casing, mint lights run along the recessed channel, and
the broken outer orbit moves in the opposite direction. Charging increases the
light and levitation. The release lifts the sectors in a short staggered wave,
then lets them settle. The banner uses the same artwork at a quieter intensity.

There are no new raster assets or shaders. `game/ui/SummonPortal.gd` retains its
existing energy/opacity/accent/pulse interface and bounds particle lifetimes.
`portal-before.gd.txt` preserves the previous drawing for comparison. The summon
flow, cards, rewards and costs are unchanged.

## Review

Run `powershell -NoProfile -ExecutionPolicy Bypass -File
docs/ui_review/2026-10-24/summon-portal-v2/run.ps1 -Record` from the project root,
then `python docs/ui_review/2026-10-24/summon-portal-v2/build_preview.py`.

The native fixture uses an isolated workspace profile and supplied results with
`PlayerData.persist = false`. It covers x1/x10, fast taps, skipping at each stage,
stable card placement, unique result controls, player-data preservation and menu
restoration at 450×800 and 360×640. Four additional unobstructed portal images
show idle, half charge, full charge and release. Manifests record the checks,
capture names and exact recording lengths.

The first v2 capture revealed sharp sector corners and a tangent between the
outer orbit and the horizontal split. Rounded path corners and a lifted orbit
resolve those, while the banner's seal is raised 10 design pixels to expose its
front edge. The v1 captures and animation remain in the sibling `summon-vfx/`
directory.
