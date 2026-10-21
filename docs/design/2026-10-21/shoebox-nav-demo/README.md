# Two-flap carton navigation review

Isolated interactive review, not connected to production menu logic or player saves.

- `shoebox-nav.html`: self-contained inline review. The lower bar is interactive; the pages behind it are original game captures for context.
- `art-v3/`: shared carton front/interior and mirrored flap geometry. The two side flaps meet in the middle when shut, then unfold left and right. There is no rear hinged lid or thumb notch.
- Carton fronts occupy 94% of their slots; the visible gap is about 7px at a 360px screen width. Open flaps are broad with a small outward overhang that stays inside the screen. Their plane area is roughly twice the previous low-flap revision, with the top at y36 on the 100px artwork.
- `art-v3/nav-shelf.svg`: one muted teal backdrop for all five boxes, with a narrow kraft paper edge. It is shared between native and inline reviews, at screen y570–640, with transparent space above the panel's top at y580.
- `art-v2/`: previous shoebox artwork, retained for reference.
- `NavMotionPreview.tscn`: native Godot review; open this scene and press F6. Click a tab or press 1–5.
- `native-*.png`: native previews and transition captures.
- `native-qa.json`: native interaction/bounds verification.
- `interaction-qa.json`: event/state simulation of the inline version, including rapid selection, drag cancellation, keyboard operation, reduced motion and saved selection.

The shoebox lid was rejected. The larger two-flap carton revision and shared teal background were approved on 2026-10-21, including the opening/closing animation. Production now uses `game/ui/CartonNav.gd` through `Ui.bottom_nav` and keeps one bar instance in Home. Runtime artwork is copied into `game/ui/skin/carton_nav/`; this review scene remains isolated from game state.

Motion: press compresses the box; selection opens both side flaps before the icon emerges; leaving lowers the icon before closing the flaps. Current transitions can be retargeted, and selecting the current tab does not replay the opening.

`embed_assets.py` embeds original Paytone One, original menu icons and review page captures. It also removes a residual old navigation contour from the shop preview background. Review resources stay below 1 MB and require no remote assets.
