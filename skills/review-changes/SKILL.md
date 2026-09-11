---
name: review-changes
description: Review thay đổi code theo hai trục song song — đúng quy ước repo, và đúng spec. Dùng sau mỗi task trong subagent-execution, hoặc khi người dùng muốn review một nhánh, PR, diff.
---

# Review hai trục

Hai câu hỏi khác nhau, đừng trộn:

- **Quy ước** — code có theo cách repo này vẫn làm không?
- **Đặc tả** — code có làm đúng thứ được yêu cầu không?

Code sạch mà sai yêu cầu vẫn phải làm lại. Code đúng yêu cầu mà lệch quy ước sẽ thành nợ.

## Lấy diff

```bash
git diff <mốc>...HEAD          # so với nhánh gốc
git diff HEAD~1                # task vừa xong
gh pr diff <số>                # pull request
```

Người dùng không nói mốc thì hỏi, đừng đoán. Review nhầm phạm vi tốn công cả hai bên.

## Chạy hai reviewer song song

Gọi hai `Agent` với `subagent_type: general-purpose` **trong cùng một lượt** để chúng chạy
song song và không nhiễu context của nhau.

**Reviewer A — Quy ước.** Đưa: diff, `CLAUDE.md` của project nếu có, và vài file cùng loại
đã tồn tại để đối chiếu. Kiểm: đặt tên, cấu trúc thư mục, cách xử lý lỗi, cách log, escape
đầu ra, có tái dùng được hàm sẵn có thay vì viết mới không.

**Reviewer B — Đặc tả.** Đưa: diff, spec hoặc nội dung task, và tiêu chí nghiệm thu. Kiểm
từng tiêu chí một: đã làm / chưa làm / làm khác. Đặc biệt soi các trường hợp biên đã ghi
trong spec — đây là chỗ hay bị bỏ nhất.

Reviewer **không** nhận lịch sử hội thoại của người viết code. Dùng chung context thì reviewer
thấy code hợp lý vì nó vừa tự nghĩ ra logic đó.

## Gộp kết quả

Bỏ trùng, xếp theo mức độ, và **chỉ giữ phát hiện kiểm chứng được**:

| Mức | Nghĩa |
|---|---|
| Chặn | Sai chức năng, lỗ hổng bảo mật, thiếu tiêu chí nghiệm thu bắt buộc |
| Nên sửa | Lệch quy ước, thiếu xử lý trường hợp biên, khó bảo trì |
| Góp ý | Sở thích cá nhân, có thể bỏ qua |

Mỗi phát hiện ghi: `file:dòng`, vấn đề là gì, **vì sao** là vấn đề, và cách sửa.

Phát hiện không nêu được hệ quả cụ thể thì bỏ. *"Nên tách hàm này"* mà không nói tách ra
được gì chỉ làm nhiễu.

## Với code PHP WordPress

Gọi thẳng `devflow:wp-security-audit` thay vì tự soi bảo mật — nó có 40+ rule theo WPCS mà review
bằng mắt không phủ hết.

## Kết luận

Kết thúc bằng một trong hai:

- **Đạt** — không có mục Chặn. Ghi kèm các mục Nên sửa để xử lý sau.
- **Chưa đạt** — liệt kê mục Chặn cần sửa trước khi đóng task.

Trong `devflow:subagent-execution`, chỉ `Đạt` mới được đóng task.

Review độc lập (không nằm trong vòng lặp subagent) mà kết luận `Đạt` thì chuyển tiếp
`devflow:verify-done` để chạy kiểm chứng thật — review đọc diff, nó không chứng minh được
code chạy được.
