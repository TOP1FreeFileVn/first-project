# Mũ và giày — bản thử ngày 22/10/2026

Người dùng chấm áo giáp 6/10, yêu cầu làm tiếp giày và mũ để xem. Đây là đề xuất riêng, chưa thay asset trong game; điểm 6/10 không được xem là duyệt cả bộ để tích hợp.

Thiết kế cùng họ thép bạc với áo, giữ diện màu rộng. Mũ là vòm sắt có chỗ cho hai tai và hai tấm che bên mặt, không phải băng trán cũ. Giày đi theo đôi, có cổ hở, mũi tròn và đế rõ; đứng thẳng, không xoay 45 độ. Cả hai chỉ cộng chỉ số, không mặc lên mèo.

Hai màu fill `#d9e0e8` / `#a8b4c7`; nét chính `#583f21`, nét phụ `#9b7f58`. Không vàng/cam, đá quý, đường trang trí mảnh, gradient hoặc bóng. Tách mảng vật liệu bằng fill, không bao từng mảng bằng nét.

Profile icon 256 px tiếp nối mẫu áo mới nhất: main **11.35 px**, secondary **7.41 px**. Đây là profile của bản thử icon, không thay mốc 9 px cho vũ khí cầm trên canvas mèo. Viền hình và mép hở dùng main; đường ghép mặt mũ và nét cấu tạo nhỏ dùng secondary. Đường sau vật thể trước được che, không nhân đôi mép chung.

Tham khảo đã xem: [KingEquip trong Figma](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3443-119), đặc biệt cách gom họ màu của Armor0113 và Boots0113. Ảnh xem tại `../armor-canvas/figma-equipment-reference.png`; giữ các mức bạc cùng họ, không sao chép hoa văn hoặc thêm nhiều chất liệu. Nguồn `helmet.js` / `boots.js` dùng chung path cho Canvas và SVG.

`preview.html`: so sánh cũ/mới cùng kích thước và phân cấp nét. `round-*.png`: kiểm tra Canvas. `export.mjs`: xuất SVG. `godot/`: PNG kiểm tra renderer game ở 32/48/64/96/256 px. `review.png`: bảng hai mẫu để duyệt.

Kiểm tra Canvas vòng 1: lỗ mặt mũ quá thấp/bé, giày loe sang cả hai phía nên dễ đọc như bình. Vòng 2 tăng khoảng hở mặt mũ, đưa gót giày thẳng hơn và làm rõ mũi giày; giữ nguyên bảng màu và độ dày nét. Không xem việc xuất file thành công là đã đạt yêu cầu mỹ thuật.

Đã mở và kiểm tra `round-2.png`, PNG Godot của hai món, bản phân vai nét và `review.png` với icon 32/48/64/96 px. Không cắt viền; lỗ mặt/cổ giày đọc được; đường ghép còn phân biệt với viền ngoài. Ở mũ 256 px, scan lõi màu tại mép trái y=180 cho 10 px main và tại đường ghép y=80 cho 6 px secondary; ở 96 px tương ứng 3/2 px. Đây là số pixel lõi theo ngưỡng màu (không gồm toàn bộ antialias), không thay thông số nét nguồn 11.35/7.41. Hai món dùng cùng tỉ lệ icon .78 như giáp; nét nguồn không bị thêm transform lệch trục. Godot xuất đủ 12 biến thể thành công; log chỉ có lỗi đọc kho chứng chỉ hệ điều hành đã biết, không ảnh hưởng render SVG local.

Người dùng nhận xét trông ổn và yêu cầu giày theo đôi, đồng thời củng cố skill. Bản mới trong `boots.js` dựng hai chiếc ở kích thước cuối bằng translation, giữ 11.35/7.41 px; không scale từng chiếc khiến nét bị mỏng. `round-3-pair.png` là kiểm tra Canvas mới. `boots-single.js`, `review-single.png` và vòng 2 giữ bản giày đơn để đối chiếu. `review.png` hiện là bản mũ + đôi giày; skill dùng ảnh này làm hướng đang phát triển, không nâng điểm áo giáp 6/10 thành duyệt hoàn toàn.
