# Nghiên cứu nền Cat Gunner

Ngày xem: 2026-10-20. Game người dùng gọi là “Cat Shooter” được đối chiếu với bộ RE đang có: **Cat Gunner 1.1.64**, package `com.Chodun.CatGunner`. Danh tính và phiên bản được ghi trong `input-provenance.json` và `asset-manifest.json` của bộ trích xuất, không suy ra chỉ từ tên thư mục.

Nguồn gốc trên máy:

`C:/Users/dangp/OneDrive/Documents/first-project/reverse_engineering/CatGunner_1.1.64/`

Ảnh tổng hợp [cat-gunner-background-sources.png](cat-gunner-background-sources.png) giữ nguyên tỉ lệ sprite. Đây là **bảng tài sản gốc đã trích xuất**, không phải ảnh chụp màn hình đang chạy và không chứng minh vị trí của chúng trong sảnh thật. `sources.json` lưu đường dẫn và SHA-256 từng ảnh.

## Những file nền hữu ích

- `Assets/Sprite/sharedassets0.assets/Map_0__644.png`: rừng xanh, 512×286.
- `Assets/Sprite/sharedassets0.assets/Map_1__896.png`: sa mạc, 512×286.
- `Assets/Sprite/sharedassets0.assets/Map_2__606.png`: tuyết, 512×286.
- `Road_Forest__497.png`, `Field_Forest__622.png`: mảng đất/cỏ vuông 128×128, gần như màu phẳng.
- `Road_up_Forest__590.png`: dải mép cỏ 253×33, hai tầng màu.
- `Bush_Yellow_Green_01` đến `05` và `Forest_Grass`: bụi/cỏ tách riêng, nền trong suốt.

Các file bắt đầu bằng `Raid_0`…`Raid_4` là atlas nhân vật boss sau khi mở xem, không dùng làm bằng chứng về nền. Sprite `Background__449.png` chỉ là miếng UI 32×32.

## Quan sát hình ảnh

- Khối to, đường viền nâu ấm bo tròn, ít đường nội bộ. Các đường bao của lớp đồi tiếp nối nhau; chi tiết vật liệu không dày đặc.
- Vật ở gần nằm sát hai cạnh và bị cắt khỏi khung; vùng giữa thấp, thoáng, phù hợp chỗ đặt nhân vật hoặc công trình chính.
- Độ sâu được tạo bằng lớp cây/bụi trước, mặt đất, đồi xa và bầu trời. Màu xanh ở rừng thiên vàng và xám nhẹ, không rực neon.
- Nền không tuyệt đối màu phẳng: bầu trời có chuyển sắc nhẹ, thân cây và tán lá có ít mảng tối/sáng. Các mảng bóng lớn giúp đọc khối, không tạo bề mặt 3D bóng.
- Viền môi trường nhẹ hơn nét bao của icon/nhân vật khi xem ở kích thước sử dụng; không áp máy móc con số 9 px của canvas mèo lên toàn bộ cây, cỏ và mây.

Mẫu màu đọc trực tiếp từ pixel nguồn: đường đất `#B89475`, cỏ `#61864E`, mép cỏ tối quanh `#415935`; trong tranh rừng có trời `#9AD3E6`, xanh lá `#92AB58`/`#8AA95B` và các pixel viền nâu gần `#563D21`/`#584020`. Đây là màu pixel trong texture đã nén, không phải bảng màu thiết kế gốc. Độ dày nét thay đổi theo lớp và đối tượng; không có đủ bằng chứng để tuyên bố mọi nét nguồn dùng chung một số px.

## Đề xuất cho sảnh lâu đài giấy mèo

Đây là đề xuất áp dụng vào game của mình, không phải thông tin hệ thống của Cat Gunner:

- Giữ góc nhìn thẳng, mặt đất liên tục; hai bên có cây/bụi làm khung, giữa dành cho lâu đài hộp giấy.
- Lâu đài dùng mảng bìa vàng nâu sáng, mép bìa nâu ấm, băng dính và hình mèo; không gắn shading kim loại hay đá tả thực.
- Chỗ vui chơi đặt lệch hai bên dưới lâu đài, chỉ vài món lớn; giữ khoảng trống trước cửa cho mèo đã tách chân chuyển động.
- Chừa vùng trên thoáng cho tên màn sắp tới, giữ chữ trực tiếp trên nền như định hướng đã duyệt.
- Tách nền xa, cây giữa, lâu đài, đồ chơi, mèo thành lớp. Chuyển động nhẹ của mây/lá có thể thêm về sau.

Chưa đưa asset đối thủ vào runtime, chưa sửa cảnh Godot/Figma trong bước nghiên cứu này.
