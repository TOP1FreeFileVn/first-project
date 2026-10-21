# Lưu thử nghiệm pose mèo cũ — không dùng trong demo

**Trạng thái 2026-10-20: lưu trữ, không được native demo nạp.** Theo lựa chọn
thiết kế đã chốt, mèo luôn hiện **mặt trước** ở mọi trạng thái: đi trước/sau vật
thể, vào ống/khay, nghỉ và đi ra. Không yêu cầu pose quay lưng, ngang hay quay người.

Demo hiện lấy các phần mèo tabby mặt trước từ
[cat-spine-parts/svg/cat_tabby](../../cat-spine-parts/svg/cat_tabby/), giữ nguyên
hình, màu và nét nguồn. Xem [README demo hai vật thể](../README.md).

Các file `assembled_rear.svg`, `head_rear.svg`, các phần thân/chân/đuôi,
`manifest.json`, `png/`, `front-rear-review.png` và script trong thư mục này được
giữ lại để truy lại thử nghiệm trước khi chốt quy tắc mặt trước. Chúng không
phải nguồn sản xuất hoặc hướng dẫn đổi pose theo hướng đi.

Thông số lưu trữ: canvas **256×240**, floor-root **(128,238)**, viền chính
**12 px**, pivot chân **(82,203)** và **(174,203)**. `build_rear.py`,
`render_review.gd`, `review_rear.py` chỉ tái tạo bộ thử nghiệm cũ và báo cáo cũ.
Không cần chạy chúng để sử dụng demo hiện tại.

Chuyển động chân trong demo còn đơn giản; chưa có rig/runtime Spine. Việc giữ
mặt trước cố định là chủ ý thiết kế và không nằm trong danh sách thiếu animation.
