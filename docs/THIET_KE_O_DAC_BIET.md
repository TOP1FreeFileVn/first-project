# Thiết kế: Ô đặc biệt trên lưới gear, màn 11–15, hướng dẫn người mới

Đợt 1 của chiến lược bổ sung content: làm sâu cơ chế bánh răng (điểm khác biệt của game)
mà không cần hình mới.

## 1. Bốn loại ô

| Ô | Luật | Vai trò trong thiết kế màn |
|---|---|---|
| **Ô đá** | Không đặt gear được | Chặn một mặt của trục cam, buộc nối xích đi vòng |
| **Ô vàng** | Gear trên ô sinh lính nhanh hơn 50% | Phần thưởng cho việc kéo chuỗi xa khỏi trục |
| **Ô rỉ sét** | Gear vẫn quay và truyền động, nhưng không sinh lính | Buộc dùng một gear rẻ làm cầu nối |
| **Ô băng** | Gear trơn: không ăn khớp gear nào, chỉ quay khi chạm thẳng trục cam | Cắt chuỗi; ô cạnh trục thành ngõ cụt |

- Màn khai báo ô trong `tiles` của file màn, ví dụ `{"rock": [Vector2i(1, 1)], "gold": [...]}`.
- Ô chỉ có tác dụng khi ô lưới đó đã mở theo cấp thành.
- Mỗi ô có hoa văn riêng và một huy hiệu góc, vẫn nhìn thấy khi có gear đè lên.

## 2. Màn 11–15 (giai đoạn 2 · Mở rộng cơ chế)

| Màn | Ô | Địch nổi bật | Sức mạnh địch |
|---|---|---|---|
| 11 Bến Cảng | 2 ô đá cạnh trục | Hỗn hợp, 2 tinh nhuệ cuối | 2,9 (màn "thở" sau trùm) |
| 12 Rừng Sương | 3 ô đá | Hiệp sĩ khiên số đông, Tướng quân | 3,1 |
| 13 Đồi Cừu | 3 ô vàng + 1 ô đá | Sát thủ săn hậu tuyến | 3,6 |
| 14 Mỏ Vàng | 3 ô rỉ sét cạnh trục + 2 ô vàng | Kỵ thương dồn dập, Thợ mỏ | 3,7 |
| 15 Cầu Đá | 2 ô băng cạnh trục + 2 ô đá | Trùm nhỏ: Thợ rèn + Hiệp sĩ khiên tinh nhuệ, Tướng quân | 4,4 |

- **Thưởng lần đầu:** màn 12 mở khoá Thợ rèn, màn 15 mở khoá Sát thủ.
- **Cân bằng** được kiểm bằng bot tự chơi với hồ sơ giữa game: thành cấp 6, lính cấp 12, 2 sao, đủ loại lính.

## 3. Hướng dẫn trong trận (`game/ui/Coach.gd`)

- **Người chơi mới, màn 1:**
  1. Mua gear trong shop.
  2. Gear chạm quả cầu cam mới quay, chỉ gear đang quay mới sinh lính.
  3. Ghép 2 gear giống nhau.
  4. Bấm SẴN SÀNG.
  5. Hết đợt: nhận thịt và lãi.

  Có mũi tên và khung sáng chỉ vào đúng chỗ. Bỏ qua được bất cứ lúc nào. Save cũ đã qua màn 1 thì coi như đã xong hướng dẫn.
- **Lần đầu gặp một loại ô:** bảng "Ô MỚI TRÊN LƯỚI!" có hình mẫu ô và luật, các ô đó nhấp nháy trên lưới. Loại ô đã xem được lưu trong save.

## 4. Kiểm thử

| Bài test | Kiểm tra |
|---|---|
| `tests/TileTest.tscn` | Ô đá không đặt được; ô băng không truyền động; ô rỉ sét truyền động nhưng sản xuất 0; ô vàng sản xuất gấp 1,5 lần (đo 20 giây) |
| `tests/CoachShots.tscn` | Chụp các bước hướng dẫn và bảng "Ô MỚI" |
| `tests/LevelCards.tscn` | Tranh 15 màn |
