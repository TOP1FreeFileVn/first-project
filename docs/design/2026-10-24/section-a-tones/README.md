# Mẫu A: chia hai mảng sáng–tối

So sánh trực tiếp trên `Home.tscn` → `TroopsPage.gd` với bố cục hiện tại: hai thanh mẫu A, đội hình cố định và danh sách lính cuộn riêng.

- [Bảng so sánh](comparison.png): bên trái màu phẳng đã chọn, bên phải cách chia mảng sáng–tối đang duyệt.
- [A màu phẳng, nguyên trang](native/flat.png).
- [A sáng–tối, nguyên trang](native/two-tone.png).
- [Báo cáo ảnh và dữ liệu](native/review.json).

Hai bản dùng chung lề 28 px, chiều cao 52 px, viền nâu `#583f21` dày 4 px, góc bo 12 px, font game 26 px và chữ `#503c25`. Không có bóng. Bản sáng–tối chia ngang rõ ở 45% chiều cao, phía trên `#f8e4b7`, phía dưới `#e8c782`. Không thêm đường nét ở ranh giới giữa hai mảng.

Tương phản chữ với mảng trên đạt 8,33:1, với mảng dưới 6,42:1. Bản phẳng đạt 7,45:1. Hai ảnh giữ cùng pose, cảnh và vị trí UI để chỉ so sánh cách chia màu.

`MeadowSectionHeader.gd` mặc định vẫn dùng A phẳng `#f3d79b`; `two_tone = true` chỉ được bật ở RAM của scene duyệt này. Không ghi save hay đổi bảng màu đang áp dụng trong game.

Kiểm tra native 2026-10-24: 11 kiểm tra đạt, hai ảnh 450 × 800, không lỗi kiểm tra. Xác nhận bốn nút Ra trận/Nghỉ đã bỏ, cả hai thanh dùng component production, các rect đội hình/danh sách/vùng cuộn/bottom bar giống nhau giữa hai bản và không ghi save. `pixel-review.json` xác nhận ảnh phẳng cùng màu ở hai nửa, ảnh sáng–tối có đúng hai RGB thiết kế. Godot chỉ báo cảnh báo root certificate store đã tồn tại.

Tạo lại từ thư mục project:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File output/section-a-tones/run-preview.ps1
python docs/design/2026-10-24/section-a-tones/build_comparison.py
```
