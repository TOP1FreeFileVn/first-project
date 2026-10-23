# Gold currency icon proposals

The user selected **Kim cương bè** from the diamond proposals and requested
several gold icon demos. Keep that diamond fixed beside all three gold designs.

Visual brief: a broad, readable currency symbol with flat golden fills and the
same warm brown contour as the selected diamond. After seeing the first Canvas
round, the user asked for a **gear identity**. Compare a round coin stamped with
a gear, a coin with an eight-tooth silhouette and two overlapping coins with a
gear stamp on the front. No grip or character pose.

Palette: outline `#583F21`, gold `#F5C65D`, inset/top plane `#FFE3A0`,
rear coin `#D79A3E`, stamped gear `#B47A2C`. Main contour is 5.8 units on a 96px source, or 1.45px
at 24px and 1.93px at 32px. Inset faces and ingot planes are fills, not ink.
The broad embossed gear is a filled mark, not a second heavy outline.
These small symbols need no secondary strokes. No glossy spots, gradient,
offset shadow, tiny engraving or hairline gray detail. The toothed variant uses
eight broad teeth rather than a finely serrated edge.

Author Canvas first with the shared Pen core, inspect, export the identical paths
to SVG, and verify native 24/32px rasterizations in Godot. The context demo uses
the approved paperboard screen, original five-carton footer and selected sword
power plaque. The screenshot header is cleaned under the replaced icon
footprints before live icons are placed. This is a review-only composition;
production icons, game code, economy and player saves are unchanged.

## Review result

- `canvas-review.png`: gear stamp and hub remain separated at 24px; no additional
  engraving or outline is needed. The initial plain coin/ingot round was replaced
  after the user's request for a gear identity.
- `RenderGold.gd`: all three SVG variants rasterized successfully at 24/32px.
  Native outputs match the Canvas construction.
- `review.json`: all three context variants load without script errors, broken
  visible images or horizontal overflow. Each retains the selected brilliant
  diamond, four equipment slots and the five original bottom cartons.
- Recommended: **Xu dập bánh răng**. The circular rim preserves its currency
  meaning; the toothed alternative is more likely to be read as gear material.
  The paired version works better for a money reward than a persistent HUD.
