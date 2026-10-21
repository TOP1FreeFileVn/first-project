# Castle upgrade review bubble

Production Home reviewed at 360×640 and 450×800 through `tests/ui_review/LobbyCastleUpgrade.tscn`.

Latest native run: **120 checks, 16 captures, 0 failures**, exit code 0.

The speech bubble opens CastlePage for reviewing stats and workshop upgrades. Opening it never spends gold; only the upgrade button inside CastlePage can upgrade the castle. The bubble remains available without enough gold and at the maximum level, with a quiet arrow.

The fixture uses native viewport pointer input to check that review flow, exact spending, insufficient funds, maximum level, canceled presses, actor and control persistence, horizontal swipes, vertical drags, castle artwork access, tab visibility and overflowing troop upgrade hints. PNGs cover funded, unfunded, maximum, review, upgraded, returning lobby and troop roster states; `manifest.json` records checks and state.

`PlayerData.persist = false` and an isolated profile keep player saves unchanged. Run the native scene with Godot, without `--headless`, to regenerate rendered captures.

```powershell
$castleReviewRoot = (Get-Location).Path
$env:APPDATA = Join-Path $castleReviewRoot 'output\castle-upgrade-qa-profile\roaming'
$env:LOCALAPPDATA = Join-Path $castleReviewRoot 'output\castle-upgrade-qa-profile\local'
& 'C:\Users\dangp\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe' --path . --windowed --max-fps 60 'res://tests/ui_review/LobbyCastleUpgrade.tscn'
```
