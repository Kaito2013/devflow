---
name: clarify-requirements
description: Phỏng vấn làm rõ yêu cầu trước khi viết code. Dùng khi người dùng muốn xây tính năng mới, thêm module, đổi hành vi, hoặc đưa ý tưởng còn mơ hồ. Xuất ra spec trong devflow/specs/.
---

# Làm rõ yêu cầu

Mục tiêu: chốt được **cái gì** và **vì sao** trước khi bàn tới **làm thế nào**. Một câu hỏi
đúng lúc này rẻ hơn nhiều so với dựng sai rồi làm lại.

## Cổng chặn

Trong lúc chạy skill này, **không** viết code, không tạo file, không dựng scaffold. Việc
implement chỉ bắt đầu sau khi người dùng đã đồng ý rõ ràng với thứ bạn sắp làm — một câu
"ừ làm đi" là đủ, nhưng phải có, không được tự suy ra từ im lặng.

Nếu người dùng giục làm luôn, nói rõ còn bao nhiêu điểm chưa chốt rồi hỏi họ muốn chốt hay
chấp nhận mặc định. Việc càng "đơn giản" càng dễ sai chỗ này — giả định không kiểm tra là
nguồn lãng phí công sức lớn nhất, không phải câu hỏi thừa.

## Phân loại quy mô trước khi hỏi

Nói to quy mô bạn chọn, để người dùng chỉnh nếu sai — đừng âm thầm chọn:

| Quy mô | Dấu hiệu | Xử lý |
|---|---|---|
| **Vặt** | Đổi một dòng, một flag, một chuỗi text, sửa lỗi rõ ràng nguyên nhân | Hỏi tối đa 1 câu nếu cần, làm luôn, không cần spec |
| **Gọn** | Sửa một luồng đã có sẵn trong repo, phạm vi rõ trong một vài file | Hỏi 1 đợt câu hỏi, chốt bằng vài dòng ngay trong chat, không cần file spec |
| **Lớn** | Tính năng mới, nhiều module liên quan, đổi cách hệ thống ghép nối | Đi hết quy trình dưới đây, xuất file spec, rồi mới sang `write-plan` |

**Chỉ tăng cấp, không giảm cấp giữa chừng.** Đang làm việc "Gọn" mà phát hiện nó đụng vào 3
module chưa lường trước — dừng lại, nói rõ, chuyển sang "Lớn". Ngược lại thì không: đã chốt
là "Lớn" thì không tự ý rút gọn vì thấy đơn giản hơn dự tính.

Việc mô tả nhiều tính năng độc lập cùng lúc ("làm cho tôi hệ thống có A, B, C, D") không phải
việc "Lớn" — đó là **nhiều việc "Lớn" gộp lại**. Tách ra trước, hỏi rõ nên làm phần nào trước,
rồi chỉ đi sâu vào một phần.

## Cách hỏi

**Hỏi theo đợt.** Gom câu hỏi liên quan vào một lượt, đánh số, và kèm luôn đề xuất trả lời
của bạn để người dùng chỉ cần gật hoặc sửa:

```
❓ 1 — Giỏ hàng lưu ở đâu?
   Session (đơn giản, mất khi đóng trình duyệt) hay Database (giữ giữa
   các thiết bị, cần bảng mới và dọn rác định kỳ)?
➡️ Đề xuất: Database — vì yêu cầu có nhắc "đăng nhập nhiều thiết bị"

❓ 2 — ...
➡️ ...
```

Hỏi lắt nhắt từng câu một làm người dùng mệt và bỏ cuộc giữa chừng; dội nguyên một bảng câu
hỏi không phân nhóm cũng vậy. Đợt câu hỏi tiếp theo chỉ hỏi những gì **phụ thuộc vào câu trả
lời vừa nhận** — đừng hỏi lại thứ đã hỏi lượt trước.

**Việc tra được thì tự tra, đừng hỏi.** Câu hỏi cần một sự thật nằm trong code, file cấu
hình, hay tài liệu sẵn có — tự đọc lấy, hoặc gọi `analyze` nếu cần hiểu kiến trúc trước. Chỉ
đưa cho người dùng câu hỏi mà **chỉ họ** trả lời được: ưu tiên nghiệp vụ, ràng buộc ngân sách,
quyết định mà kỹ thuật không tự suy ra.

**Mỗi câu hỏi phải đổi được việc bạn sắp làm.** Hai đáp án dẫn tới cùng một cách dựng thì
đừng hỏi — tự chọn rồi ghi vào mục giả định.

**Đừng hỏi thứ tự đoán được.** Không hỏi "có cần responsive không" — tất nhiên là có.

## Cần chốt những gì (việc "Lớn")

Đi qua bốn nhóm, bỏ qua nhóm nào không liên quan:

1. **Phạm vi** — tính năng gồm những gì, và rõ ràng **không** gồm gì
2. **Dữ liệu** — thực thể nào, nguồn ở đâu, ai được đọc/ghi
3. **Trường hợp biên** — rỗng, lỗi, trùng, quá tải, quyền không đủ
4. **Nghiệm thu** — dấu hiệu nào cho biết đã xong

Nhóm 4 hay bị bỏ qua nhất, và là nhóm quyết định `verify-done` sau này kiểm được cái gì.

## Khi người dùng không chắc

Đừng ép họ quyết thứ họ chưa biết. Đề xuất một phương án mặc định kèm lý do, ghi rõ đây là
giả định, và nói rõ chỗ nào sẽ tốn công nếu sau này đổi ý.

## Tự soát spec trước khi đưa cho người dùng

Viết xong đừng đưa ngay — đọc lại một lượt, tự sửa những lỗi này trước khi người dùng thấy:

- **Còn chỗ trống không** — "TBD", "sẽ quyết định sau", mục bỏ dở?
- **Có tự mâu thuẫn không** — phần Dữ liệu có khớp với phần Phạm vi không?
- **Có câu nào hiểu hai cách không** — hiểu hai cách thì chọn một nghĩa, viết rõ ra, đừng để
  người đọc tự đoán.
- **Phạm vi có vừa một kế hoạch không** — quá to thì quay lại bước phân loại, tách nhỏ trước.

Sửa ngay tại chỗ, không cần báo lại quá trình soát — chỉ đưa bản đã sửa.

## Đầu ra (việc "Lớn")

Ghi spec vào `devflow/specs/YYYY-MM-DD-<tên>-spec.md`:

```markdown
# <Tên tính năng>

## Bối cảnh
Vì sao cần. Một đoạn.

## Phạm vi
- Gồm: ...
- Không gồm: ...

## Dữ liệu
Thực thể, quan hệ, quyền truy cập.

## Trường hợp biên
| Tình huống | Hành vi mong muốn |

## Tiêu chí nghiệm thu
- [ ] Kiểm được bằng cách nào

## Giả định đã dùng
Những chỗ tự điền vì người dùng không chốt.
```

Việc "Gọn" thì chốt bằng vài dòng ngay trong chat — không tạo file — rồi hỏi một câu duy
nhất: *"Vậy được chưa, làm luôn?"*

## Bàn giao

Việc "Lớn": *"Spec đã lưu ở `devflow/specs/<file>.md`. Chuyển sang `devflow:write-plan`?"*

Việc "Gọn" đã được gật đầu: bắt tay làm ngay trong quy trình bình thường, không cần
`write-plan` hay subagent riêng — chỉ việc "Lớn" mới đi hết chuỗi.
