# Mèo cầm tay quay bằng hai tay — concept sửa theo phản hồi

Thay concept mèo ngồi sau cối bằng mèo đứng vận hành tay quay tời. Hai tay nắm cùng một cán ngang dài 28 px; cán quay trên chốt lệch tâm bán kính 15 px và kéo trục/bánh đà quay. Cán tự xoay trên chốt nên vẫn nằm ngang, hai tay không bắt chéo hoặc đổi vị trí nắm. Tay, thân và cán dùng chung một góc pose; không có nhịp tay độc lập.

Mặt mèo dùng nguyên phần đầu cream đã tách, chỉ tịnh tiến/nghiêng toàn phần đầu; luôn mặt trước. Thân/chân và tay vẽ riêng cho dáng đứng; không có bàn hay mặt cối. Cơ cấu gỗ/carton, bạc trục xanh xám, màu phẳng. Main 2.9 px ở kích thước ô 100 px, đầu legacy 12 × .24 = 2.88 px. Secondary 1.6 px nâu #92764e chỉ ở nan bánh đà; mảng kem không viền thêm. Cần thấy rõ cả hai bàn tay, phần cán giữa và hai đầu cán.

`drive.js`: cùng path list cho canvas và SVG; `preview.html`: chạy/dừng/kéo góc, hình lớn, 4 pose và bố cục bàn B. `export.mjs`: xuất vector 100/300 px và 24 khung động. Góc demo chạy đều để xét động tác; gear lân cận chỉ minh họa bố cục, chưa mô phỏng state machine truyền động của game.

Đây là bản để duyệt động tác và hình dáng. Chưa sửa Core, CogDraw, GearBoard hoặc cơ chế pin. Không vẽ chồng cần pin sản xuất lên demo: tâm bánh đà đang ở (0,20), khác tâm pin (0,0), nên chưa chứng minh khớp truyền động với gear xung quanh. Khi tích hợp cần xử lý nối hai trục, dùng trực tiếp `board.pin_angle()`, giữ reach và chu kỳ hiện hành. Bản cối cũ ở `../cat-crank-demo/` đã bị từ chối.

## Bằng chứng đã kiểm tra

- `round-1.png` → `round-2.png`: bỏ viền kín phần đỉnh thân bị đầu che và hạ đầu 3 px để tránh gear phía trên. Đã mở xem cả hai ảnh.
- `poses.png`: 4 góc cực trị, cùng vector render bằng Godot ở 300 px và đúng ô 100 px; đã mở xem. Tay giữ đúng cán ở cả 4 góc, mặt không bị che.
- `motion.gif`: 24 frame/3 giây lấy từ SVG render bằng Godot, không dùng ảnh chụp HTML để làm khung động. Tất cả frame còn alpha trống ở mép canvas; `render-checks.json` ghi bounds.
- `preview.html`: chạy/dừng và kéo góc tương tác, cùng hình vẽ với các SVG. Các gear lân cận chỉ minh họa vị trí.

Tái tạo: `node .../export.mjs`, chạy `render_review.gd` bằng Godot, rồi `python .../package_review.py`. Không cần import hay thay asset sản xuất.
