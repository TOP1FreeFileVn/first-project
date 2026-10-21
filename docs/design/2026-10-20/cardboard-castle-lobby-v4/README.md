# Sảnh lâu đài hộp giấy V4

Bản thiết kế để duyệt, tiếp nối V3: lâu đài hộp giấy mèo trên mặt đất liên tục,
có sân chơi; tên màn sắp tới đặt bằng chữ phía trên. Mèo lấy nguyên từ game.

## Nguồn tham khảo đã xem

Đã tìm đúng bộ RE **Cat Gunner 1.1.64**, package `com.Chodun.CatGunner`, tại
`C:/Users/dangp/OneDrive/Documents/first-project/reverse_engineering/CatGunner_1.1.64/`.
Ba sprite `Map_0__644.png`, `Map_1__896.png`, `Map_2__606.png` nằm trong
`Assets/Sprite/sharedassets0.assets/`, cùng kích thước 512 × 286.

Xem [bảng tài sản nguồn](../cat-shooter-background-study/cat-gunner-background-sources.png),
[ghi chú quan sát](../cat-shooter-background-study/README.md) và
[đường dẫn/hash nguồn](../cat-shooter-background-study/sources.json).
Đây là tài sản nguồn trích xuất, không phải ảnh sảnh runtime của đối thủ.

## Quyết định thiết kế

- Học cách xếp lớp cây hai mép, mặt đất, đồi xa và trời; giữ giữa thoáng.
- Cảnh xa có nét và tương phản nhẹ hơn mèo, lâu đài và đồ chơi.
- Nắp gập, mặt bên hẹp và băng keo giúp lâu đài đọc thành hộp giấy thật.
- Đường mòn liên tục nối cổng, sân chơi và tiền cảnh; bỏ nền đảo/isometric.
- Giữ hình mèo gốc riêng khỏi background để tiếp tục làm Spine sau này.

## Tạo ảnh

Ảnh [courtyard-raw.png](courtyard-raw.png) được tạo bằng GPT Image 2.5
(`gpt-image-2.5-sunburst`) qua Figma `generate_image`, file
`2uKzqvXeOSPQqfaow6s7TU`, node `64:2`. Lần sinh ảnh dùng credit Figma AI.
Không dùng CLI/API tạo ảnh ngoài. [Prompt gốc](prompts/cat-gunner-informed-courtyard.txt)
được lưu để tái tạo và kiểm tra hướng thiết kế.

Thiết kế là cảnh mới của dự án; không đưa sprite đối thủ vào runtime.
Chưa thay background production hoặc logic nâng cấp trong game ở bước duyệt này.

## Bản xem và cấu trúc Figma

- [Bảng Figma V4](https://www.figma.com/design/2uKzqvXeOSPQqfaow6s7TU?node-id=66-2): cảnh mới bên trái, nguồn RE và chi tiết lâu đài bên phải.
- [Ghép thử với UI hiện tại](lobby-courtyard.png) và [cảnh có mèo](map-with-cats.png).
- [Bản đối chiếu trước/sau](raw-vs-refined.png); ảnh gốc vẫn giữ nguyên để đối chiếu.
- [Vị trí/lớp ghép](placements.json) và [ID các layer Figma](figma-editable-scene.json).

Figma tách ảnh cảnh và ảnh lâu đài thành hai lớp độc lập để thay nấc nâng cấp.
Ba mèo là vector riêng với các nhóm `head`, `body`,
`tail`, `foot_L_image`, `foot_R_image`, `paw_L_image`, `paw_R_image`.
Mép trước của khay giấy nằm trên mèo tam thể. Tên màn là text chỉnh được, dùng
`Paytone One / Regular`. Không dùng ảnh ghép toàn bộ UI làm layer trong Figma;
ảnh UI chỉ là proof cục bộ để kiểm tra khoảng trống cho các nút đang có.

Đây là bản thảo mỹ thuật của một nấc lâu đài. Chưa có các nấc nâng cấp trên sân mới,
chuyển động mây/lá, parallax hay logic tương tác với đồ chơi. Hình môi trường còn
chuyển sắc nhẹ hơn chất màu phẳng của mèo; cần chốt hướng trước bước chuẩn hóa asset.

Bước chuẩn bị tiếp theo: [pipeline vẽ lại SVG, chia lớp và tương tác mèo](../cardboard-castle-svg-pipeline/README.md).
