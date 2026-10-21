# Scrolling menu backgrounds — 2026-10-21

Native Godot review of the shared Shop-style scrolling paw/gear pattern, with contextual colors across non-battle menus.

- **1,058 checks; 36 screenshots; 2 isolated motion pairs; 0 failures.**
- Ran at **720×1280** and **360×640**, using Compatibility rendering.
- Save data was isolated under this folder's `profile/`; `PlayerData.persist=false` inside the fixture. Real player saves were not used.
- Evidence: [contact sheet](menu-contexts-contact.png), [machine-readable manifest](manifest.json), [Godot log](godot.log).

## Coverage

Actual native button routing covers the Shop, Hero, Troops and Summon tabs, Battle side-rail Castle/Login/Quests/Events pages, Events→Patrol and Events→Login transitions, and header Profile/Settings popups. Overlays also run over Shop, including closing back to the original Shop header and awning. Real close/back buttons restore the preceding context.

Assertions verify one persistent full-screen pattern behind the header, content and navigation; per-context palette application; mouse-ignore behavior; stable courtyard and cat identities; hidden/paused courtyard during menus; resumed courtyard when returning to Battle; and safe context lifetimes when an older queued popup exits after a newer popup has opened. A separate Battle scene probe retains `Background.gd`, adds no menu-pattern shader, and does not start a wave.

The pattern was captured alone for 0.7 seconds while the Home refresh timer was paused. Approximately **16%** of sampled pixels changed at both sizes. Both motion images contain only the background, so refreshed UI visibility cannot cause the result.

The native screenshots were visually inspected for full coverage, visible pattern motion, palette suitability, Shop awning placement, and unchanged Battle courtyard. Popup panels retain their existing opaque surfaces with the colored scrolling backdrop visible around them and behind the scrim.

## Reproduce

From the project root in PowerShell (isolated profile paths are required):

```powershell
$env:APPDATA = Join-Path (Get-Location) 'docs\ui_review\2026-10-21\menu-pattern-background\profile\Roaming'
$env:LOCALAPPDATA = Join-Path (Get-Location) 'docs\ui_review\2026-10-21\menu-pattern-background\profile\Local'
& 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe' --path . --rendering-method gl_compatibility --position 660,40 --resolution 720x1280 --log-file docs/ui_review/2026-10-21/menu-pattern-background/godot.log res://tests/ui_review/MenuPatternBackground.tscn
```

Known environment message: Windows failed to read the root certificate store. The fixture completed normally with no script or routing errors.

Admin and full-screen reward openings have separate review coverage; they are not included in the counts above.
