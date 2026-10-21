# Đề xuất thay hình dáng và bố cục khung menu

Ngày: 21/10/2026. Bản B đã được duyệt và triển khai vào game. Các PNG ở đây giữ lại bản đề xuất; [ảnh chụp Godot sau triển khai](../../../ui_review/2026-10-21/menu-frame-rollout/README.md) là kết quả thực tế.

## Xem thiết kế

- [So sánh hiện tại / A / B](proposal.png): ảnh hiện tại là capture game; A/B là bản dựng đề xuất riêng.
- [Bản B đã chỉnh font và button](proposal-b.png): hướng người dùng chọn; [ảnh màn hình riêng](patrol-b.png).
- [Preview HTML](preview.html): có nút thử palette ở các khung mẫu phía dưới. Chưa kiểm tra bằng trình duyệt; PNG đã được render offline và kiểm tra trực quan.
- [Sprite khung Cat Gunner gốc](cat-gunner-frame-sources.png).
- [Ảnh quảng bá Merge & Upgrade chính thức](cat-gunner-official-merge-upgrade.webp).

## Quan sát từ Cat Gunner

Bộ RE là **Cat Gunner 1.1.64**, package `com.Chodun.CatGunner`. Có thể kiểm chứng hình dáng từng sprite: góc bo mềm, viền nâu, một số mặt khung có gờ đáy nhẹ; khung tính năng màu có thể dùng viền trắng. File `sources.json` lưu 18 đường dẫn gốc, kích thước và SHA-256. Bộ export không có ảnh runtime hay cây scene/prefab đủ để xác nhận cách ghép tất cả menu.

Ảnh quảng bá trên [Google Play](https://play.google.com/store/apps/details?id=com.Chodun.CatGunner&hl=en), xem ngày 21/10/2026, cho thấy lưới ô trang bị đều: hình vũ khí ở giữa, cấp ở góc trên trái, mỗi ô có một viền bo nâu. Hiệu ứng phát sáng được dùng để nhấn nhóm ô trong ảnh quảng bá. Đây là bằng chứng quảng bá hiện tại, không phải ảnh runtime của bản RE 1.1.64. Thông tin nguồn file tải được lưu trong `web-source.json`.

## Đề xuất cho game mình

**Người dùng chọn B:** cảnh mèo riêng, nhãn nhỏ bám mép trên khung thông tin. Các dòng bên trong chia bằng khoảng cách hoặc vạch mảnh. Số liệu quan trọng lớn hơn, hành động phụ giảm độ nổi. A chỉ giữ để đối chiếu.

**Giữ button gốc và font game:** art lấy trực tiếp từ `game/ui/skin/btn_yellow.svg` và `btn_red.svg`, cùng trạng thái nhấn tương ứng trong HTML. Chữ dùng Paytone One, DejaVu Sans chỉ dự phòng ký hiệu như trong game. Không dùng Arial hay tăng đậm giả.

Đã sửa lỗi quy đổi stroke trong bản duyệt: viền chữ đo từ capture gốc khoảng **1 px ở màn rộng 360 px**. Renderer Pillow dùng bán kính viền ngoài 1 px; CSS dùng `-webkit-text-stroke: 2px` với `paint-order: stroke fill`, giữ phần ngoài khoảng 1 px. Không quy đổi trực tiếp `outline_size = 7` trong theme thành bán kính stroke 3,5 px của Pillow. Bản sai đã tạo lượng viền tối tương đối lớn hơn khoảng 4 lần ảnh gốc.

| Khu vực | Hình khung và cách bố trí đề xuất |
| --- | --- |
| Tuần tra | B: cảnh mèo ở khung riêng phía trên; Kho vàng có nhãn bám mép, số liệu và Thu hoạch trong cùng khung; Tuần tra nhanh là hàng phụ bên dưới. |
| Shop | Theo ảnh tham chiếu được duyệt tiếp: rương Vàng nổi bật toàn chiều ngang; rương Gỗ/Bạc hai cột bằng nhau, giá và nút chung hàng; đổi kim cương phía dưới. Giữ các loại rương và giá hiện có. |
| Thành / xưởng | Một khung cho một nhóm chức năng; các chỉ số và hàng nâng cấp chia bằng khoảng cách/vạch mảnh. |
| Anh hùng | Khung nhóm thông tin gọn; các ô trang bị có cùng kích thước. Giữ màu độ hiếm riêng của từng ô. |
| Lính | Giữ lưới 4 cột đã duyệt; không thêm nền lớn hoặc khung lồng quanh mỗi hàng. Chi tiết dùng popup B. |
| Sự kiện | Thẻ sự kiện có một mặt màu và một viền ngoài; phần thưởng, thời gian, nút được gom trong thẻ. |

Ở bề rộng 360 px, mẫu dùng lề ngoài 12 px, bo khung chính 22 px, nét ngoài 3 px, gờ đáy 4 px. Khung phụ giảm độ tương phản. Button dùng 9-slice gốc L40/T33/R40/B36 ở canvas 720 px, tương ứng L20/T16,5/R20/B18 ở preview 360 px. Các thông số khung mới là đề xuất, cần kiểm tra lại ở runtime khi triển khai. Không thêm mảng trắng lớn, sóng trang trí, hay đổi art thẻ độ hiếm trong đợt này.

## Dựng lại và kiểm tra

`build_reference.py` tạo contact sheet từ bộ RE tại đường dẫn được ghi trong script.

`render_icon.gd` chuyển icon rương, icon quay lại và hai mặt button SVG hiện có thành PNG cho renderer offline:

```powershell
& 'C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://docs/design/2026-10-21/menu-frame-proposal/render_icon.gd
& 'C:/Users/dangp/AppData/Local/Programs/Python/Python312/python.exe' docs/design/2026-10-21/menu-frame-proposal/build_proposal.py
```

Renderer dùng Pillow, font Paytone One của game, DejaVu Sans chỉ cho ký hiệu dự phòng. Header/navbar được cắt từ capture Tuần tra hiện tại; mèo, icon và button dùng asset của game. Hình khung A/B được dựng riêng. Đã kiểm tra PNG sau khi sửa vùng cắt cảnh mèo, đối chiếu viền chữ button với capture gốc và kiểm tra số liệu kho vàng. HTML chưa được QA trong trình duyệt.
