# Shop clarity / gradient demo — 24 October 2026

The user selected **C — teal/cream**, which is now integrated into the production ShopPage with its quieter scrolling backdrop. Prices, rewards, chest artwork, button skins and the carton bottom bar remain unchanged. This separate Godot scene retains the A/B/C palette proposals for review.

Run `./run.ps1` for the visible interactive preview, or open `ShopDemo.tscn` in Godot and run that scene. The runner isolates APPDATA/LOCALAPPDATA under `output/shop-clarity-demo-profile`; `PlayerData.persist=false` and a reset demo account prevent changes to the regular save.

Controls:

- **G** cycles flat paper, honey/cream and teal/cream. Default is honey.
- **F1** now displays the selected production teal/cream Shop; **F2** returns to the proposal.
- **R** resets the demo account (1,800 gold / 240 gems / 7 gold opens remaining until the periodic guarantee).
- **P** previews missing funds.
- The original bottom bar, rates popup, currency exchange and opening animation work. Purchases consume only the temporary demo account's in-game currency.

The proposal groups Gold's rewards, guarantee and action in one warm paper card. Supplies use compact matching cards and quieter White-tone original buttons. Dark blue/teal patterns keep their existing scroll speed with reduced motif contrast. Panel gradients use only related broad colors, without panel drop shadows. Button shadows remain. Main card art stays unchanged.

`comparison.png` and the original files in `captures/` are historical native A/B/C review captures from before C was integrated; their “current Shop” images show the previous production layout. The selected production result and its fresh verification are in `docs/ui_review/2026-10-24/shop-teal/`. Regenerate this proposal with `./run.ps1 -Capture -ImportAssets`, then `python build_comparison.py`; new F1/current captures will show the selected production Shop. Later capture runs do not need `-ImportAssets` unless new art was added.

Native verification checks horizontal containment and real pointer activation of the rates and Gold-open buttons. It checks the unchanged 120 gem deduction once and disabled actions without funds. This is a functional/layout review, not a user study or conversion experiment. The existing rates popup displays base roll weights and the current guarantee note; a full guarantee-adjusted probability audit is outside this color preview.

## Why gradients are reasonable here

More color can make the reward area more expressive while the information hierarchy stays readable. This is a visual hypothesis, not evidence that gradients increase purchases.

- W3C G18 explicitly covers varying backgrounds: evaluate contrast immediately behind each letter, not the average color of a gradient. https://www.w3.org/WAI/WCAG22/Techniques/general/G18
- Apple HIG Color allows custom colors to express personality, asks for consistent meanings and testing with nearby artwork/lighting. https://developer.apple.com/design/human-interface-guidelines/color (public markdown source also read at https://developer.apple.com/tutorials/data/design/human-interface-guidelines/color.md)
- NN/g explains hierarchy through contextual value/saturation contrast, size and grouping. https://www.nngroup.com/articles/visual-hierarchy-ux-definition/

These sources were inspected on 24 October 2026. For this demo, hue variation stays on panels/background; clear text and the original purchase-button semantics remain. Full research context: `docs/ux-research/2026-10-24/shop/README.md`.

## Verification result

Previous demo capture run, before production integration: **66 checks passed, no failed checks**, with 12 screenshots across 360×640 and 450×800. Inspected native palette comparison, rates popup and insufficient-funds state. Rates and Gold-open activation used viewport pointer down/up events; spending deducted 120 gems once. This is mouse hit testing in Godot, not device touch testing. Logs retain the machine certificate-store warning and shutdown ObjectDB/resource warnings; these did not prevent captures or the live preview. A final smoke run of the preserved demo after integration exited successfully with no parse errors and the same certificate/cleanup warnings.
