# Mèo anh hùng — bộ trang bị v3

Làm lại trọn bộ theo hướng stroke của mẫu thương được chấm 9/10 ngày 20/10/2026. UI hiện chỉ được người dùng đánh giá 5–6/10; bảng này duyệt artwork trang bị, không chốt chất lượng UI.

## Ngôn ngữ chung

Thép sáng với hai diện màu phẳng, đồng vàng mật ong, da đỏ trầm và điểm xanh từ áo choàng gốc. Viền chính nâu ấm, mục tiêu 9 px trên canvas 256 × 240; nét bề mặt nhẹ hơn, theo vật liệu. Chỉ dùng nét ở chỗ thật sự mô tả tiếp giáp/cấu tạo, không bao viền từng mảng màu. Không dựng lại biên phân vùng hoặc dùng dilation. Giữ ảnh sinh gốc và prompt.

## Trọn bộ

- Mũ thép tai mèo: dáng rộng thấp, mặt mở, đai đồng, không che lông mày.
- Giáp ngực: tấm chính rộng, cổ khoét sâu, hai vai gọn và đai đồng; tránh các vòng viền lồng nhau.
- Găng: một dáng găng tròn, ghép cặp đối xứng quanh hai điểm tay cố định.
- Giày: một dáng giày ngắn mũi rộng, ghép cặp cùng mặt sàn.
- Bùa: mặt nhỏ hình giọt/khiên, điểm xanh ngọc, dây đơn giản; không lấp kín ngực.
- Cận chiến: kiếm ngắn bản rộng, guard đồng, chuôi da.
- Tầm xa: cung cầm sẵn, dây mảnh, khoảng hở đọc rõ.
- Phép: trượng ngọc xanh, đầu tinh thể rõ, đế đồng liền và cán có điểm tựa.
- Nặng: rìu lưỡi rộng có móc gót, hai mặt thép không kẻ đường chia. Mẫu thương đã duyệt là chuẩn tham khảo nét.

## Chỉnh sau phản hồi

Người dùng nhận xét cung và gậy chưa đạt, rồi yêu cầu thử màu sáng hơn 10%. Bộ mới tăng các giá trị RGB của mảng màu trang bị theo hệ số 1.10 (giới hạn 255), giữ viền nâu và mèo gốc. Bảng `tone-plus-10-review.png` so sánh đúng cùng artwork trước/sau thay màu.

Ảnh sinh giữ làm nguồn ý tưởng. Với cung, trượng và rìu, prompt không giữ được nét khi thu nhỏ; phần vector được tác giả chỉnh Bézier cùng tỉ lệ fill và khoảng hở, ghi rõ trong provenance. Đây không phải dilation tự động hoặc dựng biên từ phân vùng ảnh. Không mô tả các bản refinement này là ảnh AI nguyên bản.

Năm lớp đồ dùng chung vị trí ở bốn pose; điểm tay trái (94,166), phải (160,166), giày gần (84,216)/(172,216). Thân, mặt, màu lông và áo choàng không đổi. Bốn pose là bốn cách cầm theo họ vũ khí, chưa phải animation hoàn chỉnh.

Xuất PNG trong suốt từng món, lớp đeo giữ canvas đăng ký, bốn mèo cầm vũ khí, ảnh thực 128 × 120, bảng so sánh bộ cũ/bộ mới và ảnh kiểm tra Godot. Đặt bảng tổng vào trang Figma 3539:2.
