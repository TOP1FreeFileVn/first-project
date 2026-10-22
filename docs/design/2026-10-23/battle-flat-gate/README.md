# Flat 2D battle gate

Brief: preserve the cardboard castle identity with a direct front view, a single open cat-shaped gateway, battlements, teal flags, tape and broad paw stamps. Remove both small side-tower doors, all extruded side faces, recessed floor and folded gate leaves. Warm flat fills and the established 4.6px brown contour remain; there are no new frames or decorations.

The complete 720x240 layers retain their registration. Runtime lifts the art 4 logical px using CASTLE_WALL_OFFSET184, so the base and gear tray's top line both sit at world734. Their 4.6px contours share a centerline rather than creating a doubled line. WALL_Y700, deployment664 and all gear coordinates remain unchanged. Tape stays within the central face.

Layer correction after user review: remove the horizontal split at source y164. Keep flags behind actors and draw the entire facade at z2 above actors. All opaque tower/gate pixels now hide cats, including the crown and upper wall. The aperture stays clear alpha, and units above the battlements remain visible.

Canonical source: castle.js, shared Pen paths. Export: node docs/design/2026-10-23/battle-flat-gate/export.mjs. The earlier perspective version remains archived in docs/design/2026-10-22/battle-cardboard-castle.

Ready button: independently lowered6logicalpx in game/ui/HUD.gd. The drag-to-sell target keeps its original rectangle.

The initial flat-art review passed 13 checks but preserved the incorrect upper-wall layer behavior. The full-facade correction replaces that expectation with visible-pixel checks for occlusion at the upper gate/crown and both towers, plus visibility in the clear aperture and above battlements. Native review also covers actual gear drag/drop/return, damage and unchanged gameplay coordinates. `production-preview.png` shows the latest live fight; `ready-preview.png` shows the lowered button. `gate-comparison.png` is the earlier art comparison. Current results and screenshot paths are recorded in `verification.json`.
