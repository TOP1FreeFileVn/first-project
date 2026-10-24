# Đội hình trên đồng cỏ cạnh thành

Bản chụp dùng trực tiếp `Home.tscn` → `TroopsPage.gd` của game, không dựng một UI thay thế.

- Bỏ khung đội hình; bốn mèo đứng trên đồng cỏ trước thành carton dùng chung `CastleTiers.gd` với sảnh.
- Cảnh nền `FormationMeadow.gd` có trời xanh nhạt, hai cụm mây và các lớp đồng cỏ; phủ hết chiều ngang trang. `Home.gd` nối cùng màu trời sau HUD lên tận mép trên màn hình, không có khe hoặc dải nền họa tiết ngăn giữa.
- Cổng thành đặt giữa trang, dùng tỉ lệ đồng đều hai chiều để giữ đúng dáng thành. Tiêu đề, đội hình, thành và cỏ đứng cố định; chỉ danh sách bản thể bên dưới được cuộn.
- Bốn rig `SoldierRig` giữ animation idle đã có. Chạm mèo mở chi tiết; nút Ra trận/Nghỉ và roster bốn cột, mười sáu bản thể giữ nguyên.
- Hai thanh mục `ĐỘI HÌNH` và `LÍNH` thay tiêu đề rời, số 4/4 và chỉ số lực chiến góc phải cũ. Bản cuối dùng nền sage sáng `#d8e2bf`, đường mép moss `#849a6a` dày 3 px trên/dưới và chữ nâu `#493f2d`, tương phản khoảng 7,65:1. Giữ cấu trúc như thanh TRANG BỊ: cao 52, chữ 26, không outline hoặc bóng. Hai thanh phủ hết chiều ngang và đứng cố định khi cuộn roster.

Ảnh mới nhất:

- [360 × 640](native/formation-meadow_360x640.png)
- [450 × 800](native/formation-meadow_450x800.png)
- [Kết quả kiểm bố cục và màu cuối](native/visual-review.json)

Kiểm tra native sau lần đổi màu cuối ngày 2026-10-24: **60 kiểm tra đạt, 2 ảnh, không lỗi kiểm tra** trên hai kích thước. Đã kiểm màu nền, mép, chữ, chiều cao, căn giữa, độ phủ ngang; bố cục roster, đội hình, bottom bar, bỏ tiêu đề cũ và lực chiến; không ghi save. Kết quả lưu trong `native/visual-review.json`.

Trước bước đổi màu thanh mục, lượt kiểm tra tương tác đầy đủ đã đạt **132 kiểm tra, 6 ảnh, không lỗi** ở hai kích thước; giữ bằng chứng trong [review.json](native/review.json). Đã xác nhận bốn idle tiến thời gian và thay đổi pose; mở chi tiết/quay lại; Nghỉ/Ra trận; nền phủ ngang trang/cổng giữa trang; trời phủ từ y=0 sau HUD. Cuộn bằng sự kiện con lăn thật trong roster làm các thẻ di chuyển, trong khi bốn vị trí mèo, hai thanh mục và cảnh nền giữ nguyên; cuộn đến cuối danh sách vẫn giữ nguyên đội hình. Con lăn trên đội hình không cuộn roster. Không ghi save và khôi phục dữ liệu RAM ban đầu. Chỉ đổi palette sau lượt này, không đổi logic hoặc kích thước, nên không lặp lại toàn bộ tương tác.

Bằng chứng tương tác trước bước đổi màu (hai ảnh này còn thanh nâu cũ): [roster cuộn](native/formation-meadow-roster-scrolled_450x800.png), [một mèo nghỉ](native/formation-meadow-benched_450x800.png).

Nền đồng cỏ ở tọa độ game `(0,164,720,320)`, cổng thành tại x=360. Thanh ĐỘI HÌNH ở y=112–164, thanh LÍNH ở y=484–536; vùng cuộn roster bắt đầu y=536 và kết thúc ngay trước bottom bar y=1076. Phần trời sau HUD phủ `(0,0,720,112)`. Godot có cảnh báo root certificate store đã tồn tại, không có lỗi script hoặc UI trong lượt kiểm tra cuối.

Chạy lại từ thư mục project:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File output/formation-meadow-preview/run-preview.ps1
```

Chỉ chụp hai ảnh và kiểm bố cục, giữ nguyên báo cáo tương tác đầy đủ: thêm `-CaptureOnly` vào lệnh trên.

Runner và scene ở `output/formation-meadow-preview/`. Script chạy Godot 4.7.2 với profile APPDATA/LOCALAPPDATA tách biệt, `PlayerData.persist=false`, kiểm hash save trước/sau. Fixture chọn bốn mèo bản Carton, cấp thành đầu tiên mở đủ bốn slot; ảnh có một số bản thể chưa mở để xem cả trạng thái khóa.
