# Bánh răng B — đã duyệt và áp dụng vào game

Người dùng chọn **B — Bánh đúc**. Sáu SVG production (cấp 1–5 và bánh chưa nối trục) đã dùng cùng contour B được fit theo khoảng hở thật của chốt và hai bánh ăn khớp. Mặt lõi lớn chỉ là mảng màu phẳng, không có viền phụ; màu cấp pastel vẫn giữ rõ khi đặt trên bàn carton.

Nguồn chuẩn: `game/ui/art_sources/battle_cog_B.svg`; nguồn Canvas: `gears.js` và `export.mjs --install=B`. `make_svgs.battle_cog()` đọc lại template chuẩn này để rebuild không quay về dáng cũ. `B-approved-original.svg` giữ bản B trước khi fit; `before-tier-1.svg` giữ art production cũ để đối chiếu. `B-production-fit.png` là Canvas bản fit đã được xem, `B-in-game.png` là ảnh cắt từ gameplay thật.

## Contour và khoảng hở

- 8 răng, outer 54, root 36.5, shoulder 43; sườn ±14°, nửa đầu răng ±5.5°, bo 2.4; pha contour +13.5°, canvas 128 × 128.
- Nét chính 3.2 px, nâu `#583f21`; tương ứng 2 px trên màn rộng 450. B không dùng đường ráp hay viền phụ trong mặt lõi.
- B ban đầu có khe chốt −0.181 px và khe hai bánh −1.936 px. Bản fit giữ cấu trúc bánh đúc, mở khoảng hở ở hõm/sườn/đầu răng để tránh chồng nét.
- **PinMeshTest thực của Godot: 0 lỗi**, khe chốt tối thiểu **1.632 px**, khe hai bánh **0.779 px**, vượt ngưỡng 1.5 / 0.5 px. Test đọc contour có stroke của SVG production, quét toàn chu kỳ và kiểm tra các chuỗi quay độc lập. Xem `B-pinmesh-stdout.log`.

## Sáu file production và kiểm tra

`game/ui/skin/battle_cog_tier_1.svg` đến `battle_cog_tier_5.svg`, cùng `battle_cog_idle.svg`. Màu viền răng lần lượt kem `#ead5ac`, xanh lam `#80bfd7`, tím `#b49cd6`, cam `#eead6c`, xanh lá `#aec778`; lòng chung `#f4dfb4`. Bánh chưa nối trục dùng vành `#aaa995`, lòng `#d2cbb8` để giảm chú ý.

`godot/B-production-palette.png` ghép trực tiếp sáu SVG production do Godot rasterize, có hàng kích thước thật 80 px tại màn rộng 450. Đã xem ảnh và kiểm tra 12 mẫu màu ở vành/lòng; năm màu cấp rõ, lòng phẳng yên và bánh chưa nối trục nhẹ hơn. Lượt render này dùng profile riêng `output/gear-B-palette`, không import editor hoặc ghi save.

Native gameplay nhãn `layers-gear-B` đạt **13/13 kiểm tra**, gồm lớp thành, cổng mở, giữ vị trí bàn, nhấn/kéo/thả/trả gear, thành nhận sát thương và không ghi save. Đã xem ảnh 450 × 800 và 360 × 640. Manifest nằm ở `docs/ui_review/2026-10-22/battle-cardboard-castle/layers-gear-B-manifest.json`; log `B-native-stdout.log`. Rebuild riêng `make_battle_cogs()` đã được hash-check: cả sáu file không đổi byte. Stderr chỉ còn lỗi đọc root certificate store của môi trường, không có lỗi parse/runtime.

## Tạo lại

1. Sửa Canvas, chụp và xem `preview.html` trước khi xuất hình mới.
2. `node docs/design/2026-10-22/gear-options/export.mjs --install=B` cập nhật canonical B.
3. `python -c "import sys; sys.path.insert(0,'tools/ui'); import make_svgs; make_svgs.make_battle_cogs()"` tạo lại đúng sáu SVG bánh răng.
4. Chạy Godot `--headless --path . res://tests/PinMeshTest.tscn`, rồi import asset mới và chụp lại `BattleCardboardCastleReview.tscn` với `-- --label=layers-gear-B` trong profile thử.
5. Bảng màu: chạy `render-B-palette.gd` bằng Godot headless (profile riêng), rồi `python docs/design/2026-10-22/gear-options/build-B-palette.py`.

## Lịch sử sáu phương án

Giữ dáng mèo và bảng màu phẳng hiện tại; thử các cấu trúc răng khác nhau thay vì chỉ đổi stroke/màu. Các mẫu nằm trên cùng bàn carton và có cùng mèo, huy hiệu cấp, vòng tiến độ.

- A: răng khối bo, vai răng có bậc, mặt lõi có đường ráp nhẹ.
- B: khối tròn đúc với răng hình thang thấp, mặt lõi lớn không viền phụ.
- C: răng quét cong cùng hướng, đầu bo và không nhọn như lưỡi cưa.
- D: carton bế bậc.
- E: vành có khe.
- F: đầu răng tròn mềm.

Nét chính 3.2 px / nét phụ 1.9 px trên hệ tọa độ game; tương ứng 2.0 / 1.1875 px ở màn rộng 450. Viền chính nâu #583f21; đường ráp phụ #9b784b. Màu phẳng, không đường sáng chạy theo viền, không bóng hoặc gradient. Lỗ xuyên là silhouette dùng nét chính, mặt chất liệu là fill.

Mỗi bánh giữ 8 răng, outer 54 và vùng giữa cho icon lính 62 px. Dòng nhỏ có khoảng tâm 100 đơn vị, scale 0.625 giống màn game 450 px. Các phương án A/C/D/E/F vẫn là bản so hình chưa được chứng nhận ăn khớp. Chỉ B được chọn, fit và kiểm tra theo kết quả phía trên; không đổi cơ chế CogDraw/Gear/GearBoard.

Mở `preview.html`: nhấn A–F để thay toàn bộ bánh trên bàn bên dưới; nút Bật quay để xem chuyển động. Canvas và SVG xuất từ cùng Pen operations. `round-1.png` / `options.png` là bản so sáu phương án; `board-context.png` xem phương án được đề xuất trên bàn. Nguồn cats: PNG production không chỉnh sửa; tham chiếu Figma `wMtwWaYIiKUchUdq5YdTm5`, node3471:252 đã được xem lại trong lượt này.
