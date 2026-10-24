# Các lựa chọn thanh phân vùng Lính

Bốn mẫu là bản chụp trực tiếp Home → TroopsPage, chỉ thay hình thức hai thanh ở bộ nhớ để duyệt. Chưa áp dụng bảng màu hoặc dáng thanh nào vào game.

- Cùng chừa lề trái/phải 28 px ở thiết kế 720 px, tương đương 17,5 px trong ảnh 450 px.
- Giữ chiều cao 52 px, font game 26 px, chữ căn giữa. Viền chính nâu đậm `#583f21`, dày 4 px theo `Ui.menu_tag()` của game; góc bo 12 px, không bóng. Ở ảnh 450 px, viền dày 2,5 px.
- Giữ thành, bốn mèo idle, bầu trời, thẻ lính và bottom bar. Đội hình cố định, chỉ danh sách thẻ cuộn.
- A: kem mật ong. B: xanh lam. C: đào đất. D: tím khói.

[So sánh bốn mẫu](comparison.png). Ảnh nguyên trang: [A](native/A.png), [B](native/B.png), [C](native/C.png), [D](native/D.png).

[Bản trước khi thêm stroke chuẩn](comparison-thin-stroke.png) giữ lại để đối chiếu.

Màu, tỷ lệ tương phản chữ/nền và lề nằm trong `palette-comparison.json`. Cả bốn đạt ít nhất 4,5:1 cho chữ. Mẫu B ưu tiên phân vùng rõ trên nền cỏ; mẫu A nhẹ hơn và gần tông carton.

Đã chụp đủ bốn ảnh 450 × 800 bằng Godot: 26 kiểm tra đạt, không lỗi kiểm tra. Hai thanh có lề cân 28 px, giữ nguyên vị trí mèo, thành, vùng cuộn, nút và bottom bar. `native/options.json` lưu số đo, màu, kiểm tra và xác nhận không ghi save.

Tạo lại bảng so sánh sau khi chụp bằng runner trong `output/troops-section-options/`:

```powershell
python docs/design/2026-10-24/troops-section-options/build_comparison.py
```
