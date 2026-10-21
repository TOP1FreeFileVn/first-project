# Castle and troop upgrade hints

This direct-upgrade iteration was superseded by the speech bubble flow in `../castle-bubble/`: opening the bubble shows the detail card, and upgrading happens inside that card.

Production Home reviewed at 360×640 and 450×800 through `tests/ui_review/LobbyCastleUpgrade.tscn`.

The fixture runs 98 checks using native viewport pointer input: direct castle upgrades, exact cost deductions, exact funds, insufficient funds with an affordable workshop, maximum level, canceled drags, persistent controls and cats, stage swipes, castle artwork opening details and workshop access, tab visibility, and large overflowing troop hints.

Fourteen PNG captures cover the funded, upgraded, unfunded, maximum, details, returning lobby and troop roster states. The pointer is parked away from interactive elements before capture. `manifest.json` records checks and states.

The fixture uses an isolated profile and sets `PlayerData.persist = false`; no player save is changed.

Run the native scene with Godot (not `--headless`, because PNGs require rendering):

```powershell
$castleReviewRoot = (Get-Location).Path
$env:APPDATA = Join-Path $castleReviewRoot 'output\castle-upgrade-qa-profile\roaming'
$env:LOCALAPPDATA = Join-Path $castleReviewRoot 'output\castle-upgrade-qa-profile\local'
& 'C:\Users\dangp\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe' --path . --windowed --max-fps 60 'res://tests/ui_review/LobbyCastleUpgrade.tscn'
```
