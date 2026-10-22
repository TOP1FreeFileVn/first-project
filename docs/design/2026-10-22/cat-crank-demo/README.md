# Mèo vận hành cối — bản đã bị từ chối

Người dùng đã bỏ hướng này: hình giống mèo ngồi chơi ở bàn, chưa thể hiện nắm cán bằng hai tay để quay trục. Bản sửa nằm ở `../cat-two-hand-drive/`. Giữ thư mục này làm lịch sử, không tích hợp vào game.

Người dùng đề xuất thay tay quay ở trục giữa bằng mèo đang quay cối kiểu xay/giã gạo. Demo này giữ mặt trước, dùng head/body/tail/feet của mèo cream đã tách; hai tay đặt riêng để bám vào cán nhỏ. Mèo nhún1.2px và nghiêng nhẹ theo góc cán, không xoay lưng hay dùng sprite nhân vật anh hùng.

Cối thấp bằng vật liệu ấm như bàn carton, mặt ellipse phẳng và cán gỗ; màu phẳng, không bóng. Main3.2px nâu#583f21, mặt tiếp xúc được giải quyết bằng fill; không vẽ viền quanh mọi mảng vật liệu. Tỷ lệ mèo .28 từ canvas256×240; khối mèo/cối nằm trong ô giữa, chân cối y~40, đầu pin giữ reach54.204486. Hai tay đi theo cùng đầu cán, không cố với ra pin ngoài.

Thứ tự: cánh truyền động → đuôi/chân/thân mèo → cối và trục nhỏ → cán/tay → đầu mèo. `crank.js` giữ hình vẽ và quỹ đạo; `preview.html` có demo động, dừng và kéo từng góc, hình lớn và bản trên bàn B. Đây là animation concept, chưa đổi Core/CogDraw/GearBoard; minh họa quay gear chưa mô phỏng state machine sản xuất. Khi tích hợp, góc pose phải lấy trực tiếp board.pin_angle(), không chạy timer mèo riêng.

Tham chiếu mặt mèo Figma node3471:252 và bộ phận node3471:258; dùng lại asset game/assets/lobby/cardboard/cats/cat_cream. `round-1.png` và `round-2.png` là ảnh thử đã tạo. Chưa thay bản game đang dùng.
