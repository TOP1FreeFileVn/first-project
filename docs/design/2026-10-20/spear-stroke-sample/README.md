# Thương — bản thử nét để duyệt

Một vũ khí mẫu sau lần học lại stroke từ Figma 3443:2. Đầu thép dùng hai diện màu không có nét giữa; nét quấn da là nâu đỏ trầm, nhẹ hơn viền hình. Khớp đồng và cán gỗ có diện màu rộng. Giữ mèo gốc, đặt vũ khí ở tay phải, không che mắt hoặc miệng.

- `review.png`: vũ khí riêng, cầm trên mèo và ảnh thu nhỏ.
- `processed/spear.png`: PNG trong suốt, có padding 16 px.
- `processed/hero-spear.png`: ghép trên canvas 256 × 240 ở độ phân giải 3×.
- `native/godot-preview.png`: ảnh kiểm tra bằng Godot; bản 128 × 120 xuất ở `processed/hero-spear-128-godot.png`.
- `generation.json`: prompt, model và node từng lượt. Bản chọn: node `32:2` trong file thử `2uKzqvXeOSPQqfaow6s7TU`.

Tạo ảnh qua Figma `generate_image`, model `gpt-image-2.5-sunburst` đã được người dùng chọn; brief chữ dựa trên các ảnh đã quan sát. Tool này không nhận ảnh tham chiếu đầu vào. Giữ ba ảnh gốc. Xử lý sau sinh chỉ bỏ nền trắng, làm phẳng bảng màu và ghép thử; không tăng nét bằng dilation hay dựng lại biên giữa các vùng màu.

Mốc thiết kế nét chính là 9 px. Nét sinh có dao động cục bộ; cạnh thẳng cán đo được khoảng 8,2 px sau ghép, chưa chứng nhận mọi nét đúng 9 px. Đây là mẫu để người dùng đánh giá cách dùng nét, chưa tích hợp vào game.
