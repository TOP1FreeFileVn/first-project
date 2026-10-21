# Cardboard cat tunnel — isolated vector pilot

Five aligned SVGs are ready for the native movement/occlusion prototype. These
are pilot art, not a change to production assets or an approved final environment.

| File | Role |
| --- | --- |
| `source.svg` | Complete tunnel; assembled from the same layer geometry |
| `shadow.svg` | Soft ground contact ellipse only |
| `rear.svg` | Narrow right paper wall; no duplicate front seam |
| `interior.svg` | Warm dark interior and floor, clipped to the doorway |
| `front.svg` | Cat-ear cardboard front with a genuinely transparent entry |

All five have width **256**, height **240**, viewBox **0 0 256 240**, and ground
registration **(128,224)**. Place their image top-left at **(-128,-224)** relative
to a shared ground root, then apply a single common scale. Do not trim layers to
their alpha bounds. The shadow extends to y=237 while the cardboard floor is y=224.

## Geometry and depth

- Doorway aperture bounds: **x70–186, y96–240**, extending below ground224.
- The front is one U-shaped contour: arch top and vertical sides, open to ground.
- There is no front bottom bar or horizontal stroke across the doorway.
- At local y210 the fully transparent run is x72.667–183.333, width110.667.
- Maximum fully transparent width at the 3x QA render is110.667 logical pixels.
- Suggested floor anchors: approach(128,236), threshold(128,212), inside(128,202),
  deep(128,188). The approach anchor intentionally lies outside the object floor.
- The integration can stop closer to the entrance at local y210; the art review
  uses that position to prove the native cat's two feet fit without narrowing it.

For the current prototype's ground root **(380,470)** and scale **1.18**, the
geometric aperture spans **(311.56,318.96)–(448.44,488.88)** in world coordinates,
continuing below the cardboard ground at world470. A cat foot root at world454
corresponds to local y210.441. No bottom bar cuts its feet or body at handoff.
The rear and clipped interior floor remain unchanged; only the front aperture
was opened to ground after native playback exposed the old sill handoff pop.

Assemble **shadow → rear → interior → front** when no actor occupies the tunnel.
While an actor occupies the doorway/inside zone, use **shadow → rear → interior
→ actor → front**. Actors outside must retain ordinary foot sorting with the
whole prop. A permanently global front overlay would incorrectly cover outside
cats.

## Style

The native `game/ui/skin/cat_tabby.svg` remains unchanged. The tunnel uses the same
warm contour **#583f21**, bright flat cardboard fills and a small number of quiet
paper marks. Main contour is **5 logical pixels**, secondary crease **2.5**, and
two tape marks2. At prop scale1.18 and cat scale0.5, their main outlines are
**5.9px** and **6px** respectively. No gradient, pseudo3D floor, embedded bitmap
or drawn cat appears in any tunnel SVG.

## Rebuild and checks

1. Run `python build_art.py` from any directory.
2. Run `render_review.gd` through the isolated Godot layout-renderer, passing this
   folder as the first user argument. It writes 3x PNGs under `png/`.
3. Run `python review_art.py` to write `qa.json` and `art-review.png`.

`art-review.png` is an art-only comparison: complete tunnel, alpha cutout, and
the untouched native cat composited between layers. It does not bake the cat
into the production SVGs. The split PNGs and complete SVG render show only minor
edge blending quantization (max5/255; mean absolute channel difference0.00076).
The front centre and ground-centre alpha are0, the cardboard face alpha is255, and all SVGs contain
zero image elements. `geometry.json` holds the paths, anchors and scale notes.
