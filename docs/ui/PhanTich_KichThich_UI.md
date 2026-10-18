# Phân tích: các yếu tố UI kích thích người chơi

Tài liệu cho nhóm thiết kế game mèo thủ thành. Dựa trên ảnh chạy thật của GearPaw và Gear Defenders (Figma, page "Bố cục toàn màn") và các nghiên cứu về tâm lý người chơi. Màn minh hoạ: `tests/ui/HomePreview.tscn` (mỗi yếu tố có chú thích trong `HomePreview.gd`).

**Về độ tin cậy của nguồn:** phần "game feel" và "dark patterns" có nghiên cứu khoa học (bài hội thảo, có thực nghiệm). Phần về chấm đỏ, FOMO, phần thưởng ngẫu nhiên trong game di động chủ yếu là bài phân tích của người làm nghề; cơ chế tâm lý gốc (Skinner, Zeigarnik, hiệu ứng tiến gần mục tiêu) thì đã được nghiên cứu lâu, nhưng mức tác động trong game cụ thể thì chưa có số liệu chắc chắn.

## 1. Bảy cơ chế mà hai game dùng

| # | Cơ chế | Nghĩa | Hai game làm thế nào | Màn sảnh của mình |
|---|---|---|---|---|
| 1 | **Nổi bật (salience)** | Mắt nhìn vào thứ to, sáng, chuyển động trước | Nút "Trận chiến" to nhất màn, vàng, có giá năng lượng; mọi thứ khác nhỏ và ở mép | Nút chính 330×108, vàng, "thở" nhẹ (phóng 4% mỗi 1,4 giây) |
| 2 | **Việc dang dở (hiệu ứng Zeigarnik)** | Việc chưa xong đọng lại trong đầu lâu hơn việc đã xong | Chấm đỏ "!" khắp nơi: cửa hàng, tướng, nhiệm vụ, hộp thư | Chấm đỏ ở 5 chỗ; "Nhiệm vụ 3/5" |
| 3 | **Càng gần đích càng cố (goal gradient)** và **tiến độ được tặng sẵn (endowed progress)** | Người ta tăng tốc khi thấy mình sắp xong; tiến độ có sẵn làm dễ bắt đầu hơn | Thanh EXP, "(4/4)", mốc sóng 1-2-3 có dấu tick, rương ở mốc kế tiếp | EXP 86%; 2/3 sóng đã tick; "Còn 1 sóng mở rương!" |
| 4 | **Phần thưởng không đoán trước (tỉ lệ biến thiên, Skinner)** | Thưởng ngẫu nhiên giữ hành vi bền hơn thưởng cố định | Triệu hồi, rút thẻ, rương, bong bóng "Triệu hồi 10" | Bong bóng "Triệu hồi miễn phí!" nhún nhảy trên tab |
| 5 | **Khan hiếm và thời gian** | Thứ sắp mất trông giá trị hơn | "Gói Thời Gian Giới Hạn 23:58:06", "Quà Hạn Giờ 2 ngày 23h" | "Gói giới hạn" với đồng hồ đếm ngược thật |
| 6 | **Sợ mất (loss aversion) qua chuỗi ngày** | Mất chuỗi đang có đau hơn được thêm một ngày | Điểm danh, quà online theo giờ | "Điểm danh · Ngày 6/7", "Quà online 04:12" |
| 7 | **Mục tiêu tiếp theo luôn trong tầm mắt** | Thấy cái kế tiếp thì muốn mở | Ải bị khoá ló ở hai mép màn, "Lv.10 Mở khóa" trong shop | Ải 1-2 và 1-4 khoá ló hai bên nút chính |

Ngoài ra là **game feel / "juice"**: mọi lần chạm phải có phản hồi ngay (nút lún xuống, âm click, rung, hạt sáng khi nhận thưởng). Phần này hiện mới có nút lún và âm click.

## 2. Bố cục đặt các cơ chế ở đâu

Cả hai game dùng cùng một công thức, và màn sảnh mới làm theo:

- **Giữa màn = một chủ thể** (đảo ải có mèo anh hùng). Không có gì đè lên.
- **Hai cột bên = các "móc" quay lại** (thông hành, VIP, gói giờ; nhiệm vụ, quà online, điểm danh). Nhỏ, có chấm đỏ và đồng hồ, để mắt lướt qua sau khi đã thấy chủ thể.
- **Dưới chủ thể = tiến độ và phần thưởng gần** (sóng 1-2-3, rương).
- **Nút chính** ngay trên thanh dưới, chỗ ngón cái chạm dễ nhất.
- **Thanh trên và thanh dưới cố định** ở mọi màn.

## 3. Nghiên cứu nói gì, và lưu ý

**Game feel ("juiciness").** Hicks, Gerling và Dickinson đưa ra định nghĩa dựa trên khảo sát và chỉ ra còn ít nghiên cứu thực nghiệm. Các nghiên cứu sau cho kết quả hai chiều:
- Hiệu ứng nhiều thường làm người chơi thích hơn. Ví dụ rung phản hồi tăng độ thích thú và nhập tâm (Singhal & Schneider, CHI 2021).
- Nhưng hiệu ứng quá nhiều, hoặc không gắn với thành công thật, có thể **làm giảm cảm giác "mình giỏi"**, thậm chí làm chơi kém đi (một nghiên cứu 2016 so hai bản game giống hệt nhau, chỉ khác lượng phản hồi).
- Bài học: hiệu ứng to nhất dành cho lúc người chơi thật sự làm được việc (thắng sóng, ghép bánh răng cấp cao), không rải đều khắp nơi.

**Dark patterns (mẫu thiết kế gây hại).** Zagal, Björk và Lewis (2013) định nghĩa đây là thiết kế cố ý làm hại lợi ích người chơi mà họ không biết. Có ba nhóm:
- **Thời gian:** bắt đăng nhập theo giờ hẹn, chơi theo lịch.
- **Tiền:** gây nhầm lẫn về giá, ép mua.
- **Xã hội:** lợi dụng bạn bè.

Nghiên cứu sau (Niknejad và cộng sự 2024, trên dữ liệu 1.496 game) bổ sung nhóm tâm lý. Theo khung này:
- Đồng hồ đếm ngược, điểm danh, quà online (cơ chế 5–6) là dạng **"chơi theo lịch hẹn"**, thuộc nhóm thời gian.
- Chấm đỏ ở mọi nơi và gói giới hạn giờ dễ trượt sang thao túng.

**Đề xuất cho bản demo của nhóm:**
1. Giữ 1–4 và 7 (nổi bật, việc dang dở có thật, tiến độ, mục tiêu kế tiếp). Đây là thiết kế rõ ràng, giúp người chơi biết làm gì tiếp.
2. Chấm đỏ chỉ hiện khi **thật sự có việc làm được ngay** (có quà nhận, có nâng cấp đủ tiền). Không hiện cố định.
3. Đồng hồ và gói giới hạn: chỉ để minh hoạ. Không thêm hình phạt khi bỏ lỡ ngày điểm danh (cho bù ngày).
4. Phần thưởng ngẫu nhiên: luôn hiện tỉ lệ và mốc bảo đảm ("chắc chắn ra lính truyền thuyết sau 79 lần"), như Gear Defenders đã làm.
5. Hiệu ứng: nút lún và âm click cho mọi nút; hiệu ứng lớn (hạt sáng, rung màn hình) chỉ khi thắng, ghép cấp cao, mở rương.

## 4. Việc tiếp theo có thể làm

- Thêm "juice" có chủ đích: số vàng chạy lên khi nhận, rương lắc khi mở được, nút chính loé sáng khi đủ năng lượng.
- Làm lại màn cửa hàng theo bố cục thẻ ưu đãi lớn và lưới, và màn chọn kỹ năng (2–3 thẻ ngang hàng) theo cùng nguyên tắc.

## Nguồn

- Hicks, Gerling, Dickinson. *What makes a Game? Reflections on Juiciness and Player Experience*: [figshare](https://figshare.com/articles/Kieran_Hicks_Kathrin_Gerling_Patrick_Dickinson_-_What_makes_a_Game_Reflections_on_Juiciness_and_Player_Experience_/5147011)
- Singhal & Schneider (CHI 2021). *Juicy Haptic Design*: [Univ. Waterloo](https://uwaterloo.ca/haptic-experience-lab/projects/juicy-haptic-design-vibrotactile-embellishments-can-improve)
- *Good feedback for bad players? A preliminary study of juicy interface feedback*: [Elsevier Pure](https://adk.elsevierpure.com/en/publications/good-feedback-for-bad-players-a-preliminary-study-of-juicy-interf)
- Tóm tắt nghiên cứu về hiệu ứng "juicy" và cảm giác năng lực: [psych.substack](https://psych.substack.com/p/the-juicy-factor-the-science-of-making)
- Niknejad và cộng sự (2024). *Level Up or Game Over: Exploring How Dark Patterns Shape Mobile Games*: [arXiv](https://arxiv.org/abs/2412.05039)
- Dark patterns trong game (DiGRA 2020): [White Rose eprints](https://eprints.whiterose.ac.uk/156460/1/DiGRA_2020_paper_189.pdf)
- Phân loại dark patterns trong game dịch vụ: [deceptive.design](https://deceptive.design/articles/designing-for-monetization-a-taxonomy-of-dark-patterns-in-top-grossing-gaas-video-games)
- Bài phân tích của người làm nghề (không phải nghiên cứu): [game-wisdom: randomized rewards](https://game-wisdom.com/general/invisible-pull-randomized-rewards-mobile-games), [nerdbot: daily rewards](https://nerdbot.com/2026/08/19/the-psychology-behind-daily-rewards-in-video-games/)
