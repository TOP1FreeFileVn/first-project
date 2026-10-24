# Thẻ bản thể Hải Tặc — demo để duyệt

- [Bảng thiết kế](demo.png): Mướp phóng lớn và bốn mèo cùng thế giới, đủ bốn độ hiếm.
- [Trong trang Lính thật](native/in-game.png): ảnh Godot 450 × 800, cuộn đến hàng Hải Tặc.
- [Hàng thẻ ở kích thước trên điện thoại](native/four-cards.png).

## Hướng thiết kế

Nền gồm trời sáng, biển phía sau một chiếc tàu có đường bao khép kín và một cột cờ hải tặc ở bên trái. Đuôi tàu ở x22, mũi tàu ở x138; cả hai đầu đều có khoảng cách với khung trong x13–147. Mèo phóng lớn từ 76 lên 86 px, đứng trên boong gỗ cùng một màu với thân tàu; chỉ giữ hai khe ván nhẹ và bóng tiếp xúc. Không có mảng ván sáng riêng ở giữa hoặc dải footer xanh. Sao và tên đặt đè ở chân khung.

Bản 2 bỏ hẳn hai thanh dây buộc chéo vì trông giống nét thừa. [Ảnh phiên bản boong tàu](demo-deck-v2.png) có đường dẫn riêng để đối chiếu với ảnh đã gửi trước.

[Bản 3](demo-ship-v3.png) tăng nhận diện tàu bằng cờ/buồm lớn và mũi tàu cong; bỏ dải xanh dưới thẻ và đưa thông tin về đáy khung. Chỉ sửa layout của 4 thẻ trong runner review, không thay production.

[Bản 4](demo-ship-v4.png) bỏ mảng buồm trắng vì đọc thành một lá cờ thứ hai ở kích thước nhỏ. Giữ duy nhất cờ hải tặc. Khép kín hai bên mạn tàu và bo góc nền gỗ để không lộ khe biển hoặc mảng gỗ ra ngoài đường viền trong.

[Bản 5](demo-grounding-v5.png) sửa mặt đứng: đường chân trời biển nằm ngang ở y60, sàn có hai khe ván thu về điểm tụ gần `(80,60)`, mép xa ở y96 và mép gần ở y137. Giữ góc nhìn trước mặt, hơi nhìn xuống, không chuyển sang isometric. Bỏ các đường chia đều kiểu vách gỗ. Mèo đứng trước mạn tàu; bóng tiếp xúc mỏng sát chân (nét chân kết thúc tại y105; riêng áo Tam y106). Không có bệ hay vòng tròn dưới chân. Giữ một cờ đen, không khôi phục buồm trắng hoặc footer xanh.

Kiểm tra native cuối bản 5: 31 kiểm tra đạt, 6 ảnh, không lỗi kiểm tra. Đã xem thẻ phóng lớn, hàng bốn thẻ và toàn trang 450 × 800; kiểm tra riêng phối cảnh sàn, mép bo góc, chữ đáy khung và bóng tiếp xúc. Không sửa mã production hoặc save người chơi.

[Bản 6](demo-complete-boat-v6.png) vẽ lại đường bao thân và mạn tàu khép kín để hai đầu không bị cắt vào viền thẻ. Đáy thân nằm khoảng y126, mạn trước ở dưới bàn chân mèo; boong và thân dùng chung `WOOD = #d7ae78`. Bỏ hoàn toàn hình thang ván sáng ở giữa. Hai khe mảnh chỉ phân chia mặt sàn, không tạo một mảng màu riêng.

Kiểm tra bản 6: 31 kiểm tra fixture đạt, 6 ảnh đã chụp. Xem lại Mướp phóng lớn và hàng bốn thẻ xác nhận hai đầu tàu nằm trong khung, bỏ ván sáng giữa sàn và giữ vị trí chân. Log có lỗi parse riêng tại `game/ui/HUD.gd:240` trong thay đổi ngoài phạm vi demo (`open()` nhận đối số không phải Control); không sửa HUD ở bước thiết kế thẻ này.

Theo yêu cầu bổ sung, phẩm chất có một dải màu liên tục rộng 7 logical px, bên trong nét ngoài nâu `#583f21` rộng 4 logical px. Màu lấy trực tiếp `Economy.RARITY_COLORS`: Thường xám `#b9c3cc`, Hiếm xanh `#5aa9e6`, Sử thi tím `#c28bff`, Huyền thoại vàng `#ffb938`. Mép trong nâu 2 px tách lớp cảnh. Nền biển không đổi theo phẩm chất. Dấu đang ra trận là lớp riêng, không thay màu độ hiếm.

Đây là **bản thử**, chưa thay khung trong game. Dùng nguyên 4 thẻ và art/font hiện tại. Hình mèo chưa được thiết kế lại trang phục theo thế giới trong bước này. Bản native gắn lớp nền review vào bốn thẻ Hải Tặc ở RAM; các thẻ khác và production không bị sửa.

## Dựng lại

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File output/pirate-card-preview/run-preview.ps1
python docs/design/2026-10-25/pirate-card-demo/build_board.py
```

Runner dùng profile riêng và `PlayerData.persist=false`, sau đó khôi phục RAM. Ảnh thẻ riêng được render lại ở 3× logical với padding 10 px để giữ nguyên chỉ báo nâng cấp nhô ra ngoài viền. Kết quả kiểm tra và kích thước thực ở [native/review.json](native/review.json).
