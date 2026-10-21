# Sảnh lâu đài hộp giấy mèo — bản thảo duyệt

Ngày 2026-10-20. Đề xuất mỹ thuật cho **sảnh ngoài**, với lâu đài hộp giấy phát triển dần theo nâng cấp.

## Các bảng duyệt

- [Ba hướng tạo hình](directions-review.png): A — Pháo đài hộp giấy; B — Nhà mèo khổng lồ; C — Tháp hộp xếp tầng.
- [Bốn nấc nâng cấp của hướng A](upgrade-review.png): ổ hộp đầu tiên → pháo đài mèo → thành hai tầng → vương quốc hộp giấy.
- [Bốn nấc ghép trong sảnh hiện tại](lobby-upgrades-review.png).
- Ảnh sảnh riêng 720×1280: [1](lobby-stage-1.png), [2](lobby-stage-2.png), [3](lobby-stage-3.png), [4](lobby-stage-4.png).

Đề xuất chọn **A**: dáng lâu đài rõ khi thu nhỏ, cổng mèo đủ nhận diện và dễ thêm các khối mới. B nhấn mạnh dáng mèo; C hợp hướng nghịch ngợm, bất đối xứng.

## Nguyên tắc nâng cấp

Giữ vị trí cổng, hộp chính, băng keo, lối lên và cờ cá để thấy cùng một ngôi nhà đang được bồi đắp. Thêm tháp hai bên, tầng giữa, ban công, rồi sân và cầu nối. Các mốc trong tranh là nấc mỹ thuật đề xuất; chưa gắn với cấp, chi phí hay cân bằng trong game. Ảnh ghép giữ UI hiện tại để đối chiếu tỷ lệ.

## Nguồn và Figma

Hai ảnh gốc tạo bằng **GPT Image 2.5 (`gpt-image-2.5-sunburst`) qua Figma `generate_image`**, trong file nháp đã được chọn trước đó. Không dùng CLI/API fallback.

- [Prompt ba hướng](prompts/directions.txt) → [ảnh gốc](directions-raw.png), Figma node `57:2`.
- [Prompt nâng cấp](prompts/progression.txt) → [ảnh gốc](progression-raw.png), Figma node `58:2`.
- [Figma — ba hướng](https://www.figma.com/design/2uKzqvXeOSPQqfaow6s7TU?node-id=59-2).
- [Figma — nâng cấp](https://www.figma.com/design/2uKzqvXeOSPQqfaow6s7TU?node-id=59-3).
- [Figma — ghép sảnh](https://www.figma.com/design/2uKzqvXeOSPQqfaow6s7TU?node-id=59-4).

Các bảng trên Figma là ảnh raster để duyệt. Ảnh gốc và prompt đã lưu tại dự án, không phụ thuộc URL tải tạm thời.

## Ghép ảnh và kiểm tra

`LobbyDraftCapture.gd` tạo ảnh UI bằng SubViewport, profile riêng, `PlayerData.persist=false`. `prepare-layout-assets.py` bỏ group lâu đài từ bản sao SVG đảo và raster các asset review. `build_review.py` tách nền mint của tranh, ghép công trình với đảo/mèo gốc. Ảnh cắt trong `processed/` dành cho mockup, chưa phải sprite sản xuất.

Đã xem các bảng ở kích thước lớn và 360×640: không cắt công trình, không che header, title, sao, rail, pager, thưởng, CTA hoặc nav. Nấc nâng cấp phân biệt được ở tỷ lệ điện thoại. Vòng sản xuất tiếp theo cần làm phẳng một số mảng tô AI, chỉnh độ dày viền và dời vài đồ trang trí bị mèo tiền cảnh che.

Toàn bộ thay đổi của nhiệm vụ này nằm trong thư mục bản thảo. Chưa thay asset hoặc logic sảnh đang chạy.
