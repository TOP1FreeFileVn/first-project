# Kiếm V4 — bản duyệt

Giữ mẫu GPT Image 2.5 mà người dùng chấm **8/10** (lượt 2), sau đó tăng toàn bộ vũ khí từ 115 lên 175 px theo yêu cầu “cho vũ khí to ra để vừa với stroke mèo”. Mức tăng 52,2%; góc cầm đổi từ −50° sang −32° để giữ đầu kiếm trong canvas 256 × 240.

- [Bản duyệt trong Figma](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3606-2), trang `3539:2`.
- [Ảnh duyệt](sword-v4-review.png), [kiếm PNG trong suốt](processed/kiem-cropped.png), [mèo cầm kiếm](processed/unit_kiem.png).
- [128 × 120 qua Godot](processed/unit_kiem_128_godot.png), [ảnh kiểm tra bằng Godot](native/godot-preview.png), [kết quả](native/result.json).
- [Prompt mẫu đã chọn](prompt-iteration-2.txt), [lịch sử generation](generation.json), [thông số ghép](processing.json).

Ảnh được tạo qua Figma `generate_image`, model `gpt-image-2.5-sunburst`, trong draft do người dùng cho phép: `2uKzqvXeOSPQqfaow6s7TU`, node `6:2`. Brief dựa trên các nguồn đã xem; tool không nhận ảnh tham chiếu đầu vào. Lượt 3 đã chạy trước khi nhận đánh giá 8/10, chỉ lưu lịch sử và không thay mẫu được chọn.

Xử lý: tách nền trắng liên thông, chuẩn hóa năm mảng vật liệu; giữ đường bao do model tạo. Không dilation, không dựng lại hình bằng SVG. Cán nằm sau nét bàn chân; khuôn mặt, trang phục, màu mèo và rarity giữ nguyên. Asset sản xuất chưa thay.

Đã kiểm tra bằng Godot 4.7.2 Compatibility trên project thử độc lập: đọc PNG, tạo texture, thu 128 × 120 và chụp viewport. Không thay texture cache hay save của game chính. Kiếm không bị cắt khỏi canvas, mắt/miệng vẫn thấy rõ. Bản nét ban đầu nhỏ hơn lưu ở `sword-v4-before-enlarging.png`.

Tạo lại asset/board: `python -X utf8 -B docs/design/2026-10-19/weapon-redesign/v4-sword/prepare_review.py`.
