---
name: clarify-requirements
description: Phỏng vấn làm rõ yêu cầu trước khi viết code. Dùng khi người dùng muốn xây tính năng mới, thêm module, đổi hành vi, hoặc đưa ý tưởng còn mơ hồ. Xuất ra spec trong devflow/specs/.
---

# Làm rõ yêu cầu

Mục tiêu: chốt được **cái gì** và **vì sao** trước khi bàn tới **làm thế nào**. Một câu hỏi
đúng lúc này rẻ hơn nhiều so với dựng sai rồi làm lại.

## Quy tắc chặn

Trong lúc chạy skill này, **không** viết code, không tạo file, không dựng scaffold, không đề
xuất thư viện. Nếu người dùng giục làm luôn, nói rõ còn bao nhiêu điểm chưa chốt rồi hỏi họ
muốn chốt hay chấp nhận mặc định.

## Cách hỏi

**Hỏi theo đợt, không hỏi từng câu một.** Gom 3–5 câu liên quan vào một lượt để người dùng
trả lời một lần. Hỏi lắt nhắt làm họ mệt và bỏ cuộc giữa chừng.

**Mỗi câu hỏi phải đổi được việc bạn sắp làm.** Nếu cả hai đáp án đều dẫn tới cùng một cách
dựng, đừng hỏi — tự chọn rồi ghi vào mục giả định.

**Kèm hệ quả vào câu hỏi** để người dùng chọn được:

> Giỏ hàng lưu ở đâu?
> - Session — đơn giản, mất khi đóng trình duyệt
> - Database — giữ được giữa các thiết bị, cần bảng mới và dọn rác định kỳ

**Đừng hỏi thứ tự đoán được.** Không hỏi "có cần responsive không" — tất nhiên là có.

## Cần chốt những gì

Đi qua bốn nhóm, bỏ qua nhóm nào không liên quan:

1. **Phạm vi** — tính năng gồm những gì, và rõ ràng **không** gồm gì
2. **Dữ liệu** — thực thể nào, nguồn ở đâu, ai được đọc/ghi
3. **Trường hợp biên** — rỗng, lỗi, trùng, quá tải, quyền không đủ
4. **Nghiệm thu** — dấu hiệu nào cho biết đã xong

Nhóm 4 hay bị bỏ qua nhất, và là nhóm quyết định `devflow:verify-done` sau này kiểm được cái gì.

## Khi người dùng không chắc

Đừng ép họ quyết thứ họ chưa biết. Đề xuất một phương án mặc định kèm lý do, ghi rõ đây là
giả định, và nói rõ chỗ nào sẽ tốn công nếu sau này đổi ý.

## Đầu ra

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

## Bàn giao

Spec xong thì nói: *"Spec đã lưu ở `devflow/specs/<file>.md`. Chuyển sang lập kế hoạch?"*
Người dùng đồng ý thì gọi `devflow:write-plan`.

Việc nhỏ, một hai bước, không cần plan thì nói thẳng và làm luôn — đừng bắt họ đi hết quy trình.
