# Trục tròn sau mèo — bỏ chấm đầu tam giác

Theo chỉnh hướng mới nhất ngày 23/10: bỏ toàn bộ ý tưởng đồ vật thật và quay lại đĩa/trục tròn đơn giản phía sau mèo.

- Đĩa tròn xanh xám tách nhẹ khỏi mèo cream, mặt phẳng, không huy hiệu.
- Giữ dáng mèo v6, hai tay cùng quay một cán, chân tròn và đệm thịt đào đất.
- Giữ hình tam giác béo gốc: root15, baseHalf15, tipHalf2.5, reach54.204253px. Đầu là cạnh cụt bo bằng line join, **không có hình tròn/chấm/đinh tán riêng**.
- Đã áp dụng vào Core trong game sau khi sửa vùng nách/tay. Pin vật lý và logic đẩy gear không đổi.

Canvas và SVG dùng cùng path. `preview.png` là ảnh duyệt; `motion.gif` là vòng quay 24 khung; `preview.html` có điều khiển góc và thử trên bàn gear.

Đã render 27 SVG bằng Godot 4.7.2; đã mở xem ảnh cơ cấu, ảnh có mèo và 4 pha chuyển động. 24/24 khung nằm trong canvas. Viền tam giác liền, đầu mũi không có marker tròn. HTML chưa được kiểm tra trực quan trong trình duyệt; ảnh PNG/GIF được dựng từ SVG native.

## Bản tích hợp

Vùng ngực được che bằng miếng màu lông nằm bên trong thân; tay đầy hơn ở vai và thu về cổ tay cũ. Đã bỏ các đĩa vai và ống màu lông phủ rộng vì chúng đè mất một phần viền thân. Không thêm nét tối để vá lỗi.

Runtime: `game/battle/CatDrive.gd`, assets ở `game/assets/battle/cat-drive/`. Mèo dùng 96 pose từ cùng path; đĩa và càng quay liên tục theo `board.pin_angle()`, cùng nhịp giảm tốc khi đẩy gear.

Kiểm tra native: PinMesh 0 lỗi; CatDriveReview 5/5 (96 ảnh pha, càng di chuyển giữa hai pose và không có chấm đầu); BattleCardboardCastleReview 13/13, gồm kéo/thả và chiến đấu ở 450×800 / 360×640. Ảnh và manifest ở `docs/ui_review/2026-10-23/cat-drive/`.
