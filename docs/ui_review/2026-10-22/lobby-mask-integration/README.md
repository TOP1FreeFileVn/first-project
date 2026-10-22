# Production lobby shortcut integration

The approved lobby design is integrated into the real Home screen. The two left shortcuts share one dark translucent strip; the right event shortcut has its own group strip. Icons have no individual frame, mask or footer. Original native input and finite hover/press/release feedback remain in the production `LobbyShortcut.gd`. The reward row and battle button are lowered together by 20 design pixels; the stage header stays fixed.

## Results

**234 checks, 18 native captures, 0 failures** at 450×800 and 360×640. The review instantiates `game/menu/Home.tscn` directly, verifies the production shortcut script paths and uses no demo substitution.

- Both shared strips retain the approved `#3f493f` at 48% opacity, no outline/shadow, compact zero-gap grouping and original 108×128 hit targets.
- Native hover and held press reach focus 1.0 and press 1.0; the held icon/label scale is 0.94. The shared strip stays fixed.
- Native release opens login gifts; independent native taps open quests and events. All three popups close back to the lobby.
- The login badge changes after a real PlayerData refresh while shortcut and strip instances stay intact. A shop-tab round trip hides and restores the same columns.
- The battle header remains at design y=150. Rewards stay above the button, and the button clears navigation by at least 18 design pixels throughout the inspected pulse states.

`home_450x800.png` and `home_360x640.png` show the integrated layout. Hover, pressed, release, login, quests, events, badge-refresh and tab-roundtrip captures are also included. `manifest.json` records exact strip/shortcut bounds and interaction states. Native home captures were visually inspected at both sizes: labels and alerts fit, the strips match the approved proposal, and the lowered action group clears the bottom navigation.

## Reproduce

Run `powershell -ExecutionPolicy Bypass -File docs/ui_review/2026-10-22/lobby-mask-integration/run.ps1`. APPDATA and LOCALAPPDATA are isolated under `output/lobby-mask-integration-profile`; persistence is disabled, sound is muted and the test window is hidden. The runner checks a fresh zero-failure manifest before returning success.

The only stderr message in the final run is the existing Windows root certificate warning. An initial run concurrent with another native capture failed one held-press timing assertion; it was rerun alone after adding two frame waits and recording actual state. Strict press assertions remain unchanged and passed in the final run. The earlier manifest/log remain under ignored `output/lobby-mask-first-trial/`.
