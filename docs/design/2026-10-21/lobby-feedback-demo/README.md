# Lobby feedback review

Option A cat portal was approved and copied into the production carton navigation as `game/ui/skin/carton_nav/summon.svg`. The four shortcut responses are now implemented by `game/ui/LobbyShortcut.gd` and wired to their real destinations in Home. Press feedback starts immediately; the destination opens 200ms after release, and switching tabs cancels that pending destination. This review scene preserves the earlier comparison implementation.

Isolated native Godot demo: the current lobby appears on the left and the proposed interaction on the right. Production assets and scripts are unchanged by this review. Both panels use the actual Home scene; all player changes stay in RAM and runs use a disposable profile under `output/lobby-feedback-demo-profile`.

Run `LobbyFeedbackPreview.tscn` in Godot. The comparison window is titled **Demo UI — Triệu hồi & 4 nút sảnh**.

- **A · Cổng mèo / B · Thư mời:** switch the proposed summon icon and open both cartons at the same time for comparison. Tapping a carton also selects the same carton in both panels while keeping the lobby visible.
- **Thử 4 nút:** plays each proposed shortcut's press and release response without navigating.
- Click a proposed shortcut to press its face down, see its individual response, then open its real destination after 260ms. Calendar peels a page, quests draws a check stamp, events flutters its banner, castle opens a door. Faces spring back in 180ms; effects finish in 520ms. Pointer exit and lost focus cancel the held state. Native keyboard focus is supported.
- **Về sảnh / Escape:** closes review popups and restores the lobby. A/B keys select the icon; Space plays the four responses.

The four shortcut frames, game font, lobby artwork, carton interaction and shelf are reused. This study changes feedback rather than introducing a new visual theme. Alerts remain separate from press feedback, and no periodic attention animation is added.

Validation: native D3D12 render, 13 state/destination captures, and eight real mouse routing checks through the scaled comparison view. All pointer press and destination checks pass; see `native/manifest.json`. The source viewport is 720×1280, displayed at 360×640: shortcut hit areas remain 54×64 screen pixels. `native/idle.png`, `portal-open.png`, `invitation-open.png`, `focused.png`, `pressed.png`, `feedback-0.png` through `feedback-3.png` capture the proposal. Proposal assets use runtime SVG rasterization and do not need a project-wide import.
