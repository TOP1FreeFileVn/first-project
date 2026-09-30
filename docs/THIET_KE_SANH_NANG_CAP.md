# Thiết kế: Sảnh 5 nút & hệ thống nâng cấp

> Tài liệu thiết kế cho phần "ngoài trận" (meta) của Gear Defenders bản Godot.
> Mọi con số ở đây là **đề xuất ban đầu**, sẽ chỉnh lại bằng bot `tests/AutoPlay.tscn` và chơi thử.

---

## 0. Game gốc làm gì (tham khảo)

| Hệ thống gốc | Chi tiết đã xác nhận từ nguồn | Mức tin cậy |
|---|---|---|
| Tiền tệ | **Kim cương** (triệu hồi, nâng cấp; nhận từ nhiệm vụ ngày/tuần, rương tuần thứ 5 cho 300 kim cương) | Guide bên thứ 3 |
| Chicken legs | Bắt đầu 10, mỗi lính triệu hồi tốn 1, **nâng cấp thành để mở thêm** | Store + guide |
| Lính | 10+ loại; **lên cấp, lên sao, thăng hạng bằng thẻ trùng**; phần lớn lượt quay ra *mảnh/thẻ* chứ không ra lính hoàn chỉnh | Store + guide |
| Gacha | Legendary 4% · Epic 32% · Rare 64%; 10 lượt chắc chắn ra lính, 100 lượt chắc chắn ra Epic | Guide |
| Thành | Nâng cấp tăng máu, phòng thủ, mở chicken legs | Store + guide |
| Rương | Sau mỗi trận thắng; chứa vé gear, token nâng thành, thẻ lính | Guide |
| Khác | Vua + trang bị + ngọc, Tuần tra (sinh tài nguyên), Tường, Endless, Xếp hạng, Battle pass, quảng cáo x1.5 tốc độ | Store |

Vòng lặp của game gốc: **đánh màn → rương/vàng/thẻ → nâng lính & thành → màn khó hơn**, cộng thêm nhiệm vụ ngày để giữ người chơi quay lại.

Bản của mình giữ vòng lặp đó, bỏ phần kiếm tiền (quảng cáo, gói nạp, VIP, pass).

---

## 1. Ba vòng lặp

```
Vòng trận (3–5 phút)    : triệu hồi → ghép gear → giữ thành qua các đợt → thưởng
Vòng sảnh (mỗi lần mở)  : nhận thưởng tuần tra → mở rương → nâng lính/thành → đánh màn tiếp
Vòng ngày               : rương miễn phí + tuần tra nhanh + nhiệm vụ ngày (giai đoạn 2)
```

Mục tiêu nhịp độ: **mỗi 1–2 trận người chơi có ít nhất 1 thứ để nâng cấp** (chấm đỏ trên nút).

---

## 2. Tiền tệ & vật phẩm

| Loại | Kiếm từ | Dùng để | Ghi chú |
|---|---|---|---|
| **Vàng** 🪙 | Thắng/thua trận, tuần tra, đổi từ kim cương | Lên cấp lính, nâng thành, nâng xưởng | Tiền chính |
| **Kim cương** ◆ | 3 sao lần đầu, mốc màn, rương miễn phí (ít), nhiệm vụ | Mở rương xịn, tuần tra nhanh thêm, đổi vàng | Tiền hiếm |
| **Thẻ lính** (mỗi loại riêng) | Rương, rương sau trận | Mở khoá lính, **lên sao** lính | Giống "mảnh" của gốc |

Không có thể lực/năng lượng giới hạn số trận: chơi bao nhiêu tuỳ thích.

---

## 3. Năm nút ở sảnh

Thứ tự từ trái sang phải; **CHIẾN ĐẤU ở giữa, to nhất, là tab mặc định** khi mở game.

| # | Nút | Icon (từ Tiny Swords) | Chấm đỏ khi |
|---|---|---|---|
| 1 | **Cửa hàng** | Đồng vàng `Icons/Icon_03` | Có rương miễn phí |
| 2 | **Lính** | Chân dung `Human Avatars/Avatars_0x` | Có lính đủ vàng/thẻ để nâng |
| 3 | **CHIẾN ĐẤU** | Kiếm `Icons/Icon_05` | Có màn mới mở |
| 4 | **Thành** | `Buildings/Blue Buildings/Castle` | Đủ vàng nâng thành |
| 5 | **Tuần tra** | Kỵ thương `Units/Blue Units/Lancer` (khung đầu) | Kho tuần tra ≥ 50% |

### 3.1 Bố cục sảnh (720 × 1280)

```
y=0    ┌────────────────────────────────────────┐
       │ [Avatar]  🪙 1.250 [+]   ◆ 30 [+]   ⚙  │  Thanh tài nguyên, cao 84
y=84   ├────────────────────────────────────────┤
       │                                        │
       │          Nội dung trang (Control)      │  cao 1056, cuộn dọc nếu dài
       │                                        │
y=1140 ├──────┬──────┬──────────┬──────┬───────┤
       │ Cửa  │ Lính │ CHIẾN    │Thành │ Tuần  │  Thanh 5 nút, cao 140
       │ hàng │      │  ĐẤU     │      │  tra  │  4 nút thường rộng 136,
       └──────┴──────┴──────────┴──────┴───────┘  nút giữa rộng 176, nhô lên 24px
```

- Nút đang chọn: nền xanh sáng (`BigBlueButton`), icon phóng to 110%, hiện chữ. Nút khác: nền tối, chỉ icon + chữ nhỏ.
- Chuyển tab: trang cũ trượt ra, trang mới trượt vào (tween 0.15 s).
- `[+]` cạnh vàng/kim cương mở thẳng tab Cửa hàng.
- ⚙ Cài đặt (popup): âm lượng, rung, xoá dữ liệu (có hỏi xác nhận).

### 3.2 Trang CHIẾN ĐẤU

```
┌──────────────────────────────┐
│  [Ribbon] Màn 3 · Pháo Đài Đỏ│
│  ┌────────────────────────┐  │
│  │  Ảnh xem trước màn     │  │  Hình lính địch của màn + nền cỏ
│  │  Địch: 🗡 🏹 🐎 ✚      │  │  Icon các loại địch sẽ gặp
│  └────────────────────────┘  │
│  ★★☆   6 đợt                 │
│  Thưởng: 🪙 180  ◆ 10 (3★ lần đầu)
│  ◀  1  2  3  🔒4  🔒5  ▶     │  Dải chọn màn (nút tròn, màn khoá xám)
│      [   CHƠI   ]            │  Nút to nhất trang
└──────────────────────────────┘
```

### 3.3 Trang LÍNH

Danh sách thẻ lính dạng lưới 2 cột. Mỗi thẻ: chân dung (frame idle), tên, **Cấp**, **★ sao**, thanh thẻ `12/30`, khung màu theo độ hiếm.

Bấm vào một lính → **popup chi tiết**:

```
┌──────────────────────────────┐
│  [Ảnh lính lớn, animation]   │
│  Chiến binh     ★★☆  Cấp 7/20│
│  Máu     85 → 124  (+6)      │
│  Sát thương 8 → 11.7 (+0.6)  │
│  Tầm đánh 38 · Hồi chiêu 1.0s│
│  Mô tả: Đỡ đòn, giữ tuyến... │
│                              │
│ [Nâng cấp 🪙 409] [Lên sao 🃏 30/30] │
└──────────────────────────────┘
```

Lính chưa mở: ảnh tối + ổ khoá + "Cần 1 thẻ để mở".

### 3.4 Trang THÀNH

Phần trên: ảnh lâu đài lớn + **Cấp thành** + nút Nâng cấp (xem bảng 5.1).
Phần dưới: **Xưởng** gồm 3 dòng nâng cấp nhỏ (bảng 5.2), mỗi dòng: tên, cấp hiện tại, hiệu ứng hiện tại → cấp sau, giá, nút.

Phần giữa: **sơ đồ lưới 6×4 thu nhỏ** tô ô đã mở / ô khoá, để người chơi thấy nâng thành mở thêm ô gear.

### 3.5 Trang CỬA HÀNG

```
Rương Gỗ      Miễn phí mỗi 4 giờ        [MỞ] / 02:13:40
Rương Bạc     🪙 600                     [MỞ]
Rương Vàng    ◆ 120                      [MỞ]   Còn 7 lần nữa chắc chắn có thẻ Sử thi
Đổi vàng      ◆ 20 → 🪙 500               [ĐỔI]
```

Mở rương → màn hình mở rương: rương rung → bung → lật từng thẻ (tween), thẻ Sử thi có hiệu ứng sáng.

### 3.6 Trang TUẦN TRA

```
┌──────────────────────────────┐
│  Đội tuần tra đang đi...     │  Vài lính Blue chạy qua lại (animation run)
│  🪙 +240 / giờ               │  Tốc độ theo màn cao nhất đã qua
│  Kho: 🪙 1.130 / 1.920       │  Thanh đầy dần, tối đa 8 giờ
│  [ THU HOẠCH ]               │
│  [ Tuần tra nhanh (2h) ] 2/2 miễn phí hôm nay, sau đó ◆ 20
└──────────────────────────────┘
```

Tính theo **giờ thực**: lưu mốc thời gian lần thu hoạch cuối, lúc mở game tính phần tích luỹ (kể cả khi tắt game).

---

## 4. Nâng cấp lính

### 4.1 Độ hiếm & mở khoá

| Lính | Độ hiếm | Mở khoá | Thẻ khi mở rương |
|---|---|---|---|
| Nông dân | Thường | Có sẵn | 64% chia đều 3 lính Thường |
| Chiến binh | Thường | Có sẵn | |
| Cung thủ | Thường | Có sẵn | |
| Kỵ thương | Hiếm | Qua màn 1 (tặng 1 thẻ) hoặc thẻ từ rương | 32% |
| Tu sĩ | Sử thi | Qua màn 2 (tặng 1 thẻ) hoặc thẻ từ rương | 4% |

Tỉ lệ theo đúng game gốc (64 / 32 / 4). Khi có thêm lính mới, chỉ cần gắn độ hiếm là tự vào bảng rơi.

Chỉ lính **đã mở** mới xuất hiện khi triệu hồi trong trận (`troop_pool` của màn giao với danh sách đã mở).

### 4.2 Cấp (tốn vàng)

- Mỗi cấp: **+8% máu và sát thương** so với chỉ số gốc (cộng dồn tuyến tính: cấp 10 = +72%).
- Giá lên cấp `L → L+1` = `round(50 × 1.35^(L−1))` vàng:

| Lên cấp | 1→2 | 2→3 | 3→4 | 4→5 | 5→6 | 6→7 | 7→8 | 8→9 | 9→10 |
|---|---|---|---|---|---|---|---|---|---|
| Vàng | 50 | 68 | 91 | 123 | 166 | 224 | 303 | 409 | 552 |

- **Trần cấp theo sao**: 1★ tối đa cấp 10, 2★ tối đa 20, 3★ tối đa 30.

### 4.3 Sao (tốn thẻ, tương ứng "star up / promote" của gốc)

| Lên sao | Thẻ cần | Thưởng |
|---|---|---|
| 1★ → 2★ | 10 | ×1.2 chỉ số, trần cấp 20 |
| 2★ → 3★ | 30 | ×1.2 nữa, trần cấp 30 |

Công thức sức mạnh cuối cùng của 1 lính trong trận:

```
chỉ_số = gốc × (1 + 0.08 × (cấp − 1)) × 1.2^(sao − 1) × 1.75^(bậc_gear − 1)
```

> **Đổi tên cho khỏi nhầm:** trong trận hiện đang gọi cấp gear là "sao" ("Chiến binh lên 2 sao!").
> Sẽ đổi thành **"bậc"** ("Chiến binh lên bậc 2!"), để "sao" chỉ dùng cho lính ngoài sảnh và sao đánh giá màn.

---

## 5. Nâng cấp thành

### 5.1 Cấp thành (một đường duy nhất, giống gốc)

Mỗi cấp tăng máu thành, và một số cấp mở thêm **thịt tối đa** (chicken legs) và **ô lưới gear**.

| Cấp | Máu thành | Thịt tối đa | Ô gear mở | Giá (vàng) |
|---|---|---|---|---|
| 1 | 100 | 10 | 12 | — |
| 2 | 115 | 10 | 14 | 150 |
| 3 | 130 | 11 | 16 | 250 |
| 4 | 150 | 11 | 18 | 400 |
| 5 | 170 | 12 | 20 | 600 |
| 6 | 195 | 12 | 22 | 850 |
| 7 | 220 | 13 | 23 (đủ) | 1.200 |
| 8 | 250 | 13 | 23 | 1.650 |
| 9 | 285 | 14 | 23 | 2.200 |
| 10 | 320 | 15 | 23 | 3.000 |

- Máu thành ở bảng là **hệ số trên `core_hp` của màn** (100 = ×1.0, 150 = ×1.5), để màn khó vẫn đặt được máu gốc riêng.
- **Ô gear bị khoá** hiện ổ khoá trên lưới; ô mở theo vòng từ bánh răng tổng ra ngoài, để luôn nối được truyền động.
  Cấp 1 mở 12 ô quanh tổng, đủ cho lối chơi hiện tại (bot dùng 7–11 gear).

### 5.2 Xưởng (3 nâng cấp phụ)

| Nâng cấp | Mỗi cấp | Tối đa | Giá cấp n (vàng) |
|---|---|---|---|
| **Lò thịt** – hồi thịt nhanh | −6% thời gian hồi (1.6 s → 1.14 s ở cấp 5) | 5 | 120 × 1.6^(n−1) |
| **Kho dự trữ** – thịt khởi đầu | +1 thịt lúc vào trận | 4 | 100 × 1.8^(n−1) |
| **Bánh răng tổng** – quay nhanh | Gear sinh lính nhanh hơn 5% | 5 | 150 × 1.6^(n−1) |

"Bánh răng tổng" gắn trực tiếp vào cơ chế truyền động: bánh tổng quay nhanh hơn (hình ảnh), các gear ăn khớp quay theo, và thời gian sinh lính giảm.

---

## 6. Cửa hàng & rương

| Rương | Giá | Nội dung |
|---|---|---|
| **Gỗ** | Miễn phí, mỗi 4 giờ | 3 thẻ + 50–100 vàng |
| **Bạc** | 600 vàng | 8 thẻ |
| **Vàng** | 120 kim cương | 25 thẻ, **chắc chắn ≥ 3 thẻ Hiếm** |
| **Rương thắng trận** | Tự động sau mỗi trận thắng | 2 thẻ (+1 nếu 3★) |

- Mỗi thẻ: tung độ hiếm theo 64/32/4, rồi chọn ngẫu nhiên một lính trong độ hiếm đó.
- **Bảo hiểm (pity)** như gốc: đếm số rương Vàng đã mở; lần thứ 10 chắc chắn có ít nhất 1 thẻ Sử thi, rồi đếm lại.
- **Đổi vàng**: 20 kim cương → 500 vàng.
- Thẻ trùng của lính đã 3★: đổi thành vàng (mỗi thẻ 20 vàng) để không phí.

---

## 7. Thưởng sau trận

| | Công thức | Màn 1 | Màn 2 | Màn 3 |
|---|---|---|---|---|
| Thắng | `60 + 40 × số_màn` + `20 × số_sao` | 160 | 200 | 240 |
| Lần đầu qua màn | Vàng ×2 + mở màn sau + thẻ tặng (nếu có) | | | |
| 3★ lần đầu | +10 kim cương | | | |
| Thua | `15 × số_đợt_đã_qua` vàng | | | |

Bảng kết thúc trận (sửa `HUD.show_end`): hiện vàng/kim cương nhận được (đếm số chạy lên), rương thắng trận, nút **Về sảnh**, **Chơi lại**, **Màn tiếp**.

**Nhịp kinh tế mục tiêu (30 phút đầu):** qua màn 1–3, mở ~6 rương, nâng thành cấp 3–4, 2–3 lính chính cấp 4–5. Kiểm chứng bằng bot có áp nâng cấp.

---

## 8. Dữ liệu lưu (`user://save.json`)

```json
{
  "version": 1,
  "gold": 1250,
  "gems": 30,
  "levels": { "unlocked": 3, "stars": { "0": 3, "1": 2 } },
  "troops": {
    "pawn":    { "unlocked": true,  "level": 5, "stars": 1, "cards": 7 },
    "lancer":  { "unlocked": false, "level": 1, "stars": 1, "cards": 0 }
  },
  "castle":   { "level": 3 },
  "workshop": { "meat_regen": 2, "start_meat": 1, "master_gear": 0 },
  "shop":     { "free_chest_at": 1780000000, "gold_chest_pity": 4 },
  "patrol":   { "last_claim": 1780000000, "quick_left": 2, "quick_day": 20360 }
}
```

- Tự chuyển dữ liệu từ `progress.cfg` cũ (số màn mở, sao) sang file mới lần đầu.
- Ghi file sau mỗi thay đổi quan trọng (mua, nâng cấp, kết thúc trận); ghi ra file tạm rồi đổi tên để không hỏng save khi tắt đột ngột.
- Thời gian dùng `Time.get_unix_time_from_system()`; nếu đồng hồ máy lùi lại thì không trừ, chỉ bỏ qua.

---

## 9. Kiến trúc code

```
game/
  core/
    PlayerData.gd       autoload, thay GameState: tiền, lính, thành, xưởng, cửa hàng,
                        tuần tra, tiến độ màn; tính toán giá & hệ số; lưu/đọc save.json
                        signal: currency_changed, troop_changed, castle_changed
    Economy.gd          hằng số & công thức (giá, thưởng, tỉ lệ rơi) để chỉnh ở 1 chỗ
    SpriteLib.gd        (có sẵn)
  data/
    TroopData.gd        + rarity, description
    upgrades/           UpgradeData.tres cho 3 nâng cấp xưởng (id, tên, max, giá, hiệu ứng)
  ui/
    UiKit.gd            tách theme/nút/ribbon/paper/icon từ HUD.gd để dùng chung
    HUD.gd              (có sẵn) + bảng thưởng sau trận
  menu/
    Home.tscn / Home.gd thanh tài nguyên + vùng trang + thanh 5 nút; main scene mới
    NavBar.gd           5 nút, chấm đỏ, hiệu ứng chọn
    pages/ShopPage.gd, TroopsPage.gd, BattlePage.gd, CastlePage.gd, PatrolPage.gd
    popups/TroopDetail.gd, ChestOpen.gd, Settings.gd
```

Nguyên tắc:
- **Trang chỉ đọc PlayerData và gọi hàm của nó**, không tự tính giá hay sửa số. Mọi logic nằm trong PlayerData/Economy, nên dễ kiểm thử.
- **Battle chỉ hỏi hệ số** khi bắt đầu trận: `PlayerData.troop_multiplier(id)`, `core_hp_multiplier()`, `max_meat()`, `meat_regen_time()`, `start_meat_bonus()`, `unlocked_cells()`, `spawn_speed_bonus()`. Không phụ thuộc vào menu.
- Chuyển cảnh: `Home → Battle` qua `change_scene_to_file`; Battle kết thúc gọi `PlayerData.grant_battle_rewards(...)` rồi về Home, mở sẵn tab CHIẾN ĐẤU.

### Chỗ cần sửa trong code trận hiện có

| File | Thay đổi |
|---|---|
| `Core.gd` | `MAX_MEAT`, `MEAT_REGEN_TIME` thành biến, lấy từ PlayerData; máu nhân hệ số |
| `Battle.gd` | Nhân chỉ số lính theo cấp/sao; lọc `troop_pool` theo lính đã mở; gửi thưởng; nút về sảnh |
| `GearBoard.gd` | Ô khoá theo cấp thành (vẽ ổ khoá, không cho đặt/triệu hồi vào); tốc độ quay theo xưởng |
| `Gear.gd` | Tốc độ sinh lính nhân `spawn_speed_bonus` |
| `HUD.gd` | Đổi "sao" → "bậc" cho gear; bảng thưởng; tách phần theme sang UiKit |
| `tests/AutoPlay.gd` | Tham số `--castle=3 --troop-level=5` để kiểm thử cân bằng với nâng cấp |

---

## 10. Lộ trình & tiêu chí xong

| Bước | Nội dung | Xong khi |
|---|---|---|
| **1. Dữ liệu** | PlayerData + Economy + save.json + chuyển save cũ | Unit test headless: nâng cấp trừ tiền đúng, lưu/đọc lại khớp |
| **2. Sảnh** | Home, thanh tài nguyên, thanh 5 nút (4 trang tạm để trống), trang CHIẾN ĐẤU | Mở game vào sảnh → chọn màn → đánh → về sảnh, tiền tăng |
| **3. Thưởng trận** | Công thức thưởng, bảng kết thúc mới, rương thắng trận | Thắng/thua đều nhận thưởng đúng bảng 7 |
| **4. Thành** | Cấp thành + xưởng + ô khoá trên lưới | Nâng thành → vào trận thấy máu/thịt/ô tăng |
| **5. Lính** | Danh sách, popup chi tiết, lên cấp, lên sao, mở khoá | Lính cấp cao đánh mạnh hơn (bot xác nhận) |
| **6. Cửa hàng** | 3 rương + đổi vàng + màn mở rương + bảo hiểm | Mở 100 rương giả lập: tỉ lệ ≈ 64/32/4 |
| **7. Tuần tra** | Tích vàng theo giờ thực, thu hoạch, tuần tra nhanh | Chỉnh đồng hồ giả lập +3h → nhận đúng vàng |
| **8. Cân bằng** | Chạy bot với nhiều mức nâng cấp; thêm màn 4–10 | Màn n thắng được khi nâng cấp ở mức "30 phút chơi" |

Giai đoạn 2 (sau khi 8 bước trên ổn): nhiệm vụ ngày/tuần (thưởng kim cương), âm thanh, hướng dẫn chơi lần đầu, thêm loại lính (khiên, pháp sư), thêm phe địch.

---

## 11. Đã chốt (bản đầu)

1. Nút thứ 5: **Tuần tra**.
2. Dùng cả **vàng và kim cương** (bắt đầu với 30 kim cương).
3. **Có khoá ô lưới theo cấp thành** (12 ô ở cấp 1 → đủ 23 ô ở cấp 7).
4. **10 màn**. Màn 4–10 được sinh theo công thức (xem lịch sử tạo trong `game/data/levels/`).

### Kết quả cân bằng bằng bot (`tests/AutoPlay.tscn`)

"Nâng cấp dự kiến" là mức người chơi thường có khi tới màn đó.

| Màn | Sức mạnh địch | Không nâng cấp | Nâng cấp dự kiến (thành / cấp lính / sao) | Kết quả |
|---|---|---|---|---|
| 1–3 | 0.9 / 2.0 / 1.5 | Thắng | — | Thắng |
| 4 | 1.9 | Thắng (thành còn 42%) | 3 / 4 / 1★ | Thắng |
| 5 | 2.2 | Thua | 4 / 5 / 1★ | Thắng |
| 6 | 2.3 | Thua | 4 / 7 / 1★ | 1 thắng, 1 thua |
| 7 | 2.5 | Thua | 5 / 8 / 1★ | 1 thắng, 1 thua |
| 8 | 2.8 | Thua | 6 / 10 / 2★ | Thắng |
| 9 | 3.0 | Thua | 7 / 12 / 2★ | Thắng |
| 10 | 3.0 | Thua | 8 / 14 / 2★ | Thắng |

Bot ghép gear ngay lập tức nên chơi giỏi hơn người thật; cần chơi thử để chỉnh tiếp.

## Nguồn

- [Gear Defenders – App Store](https://apps.apple.com/us/app/gear-defenders/id6740892835)
- [Gear Defenders – Google Play](https://play.google.com/store/apps/details?id=com.iogame.gearworld)
- [Gear Defenders Beginner Guide – Clashiverse](https://clashiverse.com/gear-defenders-beginner-guide/)
- [Gear Defenders Tips & Strategy – TopGames](https://www.topgames.com/walkthrough/Gear-Defenders-Tips-Cheats-And-Strategy-Guide)
- [Gear Defenders – QooApp](https://m-apps.qoo-app.com/en_us/app/145474?locale=en-US)
