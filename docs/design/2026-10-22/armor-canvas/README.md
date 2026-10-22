# Áo giáp — mẫu Canvas để duyệt

Giáp ngực bầu, hai vai rộng và cổ mở rõ; thay dáng áo ba lỗ/băng xanh của bản cũ bằng cấu tạo giáp tấm. Bản hiện tại dùng một họ màu thép bạc với hai fill phẳng, không gradient hoặc bóng. Giữ dáng thẳng, chỉ là icon cộng chỉ số, không mặc lên mèo.

Hai cấp nét: MAIN nâu `#583f21` cho silhouette và cổ hở; SECONDARY nâu dịu `#9b7f58` cho đường nối nách. Mảng vật liệu không bao viền. Main **11.35 px**, secondary **4.94 px** trên icon 256 px; secondary tăng đúng 30% từ 3.8 px theo yêu cầu tiếp theo của người dùng. Không áp 9 px của vũ khí cầm lên icon độc lập.

Sửa sau phản hồi trực tiếp của người dùng: đường nối giáp vai ở nách phải là nét phụ, không dùng độ dày nét chính. Đã bỏ đường xám cong trên ngực và hai nét xám bên thân; không thêm đường mảnh trang trí để chứng minh có hai cấp stroke. `round-1.png` là bản trước phản hồi, `round-2.png` là bản đã sửa.

`round-3.png` giữ bảng màu, tăng nét phụ thêm 30% so với round-2. Phối màu dùng nâu/vàng ấm đi với thép xanh lạnh, ưu tiên hình và cấu tạo khi thu nhỏ. Đây là lựa chọn mỹ thuật theo style game, không phải chứng nhận một tiêu chuẩn màu chung.

Phản hồi tiếp theo: không dùng màu mèo làm tiêu chí phối màu; lấy màu vật liệu của trang bị game thông thường làm chuẩn. Bản thử màu tiếp theo dùng thép bạc `#dce7ec`, mặt thép `#a5bcc7`, vai thép `#c4d3db` và đồng tiết chế `#d6a650`. Giữ nguyên hình, nét chính 11.35 và nét phụ 4.94 px đã chỉnh. Không suy ra cần thêm nhân vật người hay mặc giáp lên mèo. `armor-palette-preview.png` là ảnh thử màu mới, bản trước còn trong `round-3.png`.

Người dùng tiếp tục chê phối quá nhiều màu và yêu cầu xem Figma. Đã đọc trực tiếp bằng Figma MCP ngày 2026-10-22: [nhóm KingEquip](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3443-119) và [Armor0113](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3447-7569). Ảnh chụp lưu ở `figma-equipment-reference.png` và `figma-steel-reference.png`. Mỗi món giữ một họ màu vật liệu chủ đạo; nhiều mức sáng/tối trong cùng họ không đồng nghĩa nhiều màu nhấn. Giáp bạc có biểu tượng xanh lam nhỏ, trong khi phần lớn diện tích là bạc/xám; giáp da chủ yếu đỏ nâu và giáp vàng chủ yếu vàng/cam.

Bản sửa hiện tại bỏ cổ/đai vàng đồng và màu vai riêng, chỉ dùng hai fill cùng họ bạc: `#d9e0e8` và `#a8b4c7`. Giữ nguyên silhouette, main 11.35 px, secondary 4.94 px cùng hai màu nét đã chỉnh; không thêm biểu tượng hoặc đường trang trí. Đây là cách giới hạn bảng màu cho mẫu này, không phải khẳng định reference chỉ có hai swatch hay áp số màu cố định cho mọi trang bị. `armor-figma-palette-preview.png` là bản để duyệt; `armor-palette-preview.png` giữ nguyên bản nhiều màu bị chê. Chưa thay asset production.

Đối chiếu nét kiếm đang dùng: đoạn thẳng lưỡi khoảng 12.75–13 px trên nguồn 256 px. Ô 124 logical px hiển thị kiếm trong square .68 và giáp trong square .78. Mục tiêu tương đương: `13 × .68 / .78 ≈ 11.33 px`; kiểm tra thêm ở các icon 32/48/64/96 px và trong thẻ Godot thật. Đây là mẫu mới để duyệt, chưa thay asset production.

Phản hồi mới nhất: tăng nét phụ thêm **50% so với 4.94 px**, thành **7.41 px** trên icon 256 px. Giữ main **11.35 px**, bảng màu bạc và hình hiện tại. Các thông số 4.94 px phía trên mô tả bản trước. `armor-secondary-plus50-preview.png` là bản mới; `armor-figma-palette-preview.png` giữ bản trước khi tăng nét.

Nguồn duy nhất: `item.js`; Canvas và SVG xuất từ cùng path. `preview.html` xem hình, `export.mjs` xuất SVG; PNG trong `godot/` dùng renderer của game.
