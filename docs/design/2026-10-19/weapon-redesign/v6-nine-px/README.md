# Mèo và kiếm — cùng viền 9 px

Yêu cầu mới nhất: “cho cả 2 lên đồng 9px đi”. Bản này thay thế bản thử viền mèo 6,22 px. Chỉ cập nhật đề xuất; asset game chính chưa thay.

- [Figma duyệt](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3606-2), trang `3539:2`.
- [Bảng duyệt](nine-px-review.png), [mèo cầm kiếm](processed/unit_kiem.png), [kiếm rời](processed/kiem-cropped.png).
- [Số đo](measurement.json), [xử lý](processing.json), [Godot](native/godot-preview.png).

Đích 9 px ở canvas 256 × 240, tương ứng 4,5 px khi thu 128 × 120. Đo thân kiếm: 8,99968 px; nét đỉnh mũ sau Godot: 9,01152 px. Sai lệch 0,01184 px do lấy mẫu và khử răng cưa. Nét chia vật liệu bên trong không bị đồng nhất thành nét ngoài.

Mèo giữ nguyên đường hình gốc, thay độ dày viền nâu thành 9. Đuôi dùng nét nền 31 bên dưới nét màu 13 để mỗi phía có viền 9. Kiếm giữ các mảng vật liệu của mẫu GPT được chấm 8/10, chuẩn hóa viền ngoài bằng offset tròn Euclidean từ biên fill; loại các mảnh fringe nhỏ ngoài nét. Scale cố định `175/984`, góc −32°, điểm cầm (160,166); không fit lại theo bbox đã dày lên.

Đã mở ảnh render Godot và ảnh Figma để kiểm tra đầu kiếm, khoảng trống, điểm nắm, mặt và ảnh thu nhỏ. Không phát sinh generation AI mới ở lượt sửa nét này.

Tạo lại: chạy `build_review.py --prepare`, Godot `native/render_sources.gd`, rồi `build_review.py`. Chạy `native/verify.gd` trong project thử độc lập để xuất ảnh kiểm tra.
