# Battle cardboard castle — flat 2D gate

The in-game castle uses a front-facing cardboard fort and one clear cat-shaped gateway. Both small side-tower doors, extruded side faces, recessed floor and projecting gate leaves have been removed. Battlements, teal flags, tape and paw stamps retain the cardboard identity. There is no ramp or projecting platform. Canonical shared Pen source and review: `docs/design/2026-10-23/battle-flat-gate/`.

The two outer wing centerlines sit at x2.3 and717.7 (half of the 4.6 px main stroke inside the 720 px canvas). Their full vertical outlines remain visible at both screen edges rather than being clipped offscreen.

Both SVGs retain identical 720 × 240 registration. Runtime draws `rear.svg` flags behind units and the complete `facade.svg` through `CastleForeground` at z2, in front of units. The opaque cardboard covers cats at the gate crown, jambs and both towers. The cat-shaped doorway and space above the silhouette remain transparent. There is no horizontal layer cut. `composite.svg` is the static art reference only.

Cats whose bodies cross the opaque facade are occluded until they move beyond its silhouette; they no longer draw over the gate. Deployment and rally points are unchanged. Validate visibility using rendered pixels at the upper gate, both towers, the open doorway and above the battlements rather than z-index values alone.

Place at `(0, Battle.WALL_Y - 184)`. The cat doorway has straight jambs at local x313 and407, crown y148, ear tips y140, and an open bottom at y218. The whole aperture contains clear alpha. The facade baseline and gear tray's top centerline both sit at world y734; their existing 4.6px contours share one line. All contour ends remain at or above local y220.3, before the interactive gear grid begins at world y760.

Keep collision, deployment, unit limits and gear coordinates unchanged. The foreground facade fixes drawing depth; it does not create a new walking route or castle tier.

Regenerate only these assets with `node docs/design/2026-10-23/battle-flat-gate/export.mjs`. The earlier perspective source remains archived under `docs/design/2026-10-22/battle-cardboard-castle/`.
