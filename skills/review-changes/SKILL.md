---
name: review-changes
description: Review code changes along two parallel axes ("review code") — repo conventions, and spec compliance. Use after each task in subagent-execution, or when the user wants to review a branch, PR, or diff.
---

# Review hai trục

Hai câu hỏi khác nhau, đừng trộn:

- **Quy ước** — code có theo cách repo này vẫn làm không?
- **Đặc tả** — code có làm đúng thứ được yêu cầu không?

Code sạch mà sai yêu cầu vẫn phải làm lại. Code đúng yêu cầu mà lệch quy ước sẽ thành nợ.

## Bước 0 — Tiền kiểm Linter & Cú pháp (Bắt buộc trước khi gọi LLM)

Trước khi đọc diff bằng mắt hay phát reviewer LLM, chạy linter tự động theo stack để bắt lỗi cú pháp và style cơ bản:

```bash
# Laravel:
for f in $(git diff --name-only HEAD | grep '\.php$'); do php -l "$f"; done
[ -f vendor/bin/pint ] && vendor/bin/pint --test

# Node:
[ -f package.json ] && grep -q '"lint"' package.json && npm run lint

# Flutter:
[ -f pubspec.yaml ] && flutter analyze

# WordPress:
for f in $(git diff --name-only HEAD | grep '\.php$'); do php -l "$f"; done
```

Linter fail → trả về bắt implementer sửa ngay, **không tốn token review LLM** cho lỗi cú pháp.

## Lấy diff

```bash
git diff HEAD                  # Diff task hiện tại (chưa commit trong SDD)
git diff <mốc>...HEAD          # So với nhánh gốc (khi review toàn bộ branch)
gh pr diff <số>                # Pull request
```

Người dùng không nói mốc thì hỏi, đừng đoán.

## Hai chế độ Review

### Chế độ A: Review trong vòng lặp SDD (`subagent-execution`)
Với từng task nhỏ trong SDD, để tối ưu token và tốc độ: **chỉ dùng 1 Reviewer tích hợp**.
Đưa cho Reviewer: nội dung task, tiêu chí nghiệm thu, diff `git diff HEAD`, và quy ước stack tương ứng ([references/](references/)).
Reviewer trả kết quả: Đạt / Chưa đạt (kèm danh sách phát hiện Chặn / Nên sửa).

### Chế độ B: Review toàn bộ Branch / PR / Độc lập
Khi người dùng gọi `/devflow:review-changes` cho toàn bộ nhánh hoặc PR: gọi hai `Agent` chạy song song:

- **Reviewer A — Quy ước.** Đưa: diff, `CLAUDE.md`, file tham chiếu quy ước ([references/](references/)). Kiểm: cấu trúc, đặt tên, xử lý lỗi, bảo mật, tái sử dụng code.
- **Reviewer B — Đặc tả.** Đưa: diff, spec/plan, tiêu chí nghiệm thu. Soi từng tiêu chí một và các trường hợp biên.

Reviewer **không** nhận lịch sử hội thoại của người viết code để tránh thiên kiến.

## Gộp kết quả

Bỏ trùng, xếp theo mức độ, và **chỉ giữ phát hiện kiểm chứng được**:

| Mức | Nghĩa |
|---|---|
| Chặn | Sai chức năng, lỗ hổng bảo mật, thiếu tiêu chí nghiệm thu bắt buộc |
| Nên sửa | Lệch quy ước repo, thiếu xử lý trường hợp biên, khó bảo trì |
| Góp ý | Sở thích cá nhân, có thể bỏ qua |

Mỗi phát hiện ghi: `file:dòng`, vấn đề là gì, **vì sao** là vấn đề, và cách sửa cụ thể.

## Với code PHP WordPress

Gọi thẳng `devflow:wp-security-audit` thay vì tự soi bảo mật — nó có 40+ rule theo WPCS mà review bằng mắt không phủ hết.

## Kết luận

Kết thúc bằng một trong hai:

- **Đạt** — không có mục Chặn. Ghi kèm các mục Nên sửa để xử lý sau.
- **Chưa đạt** — liệt kê mục Chặn cần sửa trước khi đóng task.

Trong `devflow:subagent-execution`, chỉ `Đạt` mới được đóng task và commit.

Review độc lập mà kết luận `Đạt` thì chuyển tiếp `devflow:verify-done` để chạy kiểm chứng thật — review đọc diff, nó không chứng minh được code chạy được.
