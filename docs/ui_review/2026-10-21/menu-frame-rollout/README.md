# Khung menu B trong game

Triển khai ngày 21/10/2026 theo phương án B đã duyệt: một viền nâu bo mềm, gờ đáy nông, nhãn nhỏ bám mép khung; màu nền theo từng menu. Giữ button gốc, font Paytone One và thông số viền chữ trong theme.

- [Shop](shop_720x1280.png): rương Vàng là banner ngang; rương Gỗ/Bạc hai cột đều; [đổi kim cương](shop-exchange_720x1280.png) phía dưới. Nội dung và giá lấy từ Economy hiện có. [Popup tỉ lệ](shop-rates_360x640.png) thay cho dòng dài đầu trang.
- [Anh hùng](hero_360x640.png), [Lính](troops_360x640.png), [Thành](castle_360x640.png), [Xưởng](castle-workshop_360x640.png).
- [Sự kiện](events_360x640.png), [Tuần tra](patrol_360x640.png), [Triệu hồi](summon_360x640.png).
- [Quà 7 ngày](login_360x640.png), [Nhiệm vụ](quests_360x640.png), [Hồ sơ](profile_360x640.png), [Cài đặt](settings_360x640.png), [chi tiết trang bị](hero-detail_360x640.png).
- [Tổng quan](contact-sheet.png).

Kiểm tra bằng Godot 4.7.2, render native D3D12 ở 720×1280 và 360×640: **921 kiểm tra, 40 ảnh chụp, 0 lỗi**. [Manifest](manifest.json) lưu kết quả và hình học khung. Fixture dùng profile riêng trong workspace và `PlayerData.persist = false`.

Các luồng đã kiểm tra: điều hướng menu, mở/đóng popup, bấm ngoài popup, bấm nhãn và vùng trống trong khung, cuộn nội dung dài, đổi tiền, nhận quà ngày, thu hoạch/tuần tra nhanh, nâng thành, đổi tên và cài đặt. Kiểm tra thêm vị trí khung/nút đóng trong viewport, hai cột Shop bằng nhau, baseline nút mở, font và texture button gốc. Combat vẫn dùng background và khung riêng.

Lưới Lính còn được kiểm tra riêng ở 360×640: 33 luồng, 12 ảnh, 0 lỗi, gồm bộ lọc, nâng cấp, đóng chi tiết, kéo và đổi đội.

Nguồn dựng: `tools/ui/make_menu_panels.py`; bố cục chung: `game/ui/MenuSection.gd`, `Ui.menu_section`, `UiKit._menu_popup`. Chạy lại bằng scene `res://tests/ui_review/MenuFrameRollout.tscn` với APPDATA/LOCALAPPDATA trỏ vào một profile test trong workspace.
