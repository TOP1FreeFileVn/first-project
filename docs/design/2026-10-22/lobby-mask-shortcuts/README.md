# Approved borderless lobby shortcuts

Approved design for the three existing lobby shortcuts: Quà 7 ngày, Nhiệm vụ and
Sự kiện. The original game icons sit above white Paytone captions with dark
outlines. Following the supplied reference, each side column has one continuous
dark translucent strip behind its icons, captions and the space between them.
Both columns use the same warm neutral tint (#3f493f at 48% opacity). There are
no individual color patches, cards, frames, footer bands or offset shadows.
The strip stays still while the icons respond to hover and press. Items are
stacked with no added separation; their original 108x128 hit targets remain.

Applied to production `game/ui/LobbyShortcut.gd` and `game/menu/Home.gd` after
approval. `MaskShortcut.gd` is now a compatibility alias, and the preview runner
loads the real Home directly. No demo component is substituted into the game.
The reward row and battle button also sit 20 logical pixels lower, as approved.

Open `MaskShortcutPreview.tscn` and run the scene for the interactive proposal,
or run `powershell -ExecutionPolicy Bypass -File
docs/design/2026-10-22/lobby-mask-shortcuts/run.ps1` from the repository.
Add `-Capture` to record native 450×800 and 360×640 views and exit.
The runner uses a workspace-owned profile; the demo disables persistence and
sound before applying its fixture.

`native/proposal_450x800.png` and `native/proposal_360x640.png` preserve the
approved study. `before_*` preserves the previous framed layout. The runner's
`production_*`, focus, held press and release captures verify the current game.
The manifest records native dimensions, hit targets and real pointer input.
Production integration evidence is under
`docs/ui_review/2026-10-22/lobby-mask-integration/`.
