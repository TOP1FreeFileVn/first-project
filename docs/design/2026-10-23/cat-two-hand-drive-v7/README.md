# Tay quay mèo v7 — cụm truyền động mới sau mèo

Brief: mèo ở trước cụm đẩy bánh răng chính, máy có màu tương phản nhẹ với lông; không làm giống bản gốc bị người dùng chê. Thiết kế mới là máy tời đồ chơi với **vành vuông bo rỗng, hai gối đỡ nhỏ và thanh đẩy thon**. Không dùng mâm vàng, tay đòn tam giác hay huy hiệu chân mèo của `CogDraw.draw_orb`.

Máy dùng xanh xám #91aaae và xanh sữa #adc6c7; mèo giữ cream #f2d2ac, đệm đào đất #ca8b7b. Màu phẳng, viền chính 2.9 px nâu #583f21. Nan phụ dùng nét 1.6 px xanh xám #5e7c82. Tay, mặt, chiều cao và chân v6 giữ nguyên. Tay nắm gỗ nhỏ phân biệt chỗ cầm.

Cụm sau có vành vuông bo54×54 px, lỗ giữa38×38 px, quay quanh tâm master(0,0). Hai gối đỡ nằm trong±33.5 px. Hai crank bằng nhau radius9.5 tại(0,0)/(0,22), cùng pha, nối bằng thanh cứng22 px để giải quyết khác tâm. Cần đẩy cùng góc, reach tính từ đúng biểu thức GearBoard(54.204253...), pin ink radius3.5, fill1.5. Không thêm răng master giả thành gear ăn khớp liên tục.

Layer: gối đỡ/thanh nối/vành/cần đẩy → thân/đầu mèo → tay quay trước → lòng chân → tay/cán/bàn tay. Cần không chạy ngang mặt. ViewBox128 để không cắt pin; kích thước thật vẫn1đơn vị=1px bàn gear.

Đây là bản để duyệt, chưa sửa runtime hay asset sản xuất. Góc demo chạy đều3 giây, gear lân cận chỉ minh họa, chưa mô phỏng contact state machine. Khi tích hợp phải lấy `board.pin_angle()` và kiểm tra PinMesh/native review.

`preview.html` có nút xem riêng cụm máy, chạy/dừng/kéo góc. `export.mjs` xuất cùng path canvas thànhSVG; `render_review.gd` render bằng Godot; `build_review.py` tạo GIF24frame và ảnh review. V6 giữ nguyên tại `../cat-two-hand-drive-v6/`.
