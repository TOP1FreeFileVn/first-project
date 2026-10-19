# Rà lại đồ họa game · 19/10/2026

Đã chạy lại UI thật qua MCP Godot với profile tạm và `PlayerData.persist = false`. Có 13 màn menu/popup và 2 trạng thái battle mới chụp ở 720 × 1280; ảnh tổng hợp thu về rộng 360 px/màn. Đây là lượt xem đồ họa; không sửa asset, UI hay gameplay.

- [6 màn chính](menu-overview.png)
- [Chi tiết trang bị, lính và popup](detail-overview.png)
- [Bản đồ và chiến đấu](battle-overview.png)
- [15 ảnh gốc](screens/)
- [Kết quả MCP](mcp/mcp-results.json)

## Ngôn ngữ hình ảnh thực tế

Mèo dáng tròn, đầu rộng, mắt chấm, miệng nhỏ; viền nâu ấm `#583f21`, đầu và góc nét bo tròn. Nhân vật, vũ khí và trang bị chủ yếu dùng mảng màu phẳng, hình vật thể cụ thể, hơi ngộ nghĩnh. Màu vật liệu là gỗ nâu, thép xám sáng, vàng ấm và vải xanh/đỏ/tím. Cây, đá và thành tiếp tục dùng hình khối mềm với lượng chi tiết vừa phải.

Tiền, gem và khung/nút UI có viền, lip hoặc bóng là một lớp có chủ ý; không cần ép mọi vật thể thành cùng một cách tô như sprite.

Các hệ lính hiện nhận diện bằng trang phục:

| Hệ | Nhận diện hiện có |
|---|---|
| Bộ binh | Mũ sắt rộng vành, giáp thép, mèo tabby |
| Tầm xa | Hood xanh có tai mèo, đai/quiver, mèo xám |
| Pháp sư | Mũ phù thủy, áo choàng tím/xanh, mèo calico |
| Kỵ binh | Mũ đồng có mào, áo tabard đỏ, mèo kem |

Kỵ binh trong art hiện tại không cưỡi ngựa. Màu nền thẻ thể hiện độ hiếm, không phải hệ. Bộ 4 icon huy hiệu vừa trình bày đã bị người dùng bác bỏ; không lấy bộ đó làm chuẩn hay đưa vào UI.

Nguồn hình học: `tools/ui/make_units.py`, `tools/ui/make_svgs.py`, `tools/ui/make_battle_map.py`, `tools/ui/make_castle_art.py`; đối chiếu với các ảnh runtime trong thư mục này.

## Những phần nên giữ

- Nhân vật mèo và hệ đồ cầm/đội: nhận diện mạnh nhất của game.
- Khung kem–vàng–nâu, nút mềm và bộ tab hiện có: phù hợp fantasy dễ thương, cần điều tiết mức nổi.
- Thẻ lính 4 cột, cấp góc phải, tên giữa và sao riêng: cấu trúc dễ quét hiện tại.
- Đảo thành ở sảnh và nền trận có khoảng giữa yên: tạo bối cảnh mà không phủ chi tiết lên quân.

## Chỗ lệch nhìn thấy trong game

1. Nền chân mèo/bánh răng xanh hiện diện mạnh quanh các panel; footer có icon, viền và badge nổi, nhiều lúc tranh điểm nhìn với nội dung.
2. Rương ở shop và các mốc quà nhiều đinh/nẹp/ô chia nhỏ hơn cách giản lược của mèo, vũ khí và icon tab. Castle thu nhỏ cũng mất nhiều chi tiết.
3. Castle còn chữ trắng viền đậm và legend rất nhỏ; shop/lính dùng chữ nâu trên giấy dễ đọc hơn. Cách dùng chữ giữa các trang chưa đều.
4. Màn Thành dành nhiều diện tích cho panel nhưng art và thông số tập trung thành cụm nhỏ. Hero có tương phản tốt hơn, nhưng các khối trang bị/khoảng trống chưa thống nhất với mật độ trang lính.
5. Lính khóa bị làm tối nhiều khiến hình và màu trang phục khó đọc hơn. Preview ô thành dùng mảng xanh/vàng/đen sắc cạnh, lệch độ mềm của asset xung quanh.
6. Trong ảnh trận có 13 quân ta, nhóm quân ở giữa đã che nhau, nhất là vũ khí và silhouette phía sau. Nền trận yên là điểm tốt; việc phân biệt từng đơn vị trong nhóm cần xem thêm nếu tăng mật độ.

## Kiểm tra chạy

Hai lượt MCP kết thúc mã 0, lưu đủ 15 PNG; không có lỗi GDScript trong log. Godot vẫn in thông báo chứng chỉ Windows đã có từ trước. Lượt này chỉ đánh giá hình tĩnh runtime, chưa đánh giá toàn bộ chuyển động/VFX hoặc mọi mật độ quân về cuối trận.
