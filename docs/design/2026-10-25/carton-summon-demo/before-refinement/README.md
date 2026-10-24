# Demo triệu hồi bằng thùng carton — 25/10/2026

Demo tách riêng để duyệt kỹ hình dáng, bố cục và nhịp hoạt ảnh x1/x10 trước khi tích hợp. Thùng carton đáp xuống, hé dấu chân mèo, phát ánh sáng theo phẩm rồi giới thiệu đồng đội. Bản x10 cần đọc rõ cả nhóm thùng và từng lượt xuất hiện trên màn dọc nhỏ.

Màu carton ấm, mảng lớn, nét chính nâu bo tròn; nét phụ nhẹ hơn và theo vật liệu. Đường gấp có chức năng, ít dấu trang trí. Giữ nguyên hình mèo sản xuất. Ánh sáng nằm quanh thùng, làm rõ khoảnh khắc mở và sự khác nhau giữa các phẩm.

`CartonSummonDemo.tscn` và script cùng tên là scene riêng. Demo dùng kết quả định sẵn; không tiêu gem, phát thẻ hoặc đổi save của game. Runner đặt `APPDATA` và `LOCALAPPDATA` vào profile riêng trong `output/carton-summon-demo-review-profile/` và khôi phục biến môi trường sau khi chạy.

## Xem demo

Sau khi tạo ảnh, mở `preview.html` để chuyển x1/x10, phát lại GIF và kéo qua sáu mốc: thùng đến, đáp xuống, dấu chân mèo, ánh sáng, đồng đội xuất hiện, kết quả. Mỗi ảnh mốc có liên kết tới ảnh native gốc. Trang cũng có bản x10 ở 360×640 để kiểm tra độ rõ trên màn nhỏ.

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

Lượt native cuối đạt **72/72 kiểm tra** trên ba trường hợp: x1 ở 450×800,
x10 ở 450×800 và x10 ở 360×640. Mỗi trường hợp kiểm tra sáu ảnh mốc,
kết quả đủ số lượng, dữ liệu người chơi giữ nguyên, và thao tác chuột thật cho
Mở tất cả, Xem x1, Xem x10, Xem lại. Không có lỗi script hoặc polygon trong log.
Recording dùng **24 fps**: 135 khung cho x1, 323 khung cho mỗi bản x10.

Các tín hiệu âm thanh có trong bản native chạy tương tác; bản GIF không có âm thanh.
Khói dùng mảng liền thay cho các vòng tròn chồng nhau; cuối x10, cả mười thẻ
trượt về giữa màn hình. Ánh sáng màu chỉ bắt đầu sau khi bàn tay đã hé nắp.
Các bản review triệu hồi trước ngày 25/10 được giữ nguyên.
