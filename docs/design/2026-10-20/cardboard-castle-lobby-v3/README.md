# Sảnh hộp giấy — chỉnh theo style mèo

Bản duyệt ngày 2026-10-20, tiếp nối hướng lâu đài A. Theo phản hồi mới nhất: nền phải cùng phong cách với mèo; dùng đất liền, bỏ đảo/isometric, có sân chơi và tên màn sắp tới bằng chữ trên đầu.

## Xem bản mới

- [Cảnh và bản ghép UI](flat-style-review.png)
- [Ảnh sảnh 720×1280](lobby-flat-style.png)
- [Cảnh với mèo gốc](map-with-cats.png)
- [So sánh nền cũ và hướng mới](style-comparison.png)
- [Figma — bản duyệt](https://www.figma.com/design/2uKzqvXeOSPQqfaow6s7TU?node-id=62-3)
- [Figma — so sánh](https://www.figma.com/design/2uKzqvXeOSPQqfaow6s7TU?node-id=62-2)

## Chỉnh mỹ thuật

Nền cỏ một màu phẳng, không grain hoặc chuyển sắc. Cây ở mép dùng khối tròn lớn, nét nhẹ hơn lớp mèo. Lâu đài và đồ chơi dùng viền nâu ấm `#583f21`, bo tròn, nét chính 4.5 px ở khổ720. Đường gấp/vòng dây dùng nâu nhạt hơn, tránh dồn nét đen vào nội thất.

Giữ lâu đài ba khối hộp, cổng mèo, băng keo, cờ cá; bổ sung ống chui, cột cào, bóng len, hộp nằm và đệm. Chỉ dùng các mặt vật liệu màu kín; không tạo đảo nền hình thoi. Các mặt trên mỏng của hộp/đồ chơi giúp đọc cấu tạo trong góc nhìn2D nhẹ từ trên.

Mèo dùng nguyên asset `cat_cream`, `cat_tabby`, `cat_calico` của game. Pose đứng hiện tại là mẫu đối chiếu mỹ thuật; chưa có animation chơi/ngủ. Sảnh cố định, không dãy chấm/mũi tên đảo; tên màn là chữ thuần. Header, rail, thưởng, CTA và nav được lấy từ fixture UI native.

## Nguồn và tái tạo

[Prompt](prompts/flat-cat-map.txt) tạo [ảnh gốc](flat-map-raw.png) bằng **GPT Image2.5 `gpt-image-2.5-sunburst` qua Figma `generate_image`**, file nháp `2uKzqvXeOSPQqfaow6s7TU`, node `61:2`. Không dùng CLI/API fallback.

Ảnh AI còn chuyển sắc, nên đã làm nghiên cứu phẳng màu rồi clean contour thành [castle-clean.svg](processed/castle-clean.svg) và [playground-clean.svg](playground-clean.svg), theo tạo hình/cách bố trí của ảnh sinh. Các layer SVG màu kín được Godot rasterize; `build_flat_review.py` ghép chúng với mèo gốc và overlay UI trong `../cardboard-castle-lobby-v2/`. Ảnh raw giữ riêng để kiểm tra nguồn. Bản tự động làm phẳng trung gian không phải bản cuối.

Đã kiểm tra tổng thể và khổ điện thoại: không viền hạt, không che công trình bằng rail; tên màn cách cờ khoảng40 px. Cây được cắt ở mép theo chủ ý. Chưa sửa asset hoặc logic production, chưa áp chi phí/cấp nâng cấp.
