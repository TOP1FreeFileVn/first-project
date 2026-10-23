# Selected C shop — native integration review

This fixture instantiates the serialized production `Home.tscn` and the normal
`ShopPage.gd`. It does not inject the design demo or override production styling.

Run from the project root with Godot 4.7.2 installed at the existing desktop path:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File docs/ui_review/2026-10-24/shop-teal/run.ps1 -ImportAssets
```

The runner uses a hidden native compatibility-renderer window for capture, mutes
audio, and isolates APPDATA/LOCALAPPDATA under ignored `output/`. The fixture sets
`PlayerData.persist = false` before resetting its review account. Import and
capture processes have bounded timeouts; no real player save is changed.

Checks cover the selected shop at 360×640 and 450×800, horizontal containment,
existing bottom navigation, account/header updates, disabled purchases and exact
deficit copy, the live wood cooldown, next-opening pity, reachable exchange,
pattern strength restoration between Shop and Troops, a rates-sheet pointer tap,
and a fresh-home pointer purchase charging exactly 120 gems and showing the real
gold opening animation. Prices and loot are read from production Economy.

`manifest.json` contains the observed checks, failures, node rectangles, profile,
and captures. `shop-360x640.png` and `shop-450x800.png` are the production shop
screens; the other PNGs show account states, exchange, rates, and actual opening.
No manifest or screenshot is evidence of a passing run until its current logs
and failure list have been inspected.

## Verification result — 24 October 2026

The production native run passed **102 checks with no failures** and produced
**7 screenshots** across 360×640 and 450×800. The manifest, logs and captured
layouts were inspected. Pointer activation of the rates sheet and a real Gold
purchase worked; the purchase charged 120 gems once. Cooldown, next-opening pity,
scrolling to exchange, and the original bottom navigation remained functional.

The run retained the machine certificate-store warning and shutdown
ObjectDB/resource cleanup warnings. There were no parse errors or runtime errors
during the tested interactions. These checks verify the implementation and
layout; they do not establish a purchase-conversion improvement.
