# Demo triệu hồi bằng thùng carton — 25/10/2026

Demo tách riêng để duyệt kỹ hình dáng, bố cục và nhịp hoạt ảnh x1/x10 trước khi tích hợp. Thùng carton đáp xuống, bàn tay mèo hé nắp, ánh sáng lên theo phẩm rồi đồng đội xuất hiện. Bản x10 cần đọc rõ cả nhóm thùng và từng lượt xuất hiện trên màn dọc nhỏ.

Màu carton ấm, mảng lớn, nét chính nâu bo tròn; nét phụ nhẹ hơn và theo vật liệu. Đường gấp có chức năng, ít dấu trang trí. Giữ nguyên hình mèo sản xuất. Ánh sáng nằm quanh thùng, làm rõ khoảnh khắc mở và sự khác nhau giữa các phẩm.

Phom bàn chân theo ảnh mẫu người dùng: lòng chân bầu như hình trứng, bốn ngón ngắn tụ thành vòm, bốn đệm nhỏ hình bầu dục đứng và đệm giữa hình mây ba múi. Viền nâu ấm nhẹ, đệm hồng nhạt; cổ chân ngắn, dày và nối liền vào lòng chân. Màu lông vẫn theo từng mèo.

Bàn tay có lòng bàn bè gọn, đầu ngón tròn và cẳng tay ngắn, dày hơn ở cổ tay. Chuyển động thăm dò, xoay nhẹ rồi bám nắp giữ cảm giác tay mèo con thay vì ngón dài trên một cổ tay mảnh.

Lượt chỉnh theo ảnh toàn bộ chân trước nối lòng bàn chân và cẳng tay thành một mảng lông liền, với một viền ngoài liên tục. Không có nét khép ngang cổ tay; ảnh so sánh giữ cả khung cổ tay lộ rõ và khung hộp mở để xem chỗ nối này.

`CartonSummonDemo.tscn` và script cùng tên là scene riêng. Demo dùng kết quả định sẵn; không tiêu gem, phát thẻ hoặc đổi save của game. Runner đặt `APPDATA` và `LOCALAPPDATA` vào profile riêng trong `output/carton-summon-demo-review-profile/` và khôi phục biến môi trường sau khi chạy.

## Xem demo

Sau khi tạo ảnh, mở `preview.html` để chuyển x1/x10, phát lại GIF và kéo qua sáu mốc: thùng đến, đáp xuống, bàn tay hé nắp, ánh sáng, đồng đội xuất hiện, kết quả. Mỗi ảnh mốc có liên kết tới ảnh native gốc. Trang cũng có bản x10 ở 360×640 để kiểm tra độ rõ trên màn nhỏ.

Từ thư mục dự án:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File docs/design/2026-10-25/carton-summon-demo/run.ps1 -Interactive -Count 10
```

Lệnh này mở cửa sổ Godot có âm thanh và các nút x1, x10, xem lại, mở tất cả. Dùng `-Count 1` để bắt đầu bằng một hộp hoặc `-Size 360x640` để xem ở màn nhỏ. Profile của cửa sổ này cũng tách riêng khỏi save game.

Để tạo lại ảnh và GIF:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File docs/design/2026-10-25/carton-summon-demo/run.ps1 -Record
python docs/design/2026-10-25/carton-summon-demo/build_preview.py
```

Runner chụp x1/x10 ở 450×800 và x10 ở 360×640, dùng GL compatibility, Dummy audio và cửa sổ ẩn. Mỗi bản chạy tối đa 55 giây. Thêm `-ImportAssets` nếu cần Godot nhập tài nguyên mới trước lượt đầu.

## Bằng chứng native

Ảnh gốc, log và `manifest-{count}-{size}.json` nằm trong `review/`. Manifest ghi kết quả kiểm tra, sáu mốc và thư mục recording cùng số khung hình/fps. GIF dùng palette chung được lấy từ recording native; bảng sáu mốc là bản thu nhỏ của ảnh gốc. `package.json` ánh xạ từng bản xem tới manifest nguồn.

Lượt native cuối của bản nối liền cổ tay đạt **84/84 kiểm tra**, mỗi trường hợp 28 kiểm tra: x1 ở 450×800, x10 ở 450×800 và x10 ở 360×640. Các kiểm tra bao gồm sáu ảnh mốc, kết quả đủ số lượng, dữ liệu người chơi giữ nguyên, nhịp sáng trước khi mèo xuất hiện, chuyển động bàn tay liên tục, và thao tác chuột thật cho Mở tất cả, Xem x1, Xem x10, Xem lại. Không có lỗi script hoặc polygon trong log.

Recording dùng **24 fps**: 193 khung cho x1 và 532 khung cho mỗi bản x10. Đồng hồ demo kéo dài 7,52 giây cho x1 và 21,64 giây cho x10; recording giữ thêm nửa giây ở kết quả cuối.

Các tín hiệu âm thanh có trong bản native chạy tương tác; bản GIF không có âm thanh.
Khói dùng mảng liền thay cho các vòng tròn chồng nhau; cuối x10, cả mười thẻ
trượt về giữa màn hình. Ánh sáng màu chỉ bắt đầu sau khi bàn tay đã hé nắp.
Các bản review triệu hồi trước ngày 25/10 được giữ nguyên.

## Duyệt riêng nhịp Huyền thoại

Trước lượt chỉnh bàn tay và nhịp vàng, ảnh native, manifest, GIF và storyboard đã được sao chép vào `before-refinement/` để đối chiếu.

`build_preview.py` đọc `gold-beat` trong manifest x10 450×800: `start`, `end`, `full_light_at`, `cat_visible_at` là giây trên cùng đồng hồ với recording; `rank` là 3. Bộ đóng gói cắt `paw-continuous-preview.gif` từ `start - 0,35` tới `end + 0,35`, giữ đúng fps nguồn và kẹp vào khoảng khung hình có sẵn. `package.json` ghi khoảng khung nguồn và khoảng thời gian vàng đầy trước khi mèo xuất hiện.

Khi chọn x10 450×800 trong gallery, phần Huyền thoại có clip riêng, ảnh `gold-anticipation`/`gold-open`, và liên kết GIF cũ. Mốc ảnh bổ sung không thay sáu mốc storyboard chính.

Nhịp mới tách rõ bàn tay thăm dò rồi bám nắp, ánh sáng lên đầy và giữ, nắp mở, hộp mở còn trống, rồi mèo mới từ từ lên. `gold-anticipation` chụp lúc ánh sáng vàng đang giữ; `gold-open` chụp hộp đã mở trước khi thấy mèo. Caption thời gian trong gallery đo từ lúc vàng lên đầy tới pixel mèo đầu tiên theo metadata, gồm cả nhịp mở nắp và chờ sau khi mở.

Khoảng vàng đầy tới pixel mèo đầu tiên đo được là **1,8126 giây ở x10** và **1,9805 giây ở x1**. Ở x10, vàng lên đầy lúc 17,82 giây, nắp bắt đầu mở lúc 18,74 giây và mèo bắt đầu lộ lúc 19,6326 giây.

`paw-continuous-comparison.png` đặt bàn chân trước và sau lượt nối liền cổ tay cạnh nhau, cùng vùng cắt `(110,280)–(340,520)` từ ảnh native 450×800, phóng 1,5 lần. Nguồn trước nằm trong `before-continuous-paw/gold-open.png`; nguồn sau là `review/gold-open.png` của lượt native cuối. `paw-continuous-wrist-comparison.png` bổ sung khung x1 ở 4,5 giây khi cổ tay lộ rõ: so `before-continuous-paw/wrist-open.png` với khung 108 trong recording x1 mới ở 24 fps. Gallery đặt ảnh cổ tay lộ rõ trước clip để kiểm tra đường nối.

Bộ đóng gói ghi nguồn, vùng cắt, tỷ lệ và khung thời gian trong `package.json`. Các tên `paw-reference-preview.gif`, `paw-reference-comparison.png`, `paw-comparison.png`, `gold-preview.gif` cùng các thư mục `before-*` vẫn giữ để đối chiếu lịch sử.
