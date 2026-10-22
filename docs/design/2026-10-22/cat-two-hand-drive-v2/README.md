# Tay quay hai tay v2 — hạ mèo, rút ngắn tay

Theo phản hồi ngày 2026-10-22: hạ mèo xuống, tay ngắn lại, thu bánh quay để tỷ lệ cân. Giữ nguyên v1 ở `../cat-two-hand-drive/` để so sánh.

- Hạ đầu 7 px, vai 8 px; rút phần trên thân, giữ chân tại mặt đất cũ. Không kéo cả thân xuống làm chân lọt sàn. Giữ nguyên hình và kích thước đầu mèo.
- Bánh đà bán kính 17.5 → 13.5 px (nhỏ hơn khoảng 23%); quỹ đạo cán 15 → 9.5 px (ngắn hơn khoảng 37%). Tâm bánh xuống 2 px, tại (0,22).
- Thu khuỷu tay vào thân. Hai tay vẫn cách nhau 14 px, bám cùng cán 28 px, không trượt hoặc đổi vị trí. Khoảng cách vai–cán ở điểm thấp nhất giảm từ khoảng 37 px xuống 26 px.
- Giữ màu phẳng, main 2.9 px nâu #583f21, secondary 1.6 px #92764e. Không thu toàn hình hoặc stroke để tạo tay ngắn giả.

`drive.js` là path source dùng chung cho canvas/SVG; `preview.html` là demo chạy/dừng/kéo góc, với bối cảnh bàn gear B. `export.mjs`, `render_review.gd`, `package_review.py` xuất SVG, render bằng Godot và đóng GIF 24 frame/3 giây.

Đây vẫn là bản duyệt hình và động tác, chưa thay asset trong game. Tâm bánh đà khác tâm pin sản xuất nên phần truyền động ra gear chưa được chứng minh. Gear lân cận trong demo chỉ minh họa bố cục.

Đã mở xem `round-1.png`, `poses.png` (4 góc ở 300 và 100 px), `before-after.png` (cùng kích thước đầu/mặt đất). Không bị che mặt, hai tay còn tách rõ, cán lộ ở giữa và hai đầu. Godot render 32 SVG thành công; toàn bộ 24 frame còn khoảng trống alpha ở mép canvas (`render-checks.json`). `motion.gif` dùng trực tiếp các frame Godot, giữ chu kỳ 3 giây.
