# Chiến lược làm lại nét trang bị — 22/10/2026

Người dùng đánh giá kiếm đã đạt, các món còn lại chưa tuân theo skill vì stroke chính lộn xộn. Đây là kế hoạch sửa nguồn thiết kế và bước kiểm tra. Chưa thay artwork production.

Cập nhật cùng ngày: đã thống nhất contract **hai loại stroke: chính và phụ** trong skill repo, bản skill đang cài và hướng dẫn Canvas; template đã có profile chính/phụ riêng cho hình cầm và icon, bù độ dày theo phép fit. Đã bỏ công thức tỷ lệ nét phụ cứng và sửa thông tin slot/trạng thái tích hợp lỗi thời. Phần artwork trong kế hoạch dưới đây vẫn cần làm lại và duyệt thực tế.

## Phạm vi và mốc đối chiếu

- Giữ kiếm đang dùng làm chuẩn về trọng lượng nét trong cùng ô và trên cùng con mèo. Lưu nguồn/hash của nó trước khi làm mẫu mới.
- Đối chiếu thêm mẫu thương được chấm 9/10 để phân biệt viền chính, nét bề mặt và mảng vật liệu.
- Ưu tiên trang bị anh hùng hiện tại: cung, trượng, rìu, katana; mũ, giáp, giày. Bốn slot vẫn là weapon/helmet/armor/boots. Găng và bùa là dữ liệu lịch sử.
- Chỉ vũ khí xuất hiện trên mèo; mũ/giáp/giày là icon cộng chỉ số. Giữ mèo, khuôn mặt, áo choàng và các điểm tay.
- Pilot kiếm Canvas ngày 21/10 là tham khảo quy trình vector. Nó có hình khác kiếm raster production; không coi hai bản là cùng một nguồn hoặc tự thay kiếm đang đạt.

## Những lỗi đã tìm thấy

1. **Nhiều nguồn thiết kế:** bộ hero ghép kiếm raster, cung/trượng SVG v4, rìu từ v3, các món stat-only từ nguồn khác. Cùng ghi 9 px ở nguồn không bảo đảm cùng độ dày sau các phép fit.
2. **Fit icon chỉ căn hình:** `tools/ui/install_equipment_art.py::equipment_icons()` xoay, crop alpha và fit từng món vào inset 8%. Nó giữ nguyên nét nguồn, chưa kiểm tra nét theo chức năng hoặc trọng lượng khi hiển thị. Các vật thể có tỷ lệ và nét nguồn khác nhau sẽ lệch sau fit.
3. **Các điểm nối chưa được giải quyết:** đầu cung, khung ngọc–cổ trượng, chỗ lưỡi rìu gặp cán và chắn tay katana gom thành khối nâu; vùng màu sáng bị bó hẹp. Giày có dải nâu cổ/đế quá mạnh. Mũ cần làm gọn chỗ tai gặp vành. Giáp có nhiều ranh giới màu đang đúng và cần chỉnh ít hơn.
4. **Nguồn vũ khí lính cũ còn dilation:** `docs/design/2026-10-19/weapon-rollout/build_review.py` nở các vùng fill phân loại rồi tô viền. Installer còn lấy phần lớn vũ khí lính từ đó. Đây là nhánh riêng với bộ hero; cần ngừng dùng bước đó cho các bản làm lại.
5. **Hướng dẫn lệch phiên bản:** skill trong repo có Canvas-first, bản cài `.codex/skills` thiếu đoạn này. Skill Canvas còn quy định cứng nét phụ theo tỷ lệ .45–.5 của nét chính, trong khi stroke contract yêu cầu chọn theo chức năng/vật liệu và giữ dây cung 3 px. Cần thống nhất hướng dẫn trước đợt sản xuất.

Một dấu hiệu về phép fit: từ kích thước nguồn và transform, ở biến thể 96 px nét cung/trượng/rìu ước khoảng 5.3/5.7/4.9 px, trong khi lát cắt nét giày đã ghi nhận ở nguồn cho ước lượng khoảng 11 px. Đây là **ước lượng từ transform, chưa phải đo raster cuối**, không dùng làm chứng nhận chất lượng.

## Quy tắc áp dụng cho từng món

| Loại đường/vùng | Cách xử lý |
| --- | --- |
| Silhouette, kể cả mép lỗ hở ra nền | Nét chính nâu `#583f21`, đầu và góc tròn. |
| Cạnh chồng lấp quyết định hình khối | Có thể dùng nét chính; chỉ vẽ cạnh nhìn thấy, giải quyết cạnh chung một lần. |
| Quấn cán, đường may, đai nhỏ, trang trí | Nét phụ theo vật liệu, nhẹ hơn nét chính; không áp một màu hay tỷ lệ cứng cho mọi món. |
| Hai mặt thép, phần gỗ/kim loại/da đã phân biệt rõ | Mảng màu phẳng; không tự thêm đường viền. |
| Dây cung | Nét phụ liên tục, mục tiêu 3 px trên canvas hero 256 × 240; kiểm tra còn thấy ở 128 × 120. |

Vũ khí cầm có mục tiêu nét chính **9 px sau khi đặt lên canvas mèo 256 × 240**. Nếu nhóm hình còn scale, phải tính bề dày hiệu dụng sau scale rồi đo lại đoạn thẳng xa góc/nút giao. Ghi số đo thực tế; không chứng nhận mọi đường đều 9 px từ thuộc tính `stroke-width`.

Icon độc lập cần hiệu chỉnh nét theo kiếm ở **cùng kích thước hiển thị**, thay vì phóng cả nét của ảnh cầm cho đầy ô. Dùng chung cấu trúc hình, cho phép profile kích thước/nét riêng giữa icon và hình cầm. Không dùng dilation toàn ảnh để sửa độ dày.

## Thứ tự làm lại

| Đợt | Món | Thay đổi cần thấy |
| --- | --- | --- |
| 1 — mẫu kiểm chứng | Cung và trượng | Cung có thân cong liền, hai đầu gọn, khe dây thoáng; giữ dây phụ hiện có. Trượng có ngọc–đế–cán đồng trục, vùng gỗ rộng, cổ nối rõ thay cho khối nâu đặc. |
| 2 | Rìu và katana | Xử lý lưỡi–cán rìu bằng che khuất đúng lớp. Katana giữ dáng đã giảm cong, tăng vùng lưỡi sáng và tách rõ chắn tay/chuôi. |
| 3 | Giày và mũ, sau đó giáp | Giày giữ hướng thẳng, giảm lực đường cổ/đế. Mũ giữ tai mèo, gọn điểm nối. Giáp chỉ sửa cổ/nách và trọng lượng nét; giữ các mảng màu không viền đang tốt. |
| Mở rộng sau bộ hero | Kho vũ khí lính | Rà từng nguồn cũ, thay phần chưa đạt theo cùng contract; không coi việc sửa icon hero là đã sửa sprite lính. |

## Quy trình mỗi mẫu

1. Chụp bản hiện tại cạnh kiếm, ở đúng ô trang bị và kích thước mèo cầm. Chốt silhouette, vật liệu, khoảng hở và pose.
2. Làm sơ đồ vai trò đường: viền ngoài/lỗ hở, cạnh chồng, nét phụ, mảng fill. Sơ đồ này phải có trước bước hoàn thiện nét.
3. Với vector: vẽ trên Canvas, xem ảnh, sửa hình và điểm nối; xuất SVG từ đúng dữ liệu path đã xem. Với concept raster: giữ ảnh gốc/prompt, chỉ cleanup bảo toàn hình, không tái tạo nét bằng nở biên toàn cục.
4. Kiểm tra hình cầm trên mèo gốc: cung tay trái (94,166), các vũ khí còn lại tay phải (160,166); che cán bằng lòng bàn tay và paw đúng lớp. Không đổi pose cầm theo góc icon.
5. Xuất icon có safe inset và căn quang học. Vũ khí theo hướng 45° đã chốt; mũ/giáp/giày giữ thẳng. Kiểm tra biến thể 32/48/64/96 px và ảnh mèo 128 × 120.
6. Render bằng Godot, mở ảnh kiểm tra: nét chính đều về trọng lượng; không có nút nâu đặc, khe bị lấp, nét đôi hay đường phụ biến mất. Đo vài đoạn đại diện và ghi cả transform.
7. Đưa bảng trước/sau cùng kích thước, kèm hình cầm và icon trong ô thật. Mẫu đạt mới được mở rộng sang món tiếp theo và tích hợp source, export, runtime cùng nhau.

## Sửa pipeline trước khi triển khai diện rộng

- Thống nhất stroke contract trong bản skill repo, bản cài và hướng dẫn Canvas; loại quy định nét phụ cứng và cập nhật trạng thái các mẫu đã tích hợp. Đồng bộ bản cài là công việc riêng theo quyền ghi của môi trường.
- Một nguồn thiết kế được chọn cho mỗi món; các bản xuất dùng lại nguồn đó, không âm thầm quay về v3/v4 cũ.
- Bổ sung vào manifest: nguồn được chọn, vai trò đường, mục tiêu/đo nét sau fit, profile icon/held, ảnh Godot và trạng thái duyệt. Hash/alpha bounds/góc xoay không thay thế kiểm tra mỹ thuật.
- Kiểm thử kỹ thuật tiếp tục kiểm đường dẫn asset, transparency, bounds và socket; tiêu chí nét cần ảnh đối chiếu và người xem.

Tài liệu chuẩn: [stroke contract](../../../../tools/skills/casual-weapon-design/references/internal-strokes.md), [mẫu thương](../../../../tools/skills/casual-weapon-design/references/accepted-spear.md), [Canvas-first](../../../../tools/skills/casual-weapon-design/references/canvas-first.md).
