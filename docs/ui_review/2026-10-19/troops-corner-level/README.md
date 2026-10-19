# Cấp ở góc phải của thẻ lính

[So sánh trước–sau](before-after.png) — ba thẻ được cắt từ ảnh native 360 px, giữ nguyên pixel, gồm Cấp 10, Cấp 1 và lính vừa trong đội vừa có thể nâng cấp.

Cấp nằm ở góc trên bên phải trong một nhãn kem. Tên nằm giữa phần chân thẻ, ba sao thành một hàng riêng bên dưới. Badge trong đội/nâng cấp chuyển sang góc trái để tránh nhãn cấp; lính chưa mở vẫn có khóa bên phải.

Ảnh đầy đủ: [đội 3/3](starter_all_360x640.png), [đội 5/5](late_all_360x640.png), [cuộn đến cuối](starter_all_scrolled_360x640.png).

**24 ảnh native, 66 tuyến tương tác, 0 lỗi kiểm tra**; cả bốn lệnh Godot thoát mã 0. Đã kiểm tra nhãn cấp nằm trong vùng màu, sát phải, không đè chân dung/tên/badge; tên và sao căn giữa; toàn bộ chữ nằm trong thẻ. Các bộ lọc, nâng cấp/lên sao, đóng popup, cuộn và kéo đội hình tiếp tục hoạt động bằng con trỏ thật ở 360/720 px, đội 3/3 và 5/5.

Review chạy Home/TroopsPage thật với profile riêng, không ghi save (`persist = false`). Ảnh cũ được giữ trong `before/`. Chỉ có thông báo kho chứng chỉ Windows đã có từ trước, không có lỗi script.

Chạy: `node tools/review/mcp_ui_review.mjs docs/ui_review/2026-10-19/troops-corner-level-plan.json`. `manifest.json` gộp bốn kết quả theo kích thước và trạng thái.
