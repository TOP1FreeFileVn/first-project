# Tỷ lệ hình và phần thông tin của thẻ lính

[Ảnh cắt trước–sau ở kích thước native 360 px](before-after.png) — ảnh thẻ giữ nguyên số pixel, không phóng to. Gồm Kiếm, Bình Thuốc và Sách Phép.

Thẻ giữ chiều cao 240 px design (120 px native360). Vùng màu/nhân vật tăng từ 92 lên 154 px design; chân dung tăng từ 88 lên 120 px. Tên và hàng cấp/sao được gom gọn dưới hình.

Ước lượng phần kem bên dưới, trừ 8 px đệm trên: `(240 − chiều cao vùng màu − 8) / 240`, giảm từ **58,3% xuống 32,5%**. Đây là tỷ lệ theo hình học Control, không phải đo từng pixel viền/nền. [Số đo](balance-measurements.json).

Ảnh màn hình thật:

- [Thành 1, đội 3/3 — 360 × 640](starter_all_360x640.png)
- [Thành 6, đội 5/5 — 360 × 640](late_all_360x640.png)
- [Tên dài và hàng cuối — 360 × 640](starter_all_scrolled_360x640.png)
- [Thành 1 — 720 × 1280](starter_all_720x1280.png)

Kết quả **24 ảnh native, 66 tuyến tương tác, 0 lỗi kiểm tra**, cả bốn lệnh Godot thoát mã 0. Chỉ có thông báo kho chứng chỉ Windows đã có từ trước.

- Bốn cột bằng nhau và không tràn ngang ở 360/720 px; tất cả tên đầy đủ.
- Chân dung nằm trong vùng màu; vùng màu nằm trong thẻ và kết thúc trước phần tên.
- `TroopCardDetails`, cấp và sao nằm trong thẻ; tên, cấp và sao nằm trọn trong phần thông tin.
- Đội 3/3 và 5/5, bao gồm tên dài Bình Thuốc; cả năm bộ lọc và trạng thái khóa/đã mở/trong đội/đủ nâng cấp/đủ lên sao.
- Nhấn thẻ vẫn giữ nền màu, mở chi tiết, nâng cấp/lên sao và trừ vàng/thẻ đúng; đóng popup, click bộ lọc có một tiếng, cuộn và kéo đổi đội hình đều hoạt động bằng con trỏ thật.

Review chạy Home/TroopsPage thật trong profile riêng, `PlayerData.persist = false`. Ảnh trước được sao chép vào `before/`; kết quả các lần review trước được giữ nguyên.

Chạy lại: `node tools/review/mcp_ui_review.mjs docs/ui_review/2026-10-19/troops-card-balance-plan.json`. Plan chia bốn scene theo trạng thái starter/late và kích thước 720/360 để mỗi lệnh MCP nằm trong giới hạn 15 giây. `manifest.json` gộp bốn kết quả `manifest_<width>_<scenario>.json`.
