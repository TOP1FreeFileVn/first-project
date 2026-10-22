# Flat UI frames, raised action buttons

The frame change removes the displaced bottom shadow from UI panels, cards, the lobby shortcut tiles and castle speech bubble. Raised action buttons retain their existing lower edge and press state. Ground shadows and depth inside character, chest and scenery art are outside this UI-frame change.

Production rules are documented in [`game/ui/FrameStyle.md`](../../../../game/ui/FrameStyle.md).

## Native review

**240 checks, 24 native captures, 0 failures** at 450×800 and 360×640. Actual Home screens cover the lobby, hero, shop, shop rates, troops, summon, login gifts, quests, events, patrol, settings and profile. Native taps exercise all five navigation tabs, shortcut feedback and destinations, event-to-patrol routing and back, popup close, and the settings checkbox. Visible frame styles and global bounds are recorded in `manifest.json`; runtime flat frames have no active shadow and equal top/bottom border widths.

The hero, shop, events, login, quests, settings and patrol captures were visually inspected. Frames read with one even contour; action buttons keep a visibly raised lower edge. No broken navigation, clipped modal shell or missing action was observed. The only stderr message is the existing Windows root certificate warning.

Run `powershell -ExecutionPolicy Bypass -File docs/ui_review/2026-10-22/flat-frames/run.ps1`. The runner isolates APPDATA and LOCALAPPDATA under `output/flat-frames-profile`. The scene disables persistence and sound; the runner verifies a fresh zero-failure manifest before returning success.

## Art preservation

`button-art-before.json` records all 18 production `btn_*.svg` files before the frame change; all 18 remain byte-for-byte unchanged. Runtime theme checks also retain distinct normal and pressed art for the blue, green, yellow, red and default action buttons.

The separate asset audit changed 39 frame SVGs while preserving canvas/viewBox dimensions; 474 other SVGs were unchanged. Root integrated matching nine-slice margins and removed the extra runtime shadows. The canonical asset comparison is under `output/flat-panel-frames/`.

The first trial searched for the patrol action's ready-state caption despite using a one-hour fixture below the alert threshold. That test selector was corrected to follow the actual ready state; final evidence in this folder is the passing run. The failed trial manifest and log are preserved under ignored `output/flat-frame-first-trial/`.
