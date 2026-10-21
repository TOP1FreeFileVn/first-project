# Bottom navigation: tham khảo tương tác

Ngày xem: 2026-10-21.

## Trạng thái duyệt

Người dùng không duyệt cả ba phương án A/B/C. Yêu cầu tiếp theo là học cách tab phản hồi khi được chọn, rồi chờ chỉ dẫn. Chưa có phương án hình dáng, kích thước hay chuyển động mới nào được duyệt. Ghi chú này không thay đổi UI trong game.

## Nguồn online đã xem

1. [Clash Royale — Main menu, Interface In Game](https://interfaceingame.com/screenshots/clash-royale-main-menu/).
   - Ảnh giao diện game do thư viện bên thứ ba lưu; bản game và ngày chụp không rõ.
   - Tab Battle đang chọn rộng hơn, icon nổi cao và có tên dưới icon; các tab khác hẹp hơn.
   - Đây là ảnh tĩnh: không dùng để kết luận easing, thời lượng, animation nhấn hay cách chuyển trang.
2. [PixelToons — Tab bar animation: Mobile Gaming App](https://dribbble.com/shots/21628756-Tab-bar-animation-Mobile-Gaming-App).
   - Concept animation, không phải bằng chứng runtime của một game phát hành.
   - Đã mở player và quan sát các trạng thái Stream/Wallet: icon và tên tab được nhấn mạnh; các hàng mẫu còn dùng vạch hoặc vùng nền để thể hiện lựa chọn.
   - Clip dài khoảng 10,87 giây; đây là thời lượng toàn clip, không phải thời lượng một lần chuyển tab.
   - Chỉ học cách phối hợp nhiều thành phần trong phản hồi; màu xanh kính và icon nét đơn không phải đề xuất style cho game mèo.
3. [Abron Studio — Tab Bar Micro Interaction](https://dribbble.com/shots/24724129-Tab-Bar-Micro-Interaction).
   - Đã kiểm tra player; nội dung là slider giới thiệu tính năng web Hazar, không phù hợp làm bằng chứng bottom nav của game. Không dùng để chốt thiết kế.

## Đối chiếu mã client có sẵn

GearPaw Defenders! 0.17.0, package `com.gearpaw.defenders.td.game`.

Gốc local: `C:/Users/dangp/OneDrive/Documents/first-project/reverse_engineering/GearPaw_0.17.0/ExportedProject/Assets/`.

- `RecoveredLuaSource/app/ui/main_city/cell/bottom_btn_cell.lua:25`: ô chọn rộng thêm 70 đơn vị UI, bật nền chọn và tên; icon đổi Y từ 5 sang 45.
- Cùng file, hàm chọn/rời ở khoảng dòng 65–88: mới chọn chạy Spine `born1`; vừa bỏ chọn chạy `born2`, rồi về `idle`.
- `RecoveredLuaSource/app/ui/main_city/main_city_ui.lua:453`: click phát `UI_SWITCH`; có asset `arts/sounds/sfx/ui/ui_btn_switch.wav`.
- Cùng file, khoảng dòng 644–674: bật/tắt và refresh nội dung. Đoạn này không chứng minh có tween trượt trang.

Phân loại: mã Lua client phục hồi, chưa phải quan sát runtime. Chưa đọc track Spine nên không gọi `born1` là nảy/xoay, không nêu thời lượng. Chưa nghe file âm thanh nên không mô tả chất âm.

## Điểm cần đánh giá khi người dùng cho làm tiếp

Đây là tiêu chí đề xuất, chưa phải thông số đã duyệt:

- Phản hồi ngay khi nhấn; phân biệt lúc giữ và lúc thả.
- Tab mới có chuyển động vào; icon, nền và tên phối hợp thành một phản hồi dễ đọc.
- Tab cũ có chuyển động trở về trạng thái thường, tránh biến mất hoặc đổi hình đột ngột.
- Khi chuyển xong, trạng thái chọn rõ ràng và ổn định; chuyển động liên tục chỉ dùng nếu có mục đích.
- Kiểm tra cùng lúc cả thanh tab và nội dung trang, cả trường hợp bấm đổi tab nhanh.
- Bản duyệt sau phải thể hiện tương tác thật, không chỉ ảnh các trạng thái đứng yên.

Chờ chỉ dẫn tiếp theo; không tự chọn lại A/B/C hoặc khóa quy tắc năm ô bằng nhau.
