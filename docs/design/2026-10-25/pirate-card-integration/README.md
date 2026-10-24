# Áp dụng thuyền cute cho bốn thẻ Hải Tặc

- [Bảng duyệt từ thẻ trong game](review.png).
- [Ảnh trang Lính thật, 450 × 800](native/in-game.png).
- [Bốn thẻ ở kích thước điện thoại](native/four-cards.png).
- [Thẻ đang ra trận và thẻ chưa mở](native/mixed-locked-fielded.png).

Đã áp dụng trong production cho `cu_kiem`, `gay_phep`, `dai_bac`, `dao`, là bốn bản thể Hải Tặc của Mướp/Tro/Tam/Bơ. Các thế giới còn lại giữ bố cục cũ. Không đổi save, cân bằng, cơ chế ra trận hoặc độ hiếm.

## Bố cục

Giữ nguyên thuyền SVG v2 người dùng đã duyệt; chia thành lớp cột/buồm/cabin phía sau, mèo, rồi lớp thân/mạn phía trước. Bổ sung mặt boong phẳng cùng màu gỗ giữa hai đường mép đã có, không đổi đường bao thuyền. `PirateTroopCard.gd` dựng cảnh và khung; mọi lớp vẽ bỏ qua pointer để `TroopDragButton` vẫn nhận tap/drag.

Trong thẻ 160 × 150, thuyền giữ đúng tỉ lệ trong `(2,4,156,136.5)`, hai đầu đều nằm trong khung. Mèo 60 px tại `(40,41)` để chừa buồm đầu lâu và cabin bên phải. Mạn trước che đúng phần thấp nhất gần chân. Sao ở y114, tách khỏi cửa tròn giữa thân; tên Hải Tặc ở y126, sát đáy khung. Không có dải footer riêng hoặc tấm ván sáng giữa sàn.

Viền phẩm chất giữ bốn màu từ `Economy.RARITY_COLORS`, nét nâu ngoài 4 px, dải phẩm chất 7 px. Thẻ ra trận giữ màu hiếm và dấu tick riêng; thẻ khóa có nền dịu và hình mèo dấu hỏi. Chỉ hiện số sao đã đạt. Chỉ báo nâng cấp vẫn nhô ngoài khung.

## Kiểm tra

Runner dùng trực tiếp `Home/TroopsPage`, không gắn art hoặc chỉnh layout ở RAM. 138 kiểm tra đạt, 8 ảnh native, không lỗi kiểm tra; `review.json` ghi kích thước các lớp và nội dung thẻ. Đã kiểm tra tap mở chi tiết/quay lại, kéo bản Hải Tặc lên đúng mèo, từ chối sai mèo và thẻ khóa, trạng thái đang ra trận, các lớp hình không chặn input. Hai lớp nền/mạn cùng phủ đủ thẻ 160 × 150.

Profile chạy review tách riêng, `PlayerData.persist=false`, khôi phục trạng thái RAM và kiểm tra save không bị ghi. Lượt chạy chỉ có cảnh báo root certificate store vốn có.

```powershell
python docs/design/2026-10-25/cute-pirate-ship/export_layers.py
powershell -NoProfile -ExecutionPolicy Bypass -File output/pirate-card-preview/run-preview.ps1
python docs/design/2026-10-25/pirate-card-integration/build_review.py
```

Không commit hoặc push ở bước này.
