# Nhân vật cầm vũ khí — nguồn Figma 3443:2

Nguồn người dùng bổ sung: [Asset chính · Kho PNG](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3443-2). Ngày xem: 2026-10-19.

Đã đối chiếu biến thể 1 và 6 của 21 nhóm Hero, xem bảng nhãn dán đầu tiên và xem kỹ sáu mẫu cầm kiếm, rìu, giáo, gậy, nỏ và sách. Hai nhóm có thể dùng chung hình; số mục nguồn không phải số thiết kế độc nhất. Không khẳng định đã xem kỹ toàn bộ kho PNG hay mọi biến thể trung gian.

- [21 nhóm — biến thể 1](heroes-variant-1.png).
- [21 nhóm — biến thể 6](heroes-variant-6.png).
- [Sáu tư thế cầm và bản thu nhỏ](held-weapon-examples.png).
- [Nguồn, node Figma và hash](sources.json); sáu PNG nguyên bản giữ trong `samples/`.

Các bảng xem lớn cắt phần alpha để dễ quan sát. Hàng ảnh 128 × 128 trong bảng sáu ví dụ thu từ toàn bộ canvas gốc 256 × 256; đây là kích thước kiểm tra, không xác nhận kích thước runtime của game tham khảo.

## Những gì bổ sung cho thiết kế vũ khí

| Mẫu gốc | Node ảnh Figma | Cách dựng đáng học |
| --- | --- | --- |
| Hero2 / 1 — kiếm | [3447:14466](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3447-14466) | Lưỡi chéo ngoài má, tay che cán; mảng thép và mặt sáng lớn, đốc gọn |
| Hero6 / 1 — rìu | [3447:14706](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3447-14706) | Đầu thép cạnh vai, khớp đồng lớn, cán đi qua bàn tay |
| Hero4 / 6 — giáo | [3447:14656](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3447-14656) | Cán ngang dưới mặt, mũi giáo vươn ra bên; khác tư thế kiếm |
| Hero8 / 6 — gậy | [3447:14816](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3447-14816) | Gậy ngắn, quả cầu lớn, điểm sáng phẳng rộng; đầu gậy không che mặt |
| Hero9 / 4 — nỏ | [3447:14844](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3447-14844) | Đặt thấp trước bụng, khe dây rộng và nét dây mảnh |
| Hero16 / 6 — sách | [3447:14336](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3447-14336) | Sách mở dưới cằm, có tay đỡ; trang và bìa thành mảng rõ |

Mấu chốt là thiết kế **nhân vật, tay cầm và vũ khí trong cùng bố cục**. Phải quyết định điểm cầm, phần tay che, hướng đầu vũ khí, khoảng hở quanh mặt và tỷ lệ mảng màu trước khi trau chuốt icon rời. Giữ nguyên mèo hiện tại của game làm mẫu bố trí; không thay nhân vật để hợp một icon đã vẽ sẵn.

Vũ khí thường giữ dáng và tư thế qua các biến thể, trong khi giáp/mũ/áo choàng tăng chi tiết. Không suy ra luật nâng cấp hoặc bắt mọi độ hiếm phải có vũ khí to hơn. Viền trắng của nhãn dán và khung tròn của huy hiệu là lớp trình bày riêng.

Đã ghi vào [skill thiết kế vũ khí](../../../../../../tools/skills/casual-weapon-design/references/held-character-study.md). Không sửa ảnh nguồn, asset runtime, nhân vật hoặc gameplay.

Tạo lại bảng từ chỉ mục nguồn:

```powershell
python -X utf8 -B docs/design/2026-10-19/weapon-redesign/reference-study/held-characters/build_study.py
```
