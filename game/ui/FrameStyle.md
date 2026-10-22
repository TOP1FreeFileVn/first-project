# UI frame depth

The 2026-10-22 frame revision uses one flat contour for panels, popups, equipment
cards, avatars and feature shortcuts. Do not add an offset silhouette, a lower
backing layer, or a darker foot band to those frames. Clickable cards and
shortcuts follow the frame rule even when their input handler is a Button.

Raised action buttons keep their normal/pressed base, including the shared
`btn_*` textures, short chip buttons, close/plus controls and carton navigation.
World illustrations and character contact shadows retain their existing art.

Frame sources are `tools/ui/make_svgs.py` and `tools/ui/make_menu_panels.py`.
Keep bottom texture slices equal to top slices in `tools/ui/build_theme.gd`
and `Ui.menu_panel_style()`. Content padding is independent of frame depth.
The castle bubble and UiKit avatar/modal also use flat styles. Lobby shortcuts
use no individual frame: Home draws one fixed dark translucent strip behind
each column of icons and outlined captions (see `LobbyShortcut.md`).

Native captures and review results are in
`docs/ui_review/2026-10-22/flat-frames/`.

Hero equipment uses the approved carton A frame with natural palette 1
(2026-10-23): kraft `#DAB47A`, tape `#EAD4AA`, outline `#583F21`; rarity inserts
green `#A7CE87`, blue `#8FC6DE`, purple `#B9A0DC`, orange `#F2BA85`.
`Ui.gear_card` selects `CardEquipment*` for worn items, inventory and comparison
cards. These square frames stretch as a whole with zero texture margins so
their tape patches keep the approved proportions. Empty slots keep their
separate symbols. `CardUnit*` remains the existing shared card family.

Canonical paths: `game/ui/art_sources/equipment_frame_carton_A.svg`.
Regenerate only these four frames with
`python -I tools/ui/make_svgs.py --equipment-cards-only`, then import and run
`Godot --headless --path . --script res://tools/ui/build_theme.gd -- --equipment-cards-only`.
This installs just the four styles into the current theme. The full skin and
theme generators also retain this approved frame.
