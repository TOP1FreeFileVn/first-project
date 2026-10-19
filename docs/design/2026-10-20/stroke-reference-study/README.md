# Học lại stroke từ Figma — 20/10/2026

Người dùng yêu cầu dừng vẽ trang bị để học lại cách dùng nét. Đây là ghi chú đối chiếu ảnh tham khảo, không phải bản thiết kế mới. Không có artwork được sinh thêm, tích hợp hoặc tải lên Figma trong lần học lại này.

Nguồn: [Asset chính · Kho PNG, trang 3443:2](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3443-2). Ảnh trong thư mục tải trực tiếp bằng Figma MCP. Các ảnh lẻ là ảnh chụp node ở kích thước hiển thị 128 hoặc 160 px; chưa đủ để kết luận độ dày nét vector nguồn.

| Ảnh | Node | Quan sát |
| --- | --- | --- |
| armor-figma.png — Armor0111 | 3447:7563 | Nét trên giáp da đỏ là nâu đỏ trầm; phần vai kim loại dùng xám. Không có một màu nét trong chung cho cả món. |
| armor-steel-figma.png — Armor0113 | 3447:7569 | Viền hình nâu đậm; đường trên mặt thép xám hơn và nhẹ hơn. Các mảng xám rộng không đồng nghĩa với stroke. |
| armor-gold-figma.png — Armor0115 | 3447:7575 | Nét cấu tạo và hoa văn đi theo nâu vàng/ochre, khác với nét kim loại bạc. |
| boots-figma.png — Boots0111 | 3447:7581 | Tiếp giáp hai chiếc giày mạnh hơn nét may trên bề mặt; lớp màu vẫn đủ rộng. |
| boots-steel-figma.png — Boots0113 | 3447:7587 | Cùng món có phần thép xám, phần dây da nâu; không đổi toàn bộ nét trong thành xám. |
| crown-figma.png — Crown0111 | 3447:7600 | Mép lỗ chạm nền vẫn thuộc silhouette. Mặt sau xám là mảng màu, không phải một đường viền dày. |
| necklace-figma.png — Necklace0111 | 3447:7618 | Mép trong vòng dây tiếp xúc với nền vẫn giữ viền đậm; nét trên bề mặt dây nhẹ hơn. |
| sword-figma.png — Hero2/1 | 3447:14466 | Dải xám trên lưỡi kiếm là mặt bên rộng; không nên chuyển thành stroke. Bàn tay che nét ở chỗ cầm. |
| axe-figma.png — Hero6/1 | 3447:14706 | Nét và mảng được tiết chế ở kích thước nhân vật; các chỗ chồng lớp đọc qua hình và che khuất. |
| staff-figma.png — Hero8/6 | 3447:14816 | Những mảng xám trên tóc/áo là diện màu; không thể phát hiện nét chỉ bằng tìm vùng tối. |

Ảnh tổng nhóm trang bị: `equipment-group-figma.png`, node `3443:119`.

Ảnh tham khảo từ game thương mại được giữ local theo quy ước `.gitignore` của dự án. Git lưu ghi chú, node nguồn và script dựng bảng đối chiếu; mở link Figma phía trên để xem lại ảnh gốc sau khi clone. Mẫu thương mới do dự án tạo nằm ở `../spear-stroke-sample/` và được lưu đầy đủ trong Git.

## Cách hiểu cần sửa

1. Phân loại theo **mép hình, tiếp giáp, nét bề mặt và diện màu** trước khi quyết định độ dày. Vị trí trong/ngoài chưa đủ.
2. Nét bề mặt có màu và độ tương phản theo vật liệu. Không áp một mã xám cho toàn bộ đồ.
3. Nét chính vẫn theo mốc **9 px trên canvas mèo 256 × 240** đã chốt. Không tự coi mọi cổ tay, đế giày hay mép tấm giáp đều là nét chính.
4. Giữ các mảng màu lớn, dùng nét có chọn lọc. Không dựng một vòng viền dày quanh từng vùng màu hay biến mảng facet thành đường.
5. Sửa cấu tạo, khoảng màu và điểm tiếp giáp trực tiếp. Tăng nét toàn ảnh hoặc tái dựng mọi biên phân vùng không thay thế được cách vẽ này.

Bản vừa làm sai vì áp công thức độ dày/màu lên các biên mà chưa hiểu chúng đang mô tả gì. Đã sửa ghi chú trong `tools/skills/casual-weapon-design/references/internal-strokes.md`; các mẫu hero-equipment trước đó vẫn chưa được duyệt.
