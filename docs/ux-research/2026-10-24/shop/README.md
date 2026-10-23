# Phối màu và bố cục shop để người chơi dễ quyết định

Ngày nghiên cứu: **24/10/2026**. Phạm vi: tài liệu công khai về màu sắc, khả năng đọc, lựa chọn và UX mua hàng; đối chiếu shop rương hiện tại bằng ảnh native 360×640 / 450×800 và mã nguồn. **Chưa thực hiện nghiên cứu với người chơi hoặc đo mức tăng mua.** Không thay đổi UI, giá, phần thưởng hay cơ chế game trong đợt nghiên cứu này.

## Kết luận áp dụng cho game

Ưu tiên **hiểu giá trị → so sánh → biết giá → hành động rõ ràng**. Giữ phong cách giấy, font game và bottom bar đã duyệt. Dùng nền xanh trầm ít cạnh tranh, bề mặt giấy sáng và một mức nhấn vàng mạnh cho hành động mở rương. Tăng độ rõ của lợi ích trước khi thêm màu hay hiệu ứng.

Shop đã dành vị trí trên cùng, khung ngang rộng và hình lớn hơn cho Rương Vàng. Đây là nền tảng hợp lý để thử tiếp; không cần phá toàn bộ bố cục. Minh họa [direction-board.png](direction-board.png) là **sơ đồ phân tích**, không phải ảnh một UI mới đã chạy trong game hoặc kết quả A/B.

## Nghiên cứu thực sự nói gì?

| Câu hỏi | Bằng chứng | Cách dùng |
| --- | --- | --- |
| Đỏ, xanh hay vàng khiến người ta mua nhiều hơn? | Tổng quan tâm lý màu của Elliot nhấn mạnh bối cảnh, ý nghĩa màu và hạn chế phương pháp nghiên cứu [S1]. NN/g giải thích phân cấp phụ thuộc độ tương phản với xung quanh, kích thước và nhóm [S2]. | Chọn màu theo vai trò trong màn hình. Không tuyên bố một màu nút luôn bán tốt hơn, hoặc đổi màu sẽ tăng doanh thu một tỷ lệ xác định. |
| Shop ít món luôn tốt hơn? | Meta-analysis 2010 thấy hiệu ứng trung bình của quá tải lựa chọn gần bằng 0, có biến thiên lớn [S3]. Meta-analysis 2015 xác định độ phức tạp, khó khăn nhiệm vụ, sự chưa rõ sở thích và mục tiêu giảm công sức là các biến điều tiết [S4]. | Chuẩn hóa thông tin để dễ so sánh; chia nhóm khi danh mục lớn. Không áp dụng quy tắc máy móc “chỉ được 3 món”. |
| Phối màu thế nào để đọc được? | WCAG đặt mốc 4,5:1 cho chữ thường và 3:1 cho chữ lớn; không dùng riêng màu để diễn đạt trạng thái [S5]. | Giá, lợi ích, thiếu tiền phải có chữ/icon rõ. Độ tương phản đạt không thay thế kiểm tra cỡ chữ và stroke trên điện thoại. |
| Thông tin mua nên đặt đâu? | Apple hướng dẫn tên/mô tả gọn, tổng giá rõ, trải nghiệm mua cùng phong cách app [S6]. NN/g khuyến nghị trạng thái rõ, ngăn lỗi và giảm ghi nhớ [S7]. | Đặt lợi ích, giá và nút trong một nhóm; ba rương có chung thứ tự đọc. |
| Đánh giá bằng mắt có đủ không? | NN/g phân biệt cảm nhận thị giác với hành vi: preference test không thay thế task test/A/B [S8]. | Thử khả năng tìm đúng rương và hiểu giá trước; đo hành vi mua sau. |

Không nguồn nào ở trên đo conversion của game này. Các màu, kích thước và bố cục dưới đây là đề xuất để kiểm chứng.

## Shop hiện tại: phần tốt và điểm cản

Ảnh nguồn: `docs/ui_review/2026-10-23/chest-b-integration/shop-450x800.png` và `shop-360x640.png`.

1. **Tương phản chữ trên thẻ đã tốt.** Tính từ màu phẳng authored: chữ nâu `#3B2B1E` trên Gold `#E7CA91` ≈8,55:1; Wood `#BFD7AB` ≈8,72:1; Silver `#B2D4DF` ≈8,63:1. Chữ bảo đảm tím `#69328C` trên Gold ≈5,44:1. Đây là phép tính hai màu phẳng, không chứng nhận mọi nhãn, chữ viền hoặc trạng thái động.
2. **Chữ phụ nhỏ ở ảnh 360.** Font 20 trên canvas logical 720 trở thành khoảng 10 px trong capture rộng 360: dòng bảo đảm, vàng thưởng và trạng thái miễn phí khó quét hơn. Thử tăng nội dung quyết định lên khoảng 14–16 px trong bản hiển thị rộng 360, rút câu và kiểm tra với font game. Đây là điểm bắt đầu thiết kế, không phải cỡ chữ WCAG bắt buộc.
3. **Nút phụ cạnh tranh với nút mở.** “TỈ LỆ THẺ” cũng dùng da vàng bóng. Giữ nó dễ tìm nhưng hạ xuống link/chip phụ, để hành động tiêu tiền có cấp nhấn rõ hơn.
4. **Lợi ích chưa có cùng cấu trúc để đối chiếu.** Gold có 25 thẻ và ≥3 Hiếm; Silver có dòng “Mở bằng vàng” lặp thông tin giá. Giữ các số thật, bỏ câu trùng và dùng thứ tự tên → số thẻ → đặc điểm/bảo đảm → giá.
5. **Bảo đảm Sử thi nằm ở chú thích nhỏ.** Gom vào cụm giá trị của Gold; diễn đạt số lượt còn lại từ dữ liệu thật. Không thêm nhãn “giá tốt nhất”, “phổ biến nhất” nếu chưa có cơ sở.
6. **Nền và chrome có nhiều hoạt động thị giác.** Họa tiết xanh, mái shop, ba màu thẻ, vàng của mọi nút và bottom bar cùng thu hút mắt. Thử giảm tương phản họa tiết, giữ chuyển động êm và ổn định vùng đọc. Giữ bottom bar, rút dòng trùng trước khi thu nhỏ đồ họa sản phẩm.
7. **Thiếu tiền mới chỉ làm nút disabled trong code.** Nên ghi “Thiếu X kim cương/vàng”, vẫn cho xem giá và tỷ lệ. Ảnh hiện tại đủ tiền nên phát hiện này là từ mã, chưa quan sát runtime trạng thái thiếu tiền.

Nguồn nội bộ: `game/menu/pages/ShopPage.gd` các hàm `_featured_chest`, `_supply_card`, `_chest_button`; `game/ui/UiKit.gd::INK`; `game/ui/skin/menu/shop_{featured,wood,silver}.svg`; `game/data/balance.json::chests`. Màn được kiểm tra tiêu vàng/kim cương trong game, chưa thấy checkout tiền thật trong phần mã này.

## Hướng phối màu nên thử

| Vai trò | Màu đề xuất | Lý do trong màn hình này |
| --- | --- | --- |
| Nền | Xanh trầm `#345873` | Lùi sau giấy và vàng; họa tiết gần màu nền. Không phải vì xanh tự nó làm người chơi mua. |
| Thẻ giấy | Kem ấm `#F2DCAB` | Một chất liệu chung giúp danh mục thống nhất. Có thể giữ sắc xanh nhạt của Wood/Silver ở mức nhẹ thay vì đổi hết một lần. |
| Chữ thông tin | Nâu đậm `#3B2B1E` | Trên giấy đề xuất ≈10,06:1; giữ dễ đọc khi giảm độ rực nền. |
| Viền | Nâu `#583F21` | Đồng bộ vật phẩm, rương và UI hiện tại. Không thêm bóng dưới panel. |
| Nhấn hành động | Vàng `#FFE281` | Dành độ sáng/độ bão hòa cao cho nút chính, giữ da nút và font game đã duyệt. Với nhãn trắng viền đen, phải kiểm tra nét viền thực tế thay vì lấy tỷ lệ của chữ nâu làm chứng nhận. |
| Phẩm chất | Tím hiện có ở nhãn Hiếm/Sử thi | Đi kèm chữ/icon, dùng cục bộ trong phần thưởng. Không phủ cả nền tím để thay nội dung bảo đảm. |

Các mã màu là giả thuyết phối màu, không phải bảng màu đã được người dùng thử nghiệm. Không áp dụng tỷ lệ “60/30/10” như một kết quả nghiên cứu conversion.

## Phân bố thông tin đề xuất

- **Trên:** số dư hiện tại và mái shop; tiết chế độ nổi của phần trang trí.
- **Gold full-width:** tên; rương bên trái; bên phải là `25 thẻ lính`, `Ít nhất 3 thẻ Hiếm`; tiếp ngay dưới là nút `Mở 1 lần · [gem] 120`. Dòng bảo đảm dùng số lượt còn lại thật. Link `Vật phẩm & tỷ lệ` trong cùng thẻ, xem được trước khi tiêu tiền.
- **Dưới:** Wood và Silver hai thẻ gọn, cùng thứ tự thông tin; Wood `3 thẻ + 50–100 vàng / Miễn phí`, Silver `8 thẻ / 600 vàng`. Không tự thêm bảo đảm cho Silver.
- **Tiếp theo khi cuộn:** đổi kim cương; không chen lên giữa phần thưởng và nút của Gold.
- **Bottom bar:** giữ vị trí và cấu trúc. Vùng cuộn không bị nút cố định che mất giá.

Giữ trải nghiệm chạm nhất quán: chạm thân thẻ mở xem chi tiết; nút ghi rõ hành động mới tiêu tiền. Sau bấm có phản hồi ngay, ngăn thao tác lặp khi đang xử lý, số dư/kết quả cập nhật rõ. Không cần thêm cửa sổ xác nhận dài cho mọi lượt miễn phí; trạng thái mua bằng tiền thật tuân theo luồng nền tảng.

Apple và Google yêu cầu công bố tỷ lệ vật phẩm ngẫu nhiên có mua trước giao dịch, Google còn chỉ rõ gần vị trí/thời điểm mua [S9]. Điều này cần xem xét khi gem có thể được mua bằng tiền thật. Đây là thông tin minh bạch tại điểm quyết định, không phải lý do để làm nút tỷ lệ nổi ngang nút mở. Chưa audit độ đúng của tỷ lệ hiển thị so với thuật toán đảm bảo/pity trong nghiên cứu này.

## Cách kiểm chứng với người chơi

**Vòng chẩn đoán nhỏ, đề xuất 6–8 người chơi mục tiêu:** có cả người quen và chưa quen game idle, chơi trên điện thoại ở kích thước thật. Cỡ nhóm này giúp tìm vấn đề, không dùng để ước lượng conversion của thị trường.

1. Cho xem ngắn để hỏi rương nào được chú ý đầu tiên và họ nhớ lợi ích gì. Không dùng bài nhớ sau 5 giây để kết luận đã hiểu mọi giá và điều khoản.
2. Giao tác vụ: “Bạn có 120 kim cương, muốn bảo đảm nhận ít nhất 3 thẻ Hiếm. Bạn chọn gì và mất bao nhiêu?”; “Bạn muốn nhận rương miễn phí”; “Xem tỷ lệ trước khi mở”; “Không đủ tiền thì chuyện gì xảy ra?”.
3. Ghi điểm chạm đầu, thời gian tìm, hiểu đúng số lượng/chi phí, chọn nhầm, lý do dừng. Làm tác vụ trước, hỏi thích màu/bố cục sau để giảm ảnh hưởng gợi ý [S8].
4. Đảo thứ tự bản hiện tại/bản mới giữa người tham gia. Tách vòng thử bố cục và vòng thử màu; không đổi giá/phần thưởng cùng lúc.

**Khi có người dùng đủ để A/B:** chia người chơi ngẫu nhiên và giữ nhóm qua các phiên. Định nghĩa trước exposure, cửa sổ đo, baseline, mức cải thiện đáng quan tâm và cỡ mẫu; không chốt kết quả chỉ vì một ngày tăng hoặc một màu nhiều click hơn.

- `open_shop → thấy offer → chạm xem/mở → tiêu tiền thành công → xem kết quả` là các bước riêng. Impression cần thật sự xuất hiện trong viewport, không chỉ được tạo node.
- Tách lượt nhận miễn phí, mở bằng vàng và mở bằng kim cương. Đo theo người chơi/phiên đủ điều kiện; tránh để người bấm lặp làm đẹp số liệu.
- Theo dõi thành công mở rương, hiểu đúng chi phí, nhầm thao tác, bỏ ở bước thiếu tiền và phản hồi sau mở. Với IAP thật, cần event giao dịch xác thực riêng; không gọi lượt tiêu gem là doanh thu tiền thật.
- Chỉ triển khai rộng khi hành vi mục tiêu cải thiện và các chỉ số hiểu đúng/nhầm thao tác không xấu đi. Không có mục tiêu tăng phần trăm nào được đặt ra từ dữ liệu chưa có.

**Thứ tự làm:** (1) chữ và thứ tự thông tin; (2) cấp nhấn nút mua/nút phụ; (3) nền và palette; (4) phản hồi/hiệu ứng. Không cần thay art rương vừa duyệt để thử các giả thuyết này.

## Nguồn đã đọc

Tất cả được truy cập ngày 24/10/2026. Tóm tắt phạm vi đọc nhằm phân biệt nghiên cứu thực nghiệm, hướng dẫn và đề xuất của người phân tích.

- **S1** Elliot, A. J. (2015), *Color and psychological functioning: a review of theoretical and empirical work*. Tổng quan toàn văn mở: https://pmc.ncbi.nlm.nih.gov/articles/PMC4383146/
- **S2** NN/g, Kelley Gordon (2021), *Visual Hierarchy in UX: Definition*. Đọc trực tiếp toàn bài; hướng dẫn UX, không phải thí nghiệm doanh thu game: https://www.nngroup.com/articles/visual-hierarchy-ux-definition/
- **S3** Scheibehenne, Greifeneder & Todd (2010), *Can There Ever Be Too Many Options? A Meta-Analytic Review of Choice Overload*. Đọc PDF tác giả; 63 điều kiện / 50 thí nghiệm / N=5.036: https://www.scheibehenne.de/ScheibehenneGreifenederTodd2010.pdf ; DOI https://doi.org/10.1086/651235
- **S4** Chernev, Böckenholt & Goodman (2015), *Choice overload: A conceptual review and meta-analysis*. Chỉ đọc abstract nhà xuất bản trên Crossref; 99 observations / N=7.202, không đọc toàn văn: https://api.crossref.org/works/10.1016/j.jcps.2014.08.002 ; DOI https://doi.org/10.1016/j.jcps.2014.08.002
- **S5** W3C, *Understanding SC 1.4.3 Contrast (Minimum)* và *SC 1.4.1 Use of Color*. Đọc trực tiếp; chuẩn khả năng tiếp cận, không phải dự báo mua: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html ; https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html
- **S6** Apple HIG, *Apple In-App Purchase*. Đọc trực tiếp; hướng dẫn nền tảng: https://developer.apple.com/design/human-interface-guidelines/apple-in-app-purchase
- **S7** NN/g, *10 Usability Heuristics for User Interface Design*. Đọc trực tiếp: https://www.nngroup.com/articles/ten-usability-heuristics/
- **S8** NN/g, Megan Chan (2024), *Testing Visual Design: A Comprehensive Guide*. Đọc trực tiếp toàn bài, gồm giới hạn bài 5 giây, preference test, tác vụ hành vi và A/B: https://www.nngroup.com/articles/testing-visual-design/
- **S9** Apple *App Review Guidelines* §3.1.1 và Google Play *Payments*. Đọc trực tiếp phần vật phẩm ngẫu nhiên; chính sách cần đối chiếu lại lúc phát hành: https://developer.apple.com/app-store/review/guidelines/#in-app-purchase ; https://support.google.com/googleplay/android-developer/answer/9858738?hl=en
