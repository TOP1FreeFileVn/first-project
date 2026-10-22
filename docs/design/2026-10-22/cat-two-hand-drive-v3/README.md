# Tay quay hai tay v3 — thấp thêm

Theo phản hồi “thấp hơn nữa”: hạ phần đầu và vai thêm 6 px so với v2; rút phần trên thân và tay tương ứng, giữ chân tại mặt đất. Giữ nguyên hình/kích thước đầu, bánh đà 13.5 px, quỹ đạo cán 9.5 px và khoảng cách hai bàn tay 14 px. Main 2.9 px, secondary 1.6 px, màu phẳng như v2.

Nguồn vector `drive.js` dùng chung cho canvas, SVG và GIF. Bản v2 được giữ nguyên tại `../cat-two-hand-drive-v2/`. `before-after.png` so sánh với v2 cùng mặt đất/kích thước đầu; `poses.png` có bốn góc và bản 100 px. `motion.gif` dùng 24 frame render bằng Godot, chu kỳ 3 giây.

Đây là bản duyệt hình/động tác, chưa thay trong game. Gear xung quanh chỉ minh họa bố cục; tâm trục bánh đà vẫn khác tâm pin của game và cần xử lý ở bước tích hợp.

Đã xem ảnh canvas `round-1.png`, native `poses.png` ở 300/100 px và `before-after.png`. Bốn góc không che mặt, tay bám cán, chân giữ cùng mặt đất. Godot xuất 32 SVG thành công; cả 24 frame còn alpha trống ở mép canvas theo `render-checks.json`.
