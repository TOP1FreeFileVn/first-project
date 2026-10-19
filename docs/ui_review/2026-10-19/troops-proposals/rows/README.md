# Phương án B — danh sách dễ đọc

Đây là **phác thảo tĩnh**, tạo bằng scene review riêng. Không sửa UI đang dùng trong game; không ghi save người chơi. HUD và thanh điều hướng dùng nguyên Home hiện tại.

- Đội hình thành một cụm khoảng 100 px ở màn 360 px: giữ 5 ô, chân dung và cấp; bỏ tên dài bị xuống dòng. Tiêu đề, số ô 3/3 và sức mạnh chung cùng một hàng.
- Bộ sưu tập dùng một cột, mỗi hàng cao 92 px ở màn 360 px. Chân dung, tên, thông số và trạng thái có cột ổn định.
- Nền kem và chữ nâu; độ hiếm chỉ tô ở khung chân dung để các mảng xanh/tím/cam không tranh nhau. Lính khóa giữ hình mờ vừa đủ nhận dạng và điều kiện mở có chữ riêng.
- Tên dùng Paytone 14 px, nội dung dùng DejaVu Sans 12 px tại màn 360 px. Cả hai font đều đã có trong project; chữ nội dung bỏ viền để tránh dính nét.
- Đổi lại, số lính thấy cùng lúc thấp hơn lưới 2 cột: khoảng 2 hàng đầy đủ và phần lớn hàng thứ ba. Có ảnh cuộn để xem trạng thái khóa của Mèo Katana.

Ảnh render native:

- [360 × 640](rows_360x640.png)
- [720 × 1280](rows_720x1280.png)
- [360 × 640 sau khi cuộn](rows_360x640_scrolled.png)

Chạy: `node tools/review/mcp_ui_review.mjs docs/ui_review/2026-10-19/troops-proposals/rows-plan.json`.

Godot MCP chạy scene và thoát mã 0. Đây là kiểm tra render, không phải kiểm tra hành vi của thiết kế đề xuất. Log chỉ có cảnh báo kho chứng chỉ hệ điều hành đã xuất hiện ở các review trước.
