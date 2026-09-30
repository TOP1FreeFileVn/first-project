# Thiết kế: nghỉ giữa đợt, mua gear từ shop (bỏ triệu hồi ngẫu nhiên)

**Trạng thái: ĐÃ LÀM XONG A → D** theo các đề xuất ở mục 8. Xem mục 9 để biết kết quả và những con số đã đổi khi cân bằng.

---

## 1. Hiện tại và thay đổi

| | Hiện tại | Đề xuất |
|---|---|---|
| Có gear bằng cách | Bấm TRIỆU HỒI → ra **1 gear ngẫu nhiên** trong đội | **Shop** bày 5 gear, người chơi **tự chọn** mua cái nào |
| Nhịp trận | Chuẩn bị 1 lần, sau đó các đợt chạy liền nhau (đợt sau tự tới khi hết đợt trước hoặc sau `gap` giây) | Luân phiên **NGHỈ (mua sắm) → ĐÁNH → NGHỈ → ĐÁNH…** |
| Thịt | Tự hồi theo thời gian, giá triệu hồi tăng dần | **Thu nhập theo đợt** + thịt khi giết địch + **lãi** nếu để dành |
| Lúc nào mua | Bất cứ lúc nào | Chỉ trong lượt nghỉ |

Giữ nguyên: bàn 6×4, bánh răng tổng, bánh răng cạnh nhau mới quay, ghép 2 gear giống nhau lên bậc, kéo gear vào ô BÁN.

---

## 2. Vòng lặp một màn

```
Vào màn ─► NGHỈ 1 ─► ĐÁNH đợt 1 ─► NGHỈ 2 ─► ĐÁNH đợt 2 ─► … ─► ĐÁNH đợt cuối ─► Thắng
             │                       │
             └ shop, xếp, ghép, bán  └ nhận thu nhập, shop làm mới, rồi lại mua sắm
```

### 2.1 Lượt NGHỈ

- **Không có địch**, thời gian trận dừng. Gear không sinh lính, lính còn sống đứng yên tại chỗ.
- Shop mở ở nửa trên màn hình (vùng sân trống lúc nghỉ, xem mockup mục 5).
- Người chơi được làm:
  - **Mua** gear: gear đặt vào ô trống gần bánh răng tổng nhất, giống cách đặt gear hiện nay.
  - **Kéo, ghép, bán** gear trên bàn như bây giờ.
  - **ĐỔI SHOP** (tốn thịt) để làm mới 5 món.
  - **KHOÁ SHOP** để giữ nguyên 5 món sang lượt nghỉ sau.
- Bấm **SẴN SÀNG ▶** để bắt đầu đợt.
- **Giới hạn thời gian** tuỳ chọn (xem mục 8, câu 1). Mặc định: **không giới hạn**, người chơi nghỉ bao lâu tuỳ ý.

### 2.2 Lượt ĐÁNH

- Địch ra theo danh sách đợt như hiện tại. Gear quay và sinh lính.
- **Không mua được**, nhưng vẫn **kéo, ghép, bán** được (cho người chơi việc để làm, và để cứu tình huống).
- Đợt **kết thúc khi đã ra hết địch và giết hết**.
  - `gap` trong dữ liệu màn không còn dùng để gọi đợt sau. Nó thành "thời gian tối đa của đợt": hết giờ mà địch còn sống thì địch vẫn ở lại đánh tiếp, nhưng lượt nghỉ vẫn mở.
- Hết đợt: **lính còn sống được giữ lại**, trở về vị trí tập trung. Nhận **thu nhập**, rồi sang lượt nghỉ tiếp theo.

---

## 3. Kinh tế trong trận (thịt)

Thịt vẫn là tiền trong trận nhưng **không tự hồi theo thời gian** nữa.

| Nguồn | Mặc định đề xuất | Ghi chú |
|---|---|---|
| Thịt đầu trận | `start_meat` của màn + Kho dự trữ | Như cũ; đủ mua 2–3 gear ở lượt nghỉ 1 |
| Thu nhập mỗi đợt | **5 + số thứ tự đợt** (đợt 1 xong: +6, đợt 2 xong: +7…) | Công thức `round_income`, sửa được trong admin |
| Lãi | **+1 thịt cho mỗi 5 thịt để dành, tối đa +3** | Thưởng người biết tiết kiệm (kiểu TFT) |
| Giết địch | 0,35 thịt/địch, tinh nhuệ 3 thịt | Như cũ |
| Bán gear | Hoàn **75%** giá trị (giá bậc 1 × 2^(bậc−1)), tối thiểu 1 | Hiện chỉ hoàn số thịt = bậc |
| Đầu bếp | +1 thịt / 6 giây trong lúc đánh | Kỹ năng cũ vẫn có giá trị |
| Giới hạn thịt | Theo cấp thành: **20 → 30** (gấp đôi trước đây) | Chặn việc tích trữ quá nhiều |

**Giá shop:**

| Loại | Giá (thịt) |
|---|---|
| Gear Thường | 2 |
| Gear Hiếm | 3 |
| Gear Sử thi | 4 |
| Gear Huyền thoại | 6 |
| Đổi shop | 1 (lượt đổi đầu tiên mỗi lượt nghỉ miễn phí) |

Công thức `summon_cost` cũ được thay bằng bảng giá trên và công thức `reroll_cost`.

---

## 4. Shop bày gì

- **5 ô**, mỗi ô là **1 gear bậc 1**, lấy ngẫu nhiên **chỉ trong các lính của đội hình**. Đội hình vì vậy càng quan trọng.
- **Tỉ lệ độ hiếm tăng theo đợt**. Bảng `shop_odds` sửa được trong admin:

  | Đợt | Thường | Hiếm | Sử thi | Huyền thoại |
  |---|---|---|---|---|
  | 1–2 | 80% | 20% | 0% | 0% |
  | 3–4 | 60% | 32% | 8% | 0% |
  | 5–6 | 45% | 35% | 16% | 4% |
  | 7+ | 35% | 35% | 22% | 8% |

  Đội không có lính ở độ hiếm được bốc ra thì bốc lại trong các độ hiếm mà đội có.
- **Từ đợt 5**, 1 trong 5 ô có thể là **gear bậc 2** (xác suất 15%), giá gấp 2,5 lần. Tạo khoảnh khắc "trúng lớn".
- **Gợi ý ghép**: món nào đã có gear giống trên bàn thì hiện nhãn **"GHÉP ĐƯỢC"** màu xanh. Người chơi thấy ngay nên mua gì.
- `summon_weight` của lính dùng làm trọng số trong cùng độ hiếm, như hiện nay.

---

## 5. Giao diện (màn dọc 720×1280)

```
┌──────────────────────────────────────┐
│ ←  Màn 5 · Hẻm Núi            x1     │  thanh trên (như cũ)
│ ♜ ████████ 234   ⚔ Đợt 3/6   🍖 9/12 │
├──────────────────────────────────────┤
│        LƯỢT NGHỈ · Đợt 3 sắp tới     │  ribbon
│  Đợt tới: 👤x9 🛡x5 🏹x7  ⭐tinh nhuệ  │  xem trước quân địch
│ ┌────┐┌────┐┌────┐┌────┐┌────┐       │
│ │Sát ││Thợ ││Tướng││Cung││Thợ │       │  5 thẻ gear: chân dung, tên,
│ │thủ ││mỏ  ││quân ││lửa ││mỏ  │       │  khung màu độ hiếm, giá 🍖
│ │🍖3 ││🍖2 ││🍖6  ││🍖3 ││🍖2 │       │  nhãn "GHÉP ĐƯỢC" nếu có
│ └────┘└────┘└────┘└────┘└────┘       │
│  [ĐỔI SHOP 🍖1]  [🔒 KHOÁ]  Lãi: +1   │
│  Hết đợt nhận: +7 thịt (+1 lãi)       │
├──────────── tường thành ─────────────┤
│   bàn gear 6×4 + bánh răng tổng       │  như cũ, kéo/ghép/bán được
│                                       │
├──────────────────────────────────────┤
│ [BÁN]      [   SẴN SÀNG ▶ ĐỢT 3   ]   │  nút TRIỆU HỒI → SẴN SÀNG
└──────────────────────────────────────┘
```

- Mua bằng cách **chạm thẻ**: thẻ bay xuống ô trống trên bàn. Có thể làm thêm **kéo thẻ thả vào ô cụ thể**.
- Không đủ thịt thì thẻ mờ đi và hiện giá màu đỏ. Bàn đầy thì báo "Bàn đầy, hãy ghép hoặc bán".
- Lượt ĐÁNH: shop trượt lên và biến mất. Nút dưới cùng thành "ĐANG ĐÁNH · còn 12 địch" (không bấm được).
- Hết đợt: chữ "+7 thịt" bay vào thanh thịt, rồi shop trượt xuống.

---

## 6. Ảnh hưởng tới phần khác

| Phần | Thay đổi |
|---|---|
| `WaveDirector` | Không tự gọi đợt sau. Phát tín hiệu `wave_cleared`; `Battle` chuyển sang phase `"shop"`. Đợt sau chỉ bắt đầu khi bấm SẴN SÀNG |
| `Battle` | Các phase: `shop` → `fight` → `shop` … → `won` / `lost`. Bỏ `try_summon`, thêm `buy(slot)`, `reroll()`, `toggle_lock()`, `ready()`. Lúc nghỉ gear và lính đứng yên |
| `Core` | Bỏ hồi thịt theo thời gian. Thêm `grant_round_income()` và lãi |
| `GearBoard` | Hầu như giữ nguyên. Thêm `place_near_master(troop, tier)` và giá hoàn khi bán |
| HUD | Thêm panel shop, nút SẴN SÀNG, xem trước đợt sau. Bỏ nút TRIỆU HỒI |
| **Xưởng (nâng cấp ngoài sảnh)** | **Lò thịt** đổi từ "hồi thịt nhanh hơn X%" thành "**+1 thu nhập mỗi đợt / cấp**". **Kho dự trữ** giữ nguyên (thịt đầu trận). **Bánh răng tổng** giữ nguyên |
| Dữ liệu màn | `prep_time` không cần nữa (lượt nghỉ 1 thay thế). `gap` thành thời gian tối đa của đợt. `start_meat` giữ nguyên |
| `balance.json` + Admin | Thêm mục `battle_shop` (số ô, giá theo độ hiếm, đổi shop, lãi, trần lãi, bảng tỉ lệ, cơ hội bậc 2) và công thức `round_income`. Tab mới **"Shop trận"** có mô phỏng "1000 lần đổi shop ở đợt N với đội X" |
| Bot + Mô phỏng | Bot mới: ưu tiên mua món **GHÉP ĐƯỢC**, rồi món hiếm nhất mua nổi. Đổi shop khi thịt dư trên 6. Giữ 5 thịt để ăn lãi từ đợt 3. Tự bấm SẴN SÀNG |
| Test | Test mới: thu nhập, lãi, giá, bảng tỉ lệ, khoá shop giữ đúng món, bán hoàn đúng. Chạy lại bot các màn 1–10 để cân bằng |

---

## 7. Thứ tự làm

| Bước | Việc | Kiểm tra |
|---|---|---|
| A | Phase nghỉ ↔ đánh, `WaveDirector` chờ SẴN SÀNG, dừng thời gian lúc nghỉ, thu nhập + lãi | Chạy bot, log đúng thứ tự nghỉ/đánh |
| B | Dữ liệu shop (`battle_shop`, `round_income`), bốc shop theo đội và theo đợt, mua, đổi, khoá, bán hoàn | Test đơn vị + mô phỏng 1000 lần đổi |
| C | Giao diện shop, xem trước đợt, SẴN SÀNG, hiệu ứng mua (thẻ bay xuống bàn), "+thịt" cuối đợt | Ảnh chụp các trạng thái |
| D | Xưởng Lò thịt đổi nghĩa, tab admin "Shop trận", bot mới, cân bằng lại 10 màn bằng mô phỏng | Bot thắng màn 1–5 với hồ sơ dự kiến, tỉ lệ thắng giảm dần ở các màn sau |

---

## 8. Cần bạn chốt

1. **Lượt nghỉ có đếm ngược không?**
   - (a) Không giới hạn *(đề xuất: game thủ thủ di động thích thong thả)*.
   - (b) 20 giây, hết giờ tự đánh.
   - (c) Có đếm ngược, nhưng bấm SẴN SÀNG sớm được thưởng +1 thịt.
2. **Trong lúc đánh có được mua không?**
   - (a) Không, chỉ kéo/ghép/bán *(đề xuất)*.
   - (b) Được, nhưng giá gấp đôi.
3. **Có hàng chờ (bench) không?** Tức 4–5 ô giữ gear đã mua nhưng chưa đặt lên bàn.
   - Đề xuất: **chưa làm**. Bàn 23 ô đã đủ chỗ; thêm bench thì màn hình dọc chật hơn. Có thể làm sau nếu thấy cần.
4. **Lính còn sống sau đợt**: giữ lại *(đề xuất)*, hay xoá hết để mỗi đợt bắt đầu lại từ đầu?

---

## 9. Kết quả (đã làm)

**Chốt theo đề xuất:**
- Lượt nghỉ không đếm ngược.
- Lúc đánh không mua được, nhưng vẫn ghép và bán được.
- Chưa có bench.
- Lính còn sống được giữ sang đợt sau.

**Con số đã đổi khi cân bằng bằng bot:**

| | Kế hoạch | Thực tế | Lý do |
|---|---|---|---|
| Kho thịt tối đa | 10 → 15 | **20 → 30** | Thu nhập và lãi bị cắt mất khi kho chỉ 10 |
| Thịt đầu màn (`start_meat`) | 6–7 | **5 + số màn** (màn 1: 6 … màn 10: 15) | Không còn 12–14 giây chuẩn bị để hồi thịt, nên lượt nghỉ đầu cần nhiều thịt hơn |
| Bán hoàn | giá × bậc | **75% giá trị** | Tránh mua bán lòng vòng không tốn gì |

**File chính:**

| Phần | File |
|---|---|
| Nhịp nghỉ/đánh, shop, thu nhập | `game/battle/Battle.gd`, `WaveDirector.gd`, `Core.gd` |
| Bốc shop (dùng chung cho trận và admin) | `game/battle/ShopRoller.gd` |
| Đặt gear mua được | `GearBoard.place_new` |
| Giao diện shop, SẴN SÀNG, thẻ bay xuống bàn | `game/ui/HUD.gd` |
| Dữ liệu | `balance.json`: mục `battle_shop`, công thức `round_income` và `interest` (bỏ `summon_cost` và `meat_regen_time`); Lò thịt = +1 thịt/đợt mỗi cấp |
| Admin | Tab mới **Shop trận** (mọi thông số, bảng tỉ lệ, mở thử 1.000 shop); tab Màn chơi bỏ "thời gian chuẩn bị" và "gap" |
| Bot | `game/admin/Bot.gd`: mua món ghép được, giữ 5 thịt ăn lãi từ đợt 3, đổi shop khi dư, bấm SẴN SÀNG |

**Bot (mỗi màn 1–3 trận):**
- Màn 1: thắng, không mất máu.
- Màn 2: thắng sát nút (còn 1 máu).
- Màn 6: 1 thắng 1 thua.
- Màn 8, 10: thắng.

Nên xem lại màn 2 và chỉnh `start_meat` trong admin nếu thấy khó.

**Test:**
- BalanceTest 535/535, có thêm kiểm tra thu nhập, lãi, giá, hoàn tiền, bảng tỉ lệ.
- Ảnh chụp lượt nghỉ, lượt đánh và tab admin.
