# Tay quay hai tay v4 — tay tròn mập, chân măng cụt

Theo phản hồi: tay phải béo tròn kiểu mèo; chân đang lộ đổi thành đôi “măng cụt”. Giữ nguyên độ thấp, đầu, mặt đất, bánh quay và quỹ đạo đã có ở v3.

Cẳng tay vẽ thành ống cong có bề rộng phần lông 8.4 px, đóng tròn ở cổ tay, mở đường nối vai để hòa vào thân. Bàn tay gần tròn 9.6 × 9.4 px, không ngón tay hay cổ tay vuông. Hai tay vẫn cách 14 px và bám cùng cán. Chân đổi từ hình chữ nhật bo 14 × 10 thành hai cục tròn 13 × 13 px, đáy giữ y39 như bản trước. Không thêm đường chia ngón, móng hoặc đệm chân mặt dưới vào góc nhìn chính diện.

Nguồn canvas/SVG dùng chung `drive.js`; main 2.9 px #583f21, secondary 1.6 px #92764e của nan bánh quay, màu phẳng. `motion.gif` có 24 frame/3 giây render bằng Godot; `poses.png` kiểm tra 4 góc ở 300/100 px, `before-after.png` so v3/v4.

Bản duyệt hình và động tác, chưa thay trong game. Tâm trục bánh đà khác tâm pin sản xuất; các gear xung quanh minh họa bố cục. Giữ nguyên v3 tại `../cat-two-hand-drive-v3/`.

Đã mở xem `round-1.png`, `poses.png` ở 300/100 px và `before-after.png`: tay tròn, hai bàn tay còn tách nhau khi nắm cán; chân tròn và giữ mặt đất. Godot xuất 32 SVG thành công; cả 24 frame có alpha trống ở mép canvas (`render-checks.json`).
