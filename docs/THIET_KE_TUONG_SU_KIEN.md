# Thiết kế: Tướng, Sự kiện, Quà 7 ngày, Nhiệm vụ, Ảnh đại diện

## 1. Chiến lược làm thêm lính khi sprite không đủ

Bộ Tiny Swords (bản miễn phí) chỉ có 5 loại người (Warrior, Archer, Lancer, Monk, Pawn)
trong 5 màu áo (Blue, Red, Black, Purple, Yellow). Thứ tự ưu tiên, từ rẻ đến đắt:

| # | Cách | Tốn công | Đã dùng ở |
|---|------|----------|-----------|
| 1 | **Ghép lại cái có sẵn**: cùng người nhưng đổi đồ cầm (Pawn có rìu, cuốc, búa, dao, thịt, vàng), đổi đòn đánh (Warrior Attack1/Attack2/Guard), đổi màu áo, tint, cỡ to nhỏ | rất thấp | Thợ mỏ, Thợ rèn, Sát thủ, Đầu bếp, Pháo thủ, Hiệp sĩ khiên, Tướng quân |
| 2 | **Shader đổi màu (palette swap)**: chỉ đổi phần màu đội (vùng xanh của áo Blue) sang bất kỳ màu nào, giữ nguyên da, tóc, kim loại. Vô số biến thể: bạch kim, lục bảo, hoả ngục, bóng đêm... | thấp | **Tướng** (`game/ui/recolor.gdshader`) |
| 3 | **Phụ kiện vẽ bằng code phủ lên sprite**: vương miện, hào quang, áo choàng, vũ khí phát sáng, hạt lửa/băng bay quanh | thấp–vừa | vương miện Huyền thoại, áo choàng + hào quang của tướng |
| 4 | **Hiệu ứng thay cho animation mới**: đòn đặc biệt thể hiện bằng effect (nổ, lửa, bụi, hồi máu) thay vì vẽ động tác mới | thấp | đòn nổ Pháo thủ, cháy Cung lửa |
| 5 | **Sửa file Aseprite gốc** (pack có sẵn thư mục `Units (aseprite in Blue only)`): nhân bản Warrior, vẽ lại lớp vũ khí/mũ, giữ khung 192px và bảng màu, xuất strip | vừa | chưa (khi cần dáng hoàn toàn mới) |
| 6 | **Mua bản đầy đủ Tiny Swords** của Pixel Frog: có thêm phe Goblin (Torch, TNT, Barrel...), cùng nét vẽ. Giải pháp tốt nhất cho **quái** | tiền | chưa |
| 7 | Thuê hoạ sĩ vẽ theo đúng bảng màu và khung hình của pack | cao | chưa |

Không nên dùng ảnh AI tạo ra để trộn với pixel art: lệch nét, lệch bảng màu, khó làm animation.

Quy tắc giữ nhận diện khi tái sử dụng sprite:
- **Hình dáng khác trước, màu khác sau.** Hai lính cùng sprite phải khác nhau rõ ở đồ cầm,
  cỡ người, hoặc hiệu ứng; màu chỉ để phân bậc (Blue → Purple → Yellow khi lên bậc gear).
- **Tướng luôn có hào quang và màu riêng** (shader), nên không bao giờ nhầm với lính thường.
- Phe địch dùng Red/Black, phe ta Blue/Purple/Yellow. Không đổi màu phe.

## 2. Hệ thống Tướng

- 6 tướng, 3 độ hiếm (Hiếm / Sử thi / Huyền thoại). Mỗi tướng là một sprite lính có sẵn
  được đổi màu bằng shader, và có **một buff cho cả đội**:
  - `hp`: máu lính;
  - `damage`: sát thương;
  - `spawn`: tốc độ sinh lính;
  - `income`: thịt mỗi đợt;
  - `core`: máu thành.
- Chọn **1 tướng dẫn đội**. Buff áp dụng suốt trận.
- **Tướng ra trận đánh thật:** xuất hiện từ giữa tường thành, đánh theo kiểu lính gốc
  (Hiệp sĩ khiên, Kỵ thương, Cung lửa, Tu sĩ, Sát thủ...) nhưng máu x4,5 và sát thương x2,5
  ở cấp 1, tăng theo cấp và sao. Tướng ngã thì quay lại ở đợt sau.
- **Ngoại hình riêng không cần sprite mới:**
  - to gấp 1,5 lần lính;
  - giáp đổi màu bằng shader;
  - **áo choàng** màu riêng tung bay khi chạy;
  - vòng hào quang màu độ hiếm dưới chân, thanh máu vàng, vương miện cho Huyền thoại.
- **Lên cấp:** tốn vàng. Trần cấp = sao × 10.
- **Lên sao:** tốn mảnh tướng (10/20/40/80), tối đa 5 sao. Mỗi sao tăng buff gốc thêm 25%.
- **Mở khoá tướng:** 30 mảnh. Có lại tướng đã sở hữu thì đổi thành 20 mảnh.
- Người chơi mới có sẵn **Đội Trưởng Thép** (Hiếm).

## 3. Sự kiện Triệu hồi Tướng quân (gacha)

- **Tướng nổi bật** đổi mỗi tuần, xoay vòng qua các tướng Sử thi / Huyền thoại. Có đồng hồ
  đếm ngược đến lúc kết thúc.
- **Giá:** 30 kim cương 1 lượt, 270 cho 10 lượt. Mỗi ngày có 1 lượt miễn phí.
- **Bảng tỉ lệ:**

  | Kết quả | Tỉ lệ |
  |---|---|
  | Tướng nổi bật | 1,5% |
  | Tướng Huyền thoại khác | 1% |
  | Tướng Sử thi | 6% |
  | Tướng Hiếm | 15% |
  | 5 mảnh tướng nổi bật | 8% |
  | 3 mảnh tướng ngẫu nhiên | 20% |
  | Vàng | 48,5% |

- **Bảo hiểm:** 50 lượt chưa ra tướng nổi bật thì lượt tiếp theo chắc chắn ra. Mỗi gói 10
  lượt chắc chắn có ít nhất một tướng.
- **Hoạt ảnh:** vòng triệu hồi, tia sáng theo màu độ hiếm, lật thẻ, thẻ Huyền thoại có
  chữ lớn.

## 4. Sự kiện (thay tab Tuần tra)

- Tab thứ 5 ở thanh dưới giờ là **Tướng**.
- **Tuần tra** chuyển vào nút **Sự kiện** trên màn Chiến đấu, cùng với Triệu hồi Tướng.
- Nút Sự kiện có chấm đỏ khi kho tuần tra đầy một nửa hoặc còn lượt triệu hồi miễn phí.

## 5. Quà đăng nhập 7 ngày

- Mỗi ngày (theo ngày trên máy) nhận một phần, lần lượt từ ngày 1 đến ngày 7:

  | Ngày | Quà |
  |---|---|
  | 1 | 300 vàng |
  | 2 | 20 kim cương |
  | 3 | 8 thẻ lính |
  | 4 | 10 mảnh tướng nổi bật |
  | 5 | 50 kim cương |
  | 6 | 1.500 vàng |
  | 7 | **Tướng Hiền Giả Lục Diệp** (Sử thi) |

- Bỏ lỡ một ngày không mất chuỗi: hôm sau nhận tiếp phần kế.
- Xong 7 ngày thì chuỗi bắt đầu lại và mở khung ảnh đại diện Vàng.

## 6. Nhiệm vụ hằng ngày

- **6 nhiệm vụ**, làm mới lúc 0h:
  - Đăng nhập;
  - Thắng 2 trận;
  - Mở 1 rương;
  - Nâng cấp 2 lần;
  - Thu hoạch tuần tra;
  - Triệu hồi 1 lần.
- Mỗi nhiệm vụ cho **quà riêng** và **20 điểm năng động**.
- **Mốc điểm** có rương quà: 40 điểm (vàng), 80 điểm (kim cương), 120 điểm (mảnh tướng
  nổi bật).

## 7. Ảnh đại diện

- **Chạm vào ảnh đại diện** ở góc trái trên để mở hồ sơ:
  - đổi tên;
  - chọn ảnh, khung;
  - xem thành tích (màn đã qua, tổng sao, sức mạnh đội, số tướng).
- **25 ảnh** của pack (5 kiểu × 5 màu):
  - 2 hàng đầu mở sẵn;
  - hàng 3, 4, 5 mở khi qua 3, 6, 9 màn;
  - chân dung **tướng** đã sở hữu cũng dùng làm ảnh được.
- **4 khung:**

  | Khung | Điều kiện |
  |---|---|
  | Gỗ | Mặc định |
  | Bạc | Qua 3 màn |
  | Vàng | Nhận đủ quà 7 ngày |
  | Hoàng gia | Có tướng Huyền thoại |

## 8. File

| File | Nội dung |
|---|---|
| `game/core/Heroes.gd` | Tướng, buff, giá, bảng triệu hồi |
| `game/core/Meta.gd` | Quà 7 ngày, nhiệm vụ, avatar, khung |
| `game/ui/recolor.gdshader` | Shader đổi màu đội |
| `game/menu/pages/HeroesPage.gd` | Tab Tướng |
| `game/menu/pages/SummonPage.gd` | Sự kiện triệu hồi |
| `game/ui/SummonOpening.gd` | Hoạt ảnh triệu hồi |
| `game/menu/popups/*.gd` | Sự kiện, Quà 7 ngày, Nhiệm vụ, Hồ sơ |
| `PlayerData` | Lưu `heroes`, `hero`, `summon`, `login`, `quests`, `profile` |
