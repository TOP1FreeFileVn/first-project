# Nền độ hiếm của lính

Review dùng **Home/TroopsPage thật**, save được cách ly bằng profile APPDATA/LOCALAPPDATA riêng và `PlayerData.persist = false`.

Ảnh native 360 × 640:

- [Trước — Thành 1](before/starter_all_360x640.png)
- [Sau — Thành 1](starter_all_360x640.png)
- [Trước — Thành 6](before/late_all_360x640.png)
- [Sau — Thành 6](late_all_360x640.png)
- [Tên dài khi cuộn đến cuối](starter_all_scrolled_360x640.png)

Phần chân dung có nền màu theo độ hiếm: xanh lá / xanh dương / tím / cam. Khu vực tên, cấp và sao giữ nền kem. Các ô đội hình đã mở cũng dùng màu chân dung; ô chưa mở giữ màu trung tính. Badge trạng thái có nền kem riêng để nhận diện được trên màu mới.

Kết quả cuối sau chỉnh font: **24 ảnh native, 66 tuyến tương tác, 0 lỗi kiểm tra**. Cả bốn lệnh Godot thoát mã 0; chỉ có thông báo kho chứng chỉ Windows có sẵn từ trước.

Chữ trên trang thống nhất font **Paytone One**. Tên/cấp ở bộ sưu tập dùng 24 px design (12 px tại màn 360 px). Tên trong đội dùng 20 px design, riêng “Bình Thuốc” tự co còn 19 px để giữ một dòng và cấp không tràn khỏi ô. Bộ lọc “Huyền thoại” tự nhận chiều rộng 154 px design, đủ nội dung cùng khoảng đệm.

Phạm vi kiểm tra:

- Native 360 × 640 và 720 × 1280; Thành 1 đội 3/3 và Thành 6 đội 5/5; cả 5 bộ lọc.
- Bốn cột bằng nhau, không tràn ngang; tên đầy đủ, chân dung và cấp nằm trong thẻ.
- Tên và cấp trong ô đội hình nằm hoàn toàn trong ô, gồm trường hợp “Bình Thuốc” trong đội 5/5. Tên đội luôn một dòng.
- Font thật của Label/Button và khả năng hiển thị chữ tiếng Việt được ghi trong geometry JSON. Tất cả ký tự tiếng Việt xuất hiện đều có trong base font Paytone One, không cần fallback. [Tổng hợp font và ký tự](font-coverage.json).
- `TroopRarityField` và `TroopRarityBackground` nằm trong thẻ; chân dung nằm trong vùng màu, vùng màu kết thúc trước khu vực tên.
- Metadata độ hiếm của từng vùng màu khớp dữ liệu lính. Geometry JSON ghi đường dẫn SVG xanh lá / xanh dương / tím / cam đang dùng.
- Vùng màu vẫn hiện khi nút lính đang được nhấn; lính khóa giữ nền độ hiếm.
- Click bộ lọc phát âm thanh đúng một lần. Mở chi tiết, lên sao, nâng cấp và trừ vàng/thẻ đúng; đóng popup, cuộn danh sách, kéo đổi vị trí đội hình và kéo lính vào đội đều hoạt động bằng con trỏ thật.

Chạy lại: `node tools/review/mcp_ui_review.mjs docs/ui_review/2026-10-19/troops-rarity-plan.json`.

Fixture dùng chung `TroopsCompactReview.gd` với `output_dir` riêng; các ảnh/kết quả trong `troops-compact` được giữ nguyên. Hai ảnh baseline đã được sao chép và đối chiếu SHA256 trước khi chạy review nền màu mới. Ảnh trước khi thống nhất font nằm trong `font-before/`.

Plan chia theo trạng thái starter/late và kích thước 720/360 để mỗi lệnh MCP nằm trong giới hạn 15 giây. `manifest_<width>_<scenario>.json` là kết quả từng scene; `manifest_720.json` và `manifest_360.json` gộp theo kích thước; `manifest.json` gộp cả lần review.
