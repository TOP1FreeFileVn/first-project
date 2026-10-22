# Thành giấy trong gameplay — cổng mở và bàn carton sát mép v3

Bản v3 theo chỉnh sửa tiếp của người dùng: bỏ hai mái tam giác trên cổng giữa, cho bàn gear sát hai mép màn hình và khôi phục đủ viền nâu hai cạnh ngoài của thành. Viền đặt cách mép bằng nửa nét chính (x = 2.3 và 717.7, nét 4.6 px), nên hiển thị hết nét tới x = 0 và 720. Mặt bàn trong, lưới gear, vị trí lính và quy tắc lớp vẽ của v2 giữ nguyên.

Bản v2 bỏ dốc trước cổng. Cổng đầu mèo mở xuyên, hai cánh bìa gấp sang hai bên; sàn trong cổng kết thúc sát mặt tường. Bàn xếp gear trở thành khay carton thấp, cùng màu bìa, nét nâu và băng keo kem với thành ngoài sảnh. Lưới gear 6 × 4, kích thước ô, vị trí trục và vùng kéo thả giữ nguyên.

Lớp sau và dải tường trên nằm sau lính; dải tường thấp phía trước được tách riêng để che phần chân sát tường. Đây là thay đổi lớp vẽ, chưa bổ sung đường đi xuyên cổng, collision mới hay các cấp thành mới. Phản hồi trúng đòn dùng màu hiện có của core.

## Ảnh đối chiếu

- `layers-v3-castle-board.png`: crop nguyên kích thước 450 × 440 từ ảnh đánh thật, vùng `(0, 310, 450, 750)`; không vẽ thêm hoặc resize. Đây là ảnh gọn để duyệt cổng và bàn mới.
- `layers-v3-comparison.png`: sảnh, tường đá cũ, v3 đang đánh và v3 chuẩn bị gear tại 450 × 800.
- `layers-v3-gate-table-detail.png`: crop phóng 2× chỗ nối cổng và bàn, đủ hai cạnh ngoài.
- `layers-v3-fight_*`, `layers-v3-prepare_*`: ảnh native 450 × 800 và 360 × 640; đã xem hai kích thước, mái tam giác đã bỏ, viền thành đủ và bàn chạm hai mép.
- `layers-v2-comparison.png`: bốn ảnh 450 × 800 chụp thực tế — thành ngoài sảnh, tường đá cũ, v2 đang đánh và v2 chuẩn bị gear.
- `layers-v2-gate-table-detail.png`: phần nối cổng và bàn lấy từ ảnh trận thật, phóng 2× để xem lớp vẽ và mép bàn.
- `layers-v2-fight_450x800.png`, `layers-v2-fight_360x640.png`: trận đang chạy ở hai kích thước gốc.
- `layers-v2-prepare_450x800.png`, `layers-v2-prepare_360x640.png`: cửa hàng trong trận và bàn gear.
- `comparison.png`, `before-*`, `after-*`: giữ nguyên chứng cứ của bản v1; `comparison.png` không bị ghi đè.

Tạo lại ảnh hiện tại bằng `python docs/ui_review/2026-10-22/battle-cardboard-castle/build_layers_v2_comparison.py --label layers-v3`. Bỏ đối số để dựng lại v2; các ảnh v1/v2 được giữ riêng.

## Rà soát hình ảnh

Đã xem cả trạng thái đánh và chuẩn bị ở 450 × 800 và 360 × 640. Nền carton che hết khay bo tròn cũ, mép trái/phải cân và không có bóng dưới bàn. Mặt bàn đủ yên cho hình gear và màu cấp gear; hàng cuối không bị mép bàn đè. Cổng không còn dốc hoặc tấm cửa đặc. Dấu đăng ký nhỏ thay vòng tròn dấu cộng của ô trống; ô khóa vẫn có khóa rõ.

## Kiểm tra

Lượt native v3 có **13/13 kiểm tra đạt**, gồm lớp tường thấp che đúng phần lính, khoảng mở cổng không che lính, phần thân lính trước tường trên vẫn đọc rõ và bốn kiểm tra input thật khi nhấn, kéo, thả rồi trả gear về ô cũ. Probe lớp vẽ tạm ẩn HUD để popup mua gear không che điểm lấy mẫu; ảnh gameplay vẫn chụp với HUD hiện bình thường. Native v2 trước đó cũng đạt 13/13. DeploymentTest đã đạt **29 kiểm tra** ở bước v2, gồm giới hạn lính phía trên bàn gear và khả năng địch đánh thành; không chạy lại cho v3 vì chỉ đổi hình học SVG, không đổi gameplay.

EquipmentArtTest đã đạt 101 kiểm tra ở bước tích hợp rìu trước đó. Bản v2 không đổi thông số HP, công thức chiến đấu, vị trí bàn hoặc kích thước gear. Scene review dùng renderer OpenGL, profile tạm và tắt ghi save. Log native chỉ còn cảnh báo đọc root certificate store của môi trường; không có lỗi parse/runtime trong lượt này.

## Nguồn

- Thành: `docs/design/2026-10-22/battle-cardboard-castle/` → `game/assets/battle/cardboard-castle/`.
- Bàn: `docs/design/2026-10-22/battle-cardboard-board/` → `game/assets/battle/cardboard-board/`.
- Runtime: `game/battle/Background.gd`, `game/battle/GearBoard.gd` và scene `tests/ui_review/BattleCardboardCastleReview.tscn`.

Chạy scene review với `-- --label=layers-v3` trong profile thử để chụp lại. Để xem trong game bình thường, chạy `game/battle/Battle.tscn` hoặc vào trận từ sảnh.
