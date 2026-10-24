# Đổi đội hình bằng kéo thả

Scene kiểm tra mở trực tiếp `Home.tscn` → `TroopsPage.gd` của game. Toàn bộ fixture ở RAM, `PlayerData.persist=false`, profile Godot tách biệt; hash save được so sánh trước/sau và dữ liệu RAM ban đầu được khôi phục.

Phạm vi kiểm tra:

- Hai thanh mục A: kem mật ong, chữ nâu, viền nâu chuẩn 4 px, lề trái/phải 28 px; bốn nút Ra trận/Nghỉ được bỏ.
- Game đang dùng bản A phẳng đã chọn. Bản chia mảng sáng–tối là phương án xem trước riêng, không được fixture này bật thay vào game.
- Bốn mèo vẫn chạy idle thật và đứng cố định. Chỉ danh sách thẻ lính cuộn.
- Kéo thẻ đã mở lên đúng mèo để thay bản thể; kéo mèo xuống danh sách để cho nghỉ; kéo lại vào ô trống để ra trận.
- Thả sai mèo, thẻ chưa mở, thả ngoài vùng hợp lệ, đội đã đủ và cho mèo cuối cùng nghỉ đều giữ đội hình hợp lệ.
- Bấm ngắn vẫn mở chi tiết. Vuốt nhanh trên danh sách dành cho cuộn; giữ rồi kéo dùng để thay đội hình.
- Kéo bản thể từ hàng cuối sau khi cuộn hết lên đúng mèo vẫn thay đội hình được; vị trí đội hình và vị trí cuộn được giữ nguyên sau cập nhật.

Runner gửi sự kiện `InputEventMouseButton`, `InputEventMouseMotion`, con lăn và `InputEventScreenTouch`/`InputEventScreenDrag` qua `Input.parse_input_event`, theo transform cửa sổ thực của Godot. Không gọi trực tiếp callback thả hoặc hàm thay đội hình để giả lập kéo thả.

Lượt kiểm tra cuối ngày 2026-10-24: **120 kiểm tra đạt, 10 ảnh native, không lỗi kiểm tra**, trên cả 360 × 640 và 450 × 800. Đã xác nhận chuột kéo thả sau cuộn, vuốt nhanh để cuộn trên màn cảm ứng và giữ 0,44 giây rồi kéo. Logic đội hình cũ vẫn ngăn thẻ khóa, sai mèo, vượt số chỗ và cho mèo cuối cùng nghỉ. Không ghi save người chơi. Godot chỉ có cảnh báo root certificate store vốn có, không có lỗi script/UI ở lượt cuối.

Ảnh mới:

- [Giao diện và nút đã bỏ, 450 × 800](native/troops-drag-ready_450x800.png)
- [Đang kéo vào đúng vị trí, 450 × 800](native/drag-valid-target_450x800.png)
- [Đã thay bản thể](native/troops-drag-replaced_450x800.png)
- [Cho một mèo nghỉ](native/troops-drag-benched_450x800.png)
- [Kết quả kéo bằng cảm ứng](native/troops-drag-touch-result_450x800.png)

Chạy từ project:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File output/troops-drag-preview/run-preview.ps1
```

Ảnh và số đo được ghi trong `native/`, báo cáo kiểm tra trong `native/review.json`.
