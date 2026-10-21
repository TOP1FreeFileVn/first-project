# Hero equipment icon integration review

Final `EquipmentIconLayout.tscn` run: **628 checks, 10 native screenshots, 0 failures**, process exit 0. The run followed the completed import of the final semantic-axis equipment icons.

The fixture instantiates the production Home scene, opens the actual Hero tab with native mouse input, and supplies all 17 existing item definitions: six equipped slots and 11 spare items. It runs at **720×1280** and **360×640**. No ring slot is added.

The review measures the actual texture alpha bounds after TextureRect aspect fitting against the full card rectangle. Across 108 card instances in the Hero screen, equipped detail, comparison detail, and refreshed screens, every visible icon remains inside its card and below the top caption row. The smallest alpha-to-card-edge margin is **7.67 logical pixels** (approximately 3.84 native pixels at 360 px). All 10 icon families are present; source variants are normalized when counting families.

Native mouse clicks verify Hero navigation, equipped-item detail, exact-cost upgrade, detail closing, spare-item comparison, and equip. The previous weapon returns to the bag. Upgrading preserves the same held-hero texture; equipping the Katana selects its existing hero artwork. SHA256 checks of all six original held-hero PNG files match `held-hero-before.json`, recorded before the icon installer ran.

All 10 screenshots were inspected by the fixture owner and independent art reviewer: icons fit the item cards, top labels remain readable, upgrade arrows remain distinct, helmet/armor stay upright, and the other icon directions agree with the final asset review. The asset-side semantic-axis metadata and generation checks live under `docs/design/2026-10-21/equipment-icon-fit/`; this fixture verifies native integration and routing.

The fixture uses an isolated workspace APPDATA/LOCALAPPDATA profile and disables PlayerData persistence. User saves remain unaffected. The only stderr output is the environment's Windows root-certificate-store warning; no script, resource, or gameplay runtime errors occurred.

`manifest.json` contains every assertion and measured card/art rectangle. The harness is `tests/ui_review/EquipmentIconLayout.tscn`, using Godot 4.7.2 with `gl_compatibility`.

- [Hero, 360px](hero-all-items_360x640.png)
- [Bag bottom, 360px](bag-bottom_360x640.png)
- [Equipped detail, 360px](equipped-detail_360x640.png)
- [Comparison detail, 360px](comparison-detail_360x640.png)
- [After equip, 360px](after-equip_360x640.png)
- [Hero, 720px](hero-all-items_720x1280.png)
- [Bag bottom, 720px](bag-bottom_720x1280.png)
- [Equipped detail, 720px](equipped-detail_720x1280.png)
- [Comparison detail, 720px](comparison-detail_720x1280.png)
- [After equip, 720px](after-equip_720x1280.png)
