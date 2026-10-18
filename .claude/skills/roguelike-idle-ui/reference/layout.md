# Full-screen layout (from real GearPaw / Gear Defenders screens)

Source: Figma page `3505:2` "Bố cục toàn màn" — 22 annotated 900×1600 states (Bộ A `3505:12…95`,
Bộ B `3505:103…123`) and 7 runtime shots (`3523:13/17/21` GearPaw main/shop/heroes,
`3523:29/33/37/41` Gear Defenders main/shop/summon/SVIP popup). Fetch single shots with
`get_screenshot` (`contentsOnly: true`). Positions below are % of screen height (1600 → 1280 in
our 720×1280 project, so ×0.8 for px).

## Vertical bands (every non-battle screen)

| Band | Height | Content |
|---|---|---|
| HUD | top 6–14% | avatar + Lv (+ power bar), energy, gold, gems; small "+" on each; thin EXP bar under (GD) |
| Content | 14–80% | the screen's one subject (stage, shop board, hero stage + list) |
| Action strip | 80–88% | the main button, or a 2–4 sub-tab pill row (Gói / Cửa hàng; Vua / Đá quý / Lính / Bánh răng) |
| Bottom nav | last 8–10% | 5 tabs, selected one taller and labelled, others icon-only; red dots; floating callout bubble ("Triệu hồi 10") above a tab |

The bottom nav and HUD never move between screens; only the content band changes.

## Lobby / main
- Centre: the current stage as a big picture (GD: island diorama; GP: the boss), title plaque
  + progress "(4/4)" + recommended power just above it.
- **Side rails**: a column of feature icons on the left (pass, VIP, limited gift with countdown)
  and right (events, summon), each icon + label + optional timer/red dot. They frame the
  centre, never overlap it.
- Below the picture: wave/difficulty selector or reward chest, then the **big CTA** (wide yellow
  two-line button: "Trận chiến / ⚡x5") centred ~75–80%. Locked neighbour stages peek at the
  left/right edges at the same height.

## Shop
- Section title centred, then a **hero offer**: one wide card (art left, reward slots right, value
  burst top-right corner, big price button), with page dots under it (carousel).
- Next section title + refresh timer bar, then a **2-column (GD) or 3-column (GP) grid** of
  equal cards: title, item slot, limit text, price/"Miễn phí" band. Locked slots keep the grid
  ("Lv.10 Mở khóa").
- Sub-tab pill row above the nav. GP puts a themed banner (shop awning) at the top instead of a
  scene.

## Heroes / summon
- Top half is a **scene** (meadow with heroes on stands, or the summoner + crystal), HUD sits
  on it. Locked stands show "Lv.5 Mở khóa".
- A divider strip with filters (element chips) and an action button ("Chỉnh sửa đội").
- Bottom half: card grid (4 columns), each card = art, LV, element icon, "Đã xuất chiến" tag,
  upgrade arrow. Sub-tabs (Anh Hùng / Hợp Thể / Skin).
- Summon: pity text on a dark strip, milestone chests row with timer, then **three equal
  pills** (free/ticket/gems ×1, gems ×10) above the sub-tab row.

## Battle
- HUD row: pause, enemy count, currency, (speed ×2, stats) — small round buttons in corners.
- Field in the top ~40% ending at the wall with its HP bar; gear board below on a plain floor
  with `+` slot marks; one action button at the bottom ("Refresh 💎30").
- Level-up pick: title ribbon centred near the top, **2–3 equal cards side by side**, the
  board dimmed behind; tutorial bubble + guide character at the bottom.
- Result: dark overlay, gold banner across the width ("Completed" + stage name), stats pill,
  then two buttons (ad-double teal, continue yellow); MVP badge top-left.

## Popups
- Dimmed screen, centred cream window with a **title strip** and a red round **close at the top
  right corner**, content in order: choice/preview → info rows → rewards row → 1–2 buttons at
  the bottom (secondary teal/blue left, primary yellow right).
- Rows of rewards/lists keep icons, counts and claim buttons in aligned columns.

## Rules to apply
1. Same HUD and nav on every screen; content swaps in between.
2. One centre subject + one big CTA; secondary features go to side rails or small pills.
3. Grids of equal cards; locked items stay in the grid as placeholders.
4. Overlays are separate layers (dark scrim → window/content), never a new screen.
5. Leave breathing room around the CTA; don't put buttons over the main character/art.
6. Text must fit — the GD SVIP popup in the Figma page is kept as a bug example of crowded text.

## 30 vertical layout patterns (Figma `3529:4` "30 bố cục màn dọc · tuyển chọn cho game mèo")

Block diagrams on a 360×640 (9:16) frame. Every pattern is a vertical stack of bands from this
vocabulary: **Thông tin / số dư** (HUD) · **Tiến trình** · **Nhân vật / nội dung** · **Tab nội
dung** · **Danh sách cuộn** / **Lưới nội dung** · **Thao tác chính** (green) · **Thao tác phụ** ·
**Điều hướng** (nav). Starting picks: UI-001 lobby · UI-011 summon units · UI-018 buff ·
UI-025 team · UI-041 shop · UI-050 map · UI-065 quests.

| Group | Rule | Patterns (id · layout · when) |
|---|---|---|
| 01 Lobby | One clear main play action; side notices never invade the centre | **001** stage in the middle, play button under it, tabs at the bottom (idle, fast into battle) · **004** chapter name + progress on top, stage preview middle, fight below (linear stages) · **005** top half scene, bottom half tabbed panel (keep the world visible) |
| 02 Battle HUD | HP, goal and skills first; keep enemies visible; test with the heaviest VFX | **010** wave/boss on top, field middle, one skill row bottom (auto-battle idle) · **011** economy/energy on top, unit card row with cooldowns at the bottom (Battle Cats style) · **013** field on top, buy/merge board below (merge while fighting) |
| 03 Buff pick | Show how a choice changes the build; separate pick / reroll / skip | **018** each buff a big row, icon left, text right (long Vietnamese text) · **020** buff list on top, current build icons below (synergy) · **024** between-wave rest: run state, then heal / buy / upgrade |
| 04 Heroes / team | Keep the viewed item, ownership and team effect clear | **025** team slots on top, filter + hero grid below (3–6 cats, drag to swap) · **026** big portrait top, stats/skills in tabs below · **028** filter on top, scrolling grid, tap for detail |
| 05 Inventory | Always filter, count, lock and equipped state; compare in the same units | **033** paper doll + bag · **036** category tabs, each with its own scroll · **037** tap item → bottom sheet comparing equipped vs new |
| 06 Shop / summon | Price, balance, contents and purchase state visible; banners never cover goods/buttons | **041** equal cards, price in the same spot · **042** featured pack on top, sections below · **047** banner middle; pity, odds and tickets next to the pull buttons |
| 07 Stages / map | Tell current / reachable / done apart; lock conditions readable | **049** vertical winding node path + info window · **050** roguelike branch map, tap node for risk/reward · **052** stage grid with stars/locks on each tile |
| 08 Upgrade | Show cost and change first; locked / enough / missing look different | **057** repeating stat rows (level, +gain, price) · **059** talent tiers by row · **061** one big item + change preview + cost |
| 09 Quests / events | Time, condition, progress and claimed state together; test expiry | **065** daily/weekly tabs, rows, claim all · **066** calendar grid, today highlighted, fixed claim button · **068** one main banner + list of timed events (keeps the lobby free of icons) |
| 10 Popup / reward | One idea per popup, clear exit, consistent Back, no stacked layers | **073** reward grid in a modal · **074** full-screen new hero (art, name, rarity, continue) · **078** bottom detail sheet over the visible context |

Selection criteria from the page: content runs vertically; no thick sidebars or multi-column
tables; a dedicated area for the main action; text ≥ 14 px at 360 wide (≈ 28 px in our
720-wide project); top/bottom margins for safe area. Still to test in game: touch areas, long
text / big numbers, empty / full / locked states, scrolling, heavy battle VFX, 9:19.5 and 9:20
screens (the 24 px margin in the diagrams is a placeholder for the real safe area).

**Note for our lobby:** UI-001 says side notices must not invade the centre, and UI-068
suggests moving events into one events page to avoid icon overflow — keep the side rails
short (3 per side max) and push extra events into an "Sự kiện" page.

## Screen map for the current gameplay (sheet "Gear Meow", tabs Change + Core battle)

One hero cat with swappable weapons (each weapon: own attack + skill, 2 skill gears, pairs with
2 soldier classes); 4 soldier classes in a counter ring (Tầm xa > Bộ binh > Pháp sư > Kỵ binh >
Tầm xa, ×2). Hero gear and soldier gear are **separate**.

Bottom nav: **Cửa hàng · Anh hùng · Chiến · Lính · Triệu hồi** (icons tab_shop, tab_cat,
tab_battle, tab_army, tab_summon).

### Equipment screens (rules learned from idle RPGs + GD KingEquip; first version was rejected)

**Reference the user picked: Capybara Go's equipment screen** (saved as
`scratchpad/v2/ref_capy.png` during the session; same genre). Follow it:
- Upper area is a **cream panel** (no scene, no title plaque): 3 gear cards | big hero | 3 gear
  cards, cards pushed to the panel edges.
- Gear card (`Ui.gear_card`): rarity fill, **slot-type badge top-left**, **"Lv.x" top-right**,
  big art, **green up arrow bottom-right** when it can be upgraded now.
- Under the hero: **big power plaque**, then 3 stat pills (Máu, Công, Giáp) + a detail button.
- A row of **feature shortcuts** with labels and red dots (Kỹ năng, Hợp lính, Sưu tập, Thành
  tựu, Skin) — replaces any extra info strip.
- **Dark bag** below: header band "Theo phẩm" (sort) · "Trang bị của tôi" · "Ghép" (merge, red
  dot), then a 5-column grid of the same cards.

- The weapon is **one of the 6 slots** (GD KingEquip types: Weapon, Crown, Armor, Necklace,
  Ring, Boots) — never a separate strip.
- Slots are big (≈112 px) and **hug the character** in two columns, no captions; level as a
  small "Lv.x" plaque on the slot's bottom edge; empty slots show the type's grey silhouette.
- **Stat totals** (Công, Máu, Lực chiến) sit right under the character — the number that moves
  when gear changes.
- The weapon's extras (2 skill gears, 2 paired soldier classes) go in one strip under the
  totals with icons, not as tiny chips.
- The bag is one sheet flush with the nav: type filter (icon tabs), 5-column grid, Sắp xếp +
  Ghép tự động.
- Tapping an item opens a **comparison sheet** over a dark scrim: equipped vs new side by side,
  each stat "old → new" with the difference green (better) / red (worse), then Nâng cấp /
  Trang bị (`HeroPreview` with `-- --detail`).
- Per-class lists (soldier tiers) are **rows** (UI-057): slot, name, stats, price button at the
  same right-hand spot; locked rows show a locked "Mở khoá".

- **Anh hùng** (`tests/ui/HeroPreview.tscn`): the Capybara Go layout above; slots Vũ khí, Mũ,
  Giáp | Bùa, Nhẫn, Giày.
- **Lính** (`tests/ui/ArmyPreview.tscn`): class tabs → class banner (top weapon on a stand) with
  4 class-gear slots beside it → class bonus pills → counter line → tier rows with upgrade
  price.
- Old `LobbyPreview` (4 cats on stands + support-troop grid) and `GearsPreview` (gear
  inventory) belong to the previous multi-unit design.
