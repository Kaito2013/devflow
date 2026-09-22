---
name: subagent-execution
description: Execute a plan via subagents ("thực thi bằng subagent", "triển khai") — one implementer per task, then an independent reviewer, with a ledger that survives compaction and a bounded fix loop. Use once a plan exists in devflow/plans/ and the environment supports subagents.
---

# Thực thi bằng subagent

Session chính đóng vai **điều phối**: đọc plan, phát task, nhận báo cáo, ghi ledger. Nó
**không** tự viết code — làm vậy thì context đầy sau vài task và các task sau mất chất lượng.

## Vì sao không làm tuần tự trong session chính

Mỗi task đọc vào hàng nghìn dòng code. Sau 5 task, context chính chứa toàn bộ source của 5
vùng khác nhau, và agent bắt đầu lẫn. Subagent đọc code rồi chỉ trả về **kết quả**, source
không bao giờ vào context chính.

Đây cũng là lý do reviewer phải là agent **riêng**: reviewer dùng chung context với người viết
sẽ thấy code "hợp lý" vì nó vừa tự nghĩ ra logic đó.

## Cô lập trước khi bắt đầu

Trước bất kỳ bước nào dưới đây, gọi `devflow:isolate-worktree` — trừ khi đang chuyển đổi
theme WordPress (xem Ngoại lệ cuối bài, đứng ngoài toàn bộ quy trình này). Một lần chạy SDD
hỏng giữa chừng không được phép làm bẩn nhánh mà người dùng đang xem; đây là điều kiện tiên
quyết, không phải tuỳ chọn.

## Ledger — sống sót qua compaction

Trí nhớ hội thoại không sống sót qua compaction. Một controller mất dấu sẽ phát lại từ đầu
những task đã xong — lỗi tốn kém nhất có thể mắc ở quy trình này.

Trước khi phát task đầu tiên, tạo `devflow/plans/<tên-plan>.ledger.md`:

```markdown
# Ledger — plan: devflow/plans/<file>.md

Task 1: complete — commit a1b2c3d
Task 2: fix round 1/3 (2 addressed, 1 open) — commit e4f5g6h
Task 3: parked — <phát hiện> — Ruling: <vì sao chấp nhận> — <cái giá nếu sai>
```

Trước khi phát bất kỳ task nào, đọc ledger nếu nó đã tồn tại. Task có dòng `complete` thì
**không phát lại** — tiếp tục từ task đầu tiên chưa có dòng đó. Ngờ vực trí nhớ của chính
mình hơn là tin — `git log` và ledger là sự thật, hội thoại không phải.

## Rà xung đột trước khi bắt đầu

Đọc hết plan một lượt trước khi phát Task 1. Với mỗi cặp task cùng đụng một file, hoặc phần
mô tả của một task tự mâu thuẫn — ghi vào ledger đã kiểm tra gì, và quyết định trước khi bắt
đầu thay vì để hai subagent giẫm lên nhau giữa chừng.

## Vòng lặp mỗi task

```
1. Phát Implementer  →  2. Kiểm kết quả  →  3. Phát Reviewer  →  4. Ghi ledger, đóng task
                             ↓ fail                  ↓ có vấn đề
                        phát lại (vòng sửa, tối đa 3)
```

### 1. Implementer

Phát subagent Implementer theo môi trường hiện tại:
- **Claude Code:** Gọi `Agent` với `subagent_type: general-purpose`.
- **Antigravity (AGY):** Gọi `invoke_subagent` với `TypeName: "self"`, `Role: "Task Implementer"`, `Model: "inherit"` (hoặc `flash` cho task nhỏ).
- **Codex / Single-Agent Harness (Cursor, Copilot):** Thực thi tuần tự từng task trong session chính theo hướng dẫn tại `write-plan`.

Đưa **một** task mỗi lần — gộp nhiều task vào một subagent quay lại đúng vấn đề context mà cơ chế này sinh ra để tránh.

**Ngoại lệ:** nhiều task nhỏ, cùng dạng thay đổi lặp lại (đổi một hằng số ở N file, thêm cùng
một field vào N model) thì gộp thành **một** dispatch liệt kê đủ từng file — không phát N
subagent cho N việc giống hệt nhau.

Trong prompt đưa đủ:

- **Thư mục làm việc (`WORKTREE_PATH`):** Nếu đã chạy `isolate-worktree`, chỉ rõ: *"Thư mục làm việc là `<WORKTREE_PATH>`. Toàn bộ thao tác file và lệnh test/build phải thực hiện trong thư mục này, không thao tác ngoài root."*
- Nội dung task lấy nguyên từ plan (làm gì, file nào, kiểm chứng ra sao)
- Đường dẫn spec và `CONTEXT.md` để nó tự đọc khi cần
- Stack và dòng **Có test** từ plan — có thì yêu cầu chạy `devflow:test-first`
- Nếu task có tag `[UI]` hoặc tạo/sửa giao diện (Blade, Livewire, React, Vue, HTML/CSS) mà người dùng thật
  nhìn thấy: yêu cầu đọc `devflow:ui-design` trước khi viết markup.
- **Quy tắc Git:** Implementer **tuyệt đối không tự chạy `git commit`**. Chỉ sửa code và chạy lệnh kiểm chứng.
- Yêu cầu trả về: file đã đổi, lệnh đã chạy, **output thật** của lệnh đó
- **Không được tự phát subagent khác**, kể cả để tự review. Review là việc của điều phối,
  sau khi nhận báo cáo.

### 2. Kiểm trước khi review

Đọc báo cáo của implementer. Nó có dán output lệnh không? Output đó có thật sự pass không?
Không có bằng chứng thì phát lại, đừng chuyển sang reviewer.

### 3. Reviewer nội bộ task

Để tinh gọn token và tránh trễ, **mỗi task trong SDD chỉ dùng 1 Reviewer tích hợp** (không phát 2 subagent cho một task nhỏ):
- **Claude Code:** Gọi `Agent` với `subagent_type: general-purpose`.
- **Antigravity (AGY):** Gọi `invoke_subagent` với `TypeName: "self"`, `Role: "Task Reviewer"`, `Model: "inherit"`.
- **Codex / Single-Agent:** Tự đối chiếu diff `git diff HEAD` với spec và quy ước trước khi commit.

Chỉ định Reviewer nhận: nội dung task, tiêu chí nghiệm thu, và diff chưa commit (`git diff HEAD`). Reviewer soi cả hai tiêu chí: (1) Tuân thủ spec và (2) Sạch sẽ, đúng quy ước code.

Không đạt thì vào **vòng sửa**, tối đa **3 vòng** cho một task:

- **Vòng 1–2:** phát lại đúng implementer đó, kèm nguyên văn các phát hiện của reviewer. Nó
  còn nhớ task và lựa chọn của mình.
- **Vòng 3:** phát implementer **mới**, nói rõ *"task này đã thử 2 lần trước, bạn tiếp quản"*
  — một vòng lặp sống sót 2 lần thử thường là implementer không thấy được vấn đề của chính
  mình, cần góc nhìn mới.

Sau mỗi vòng, ghi ledger: `Task N: fix round R/3 (X đạt, Y còn)`.

**Hết 3 vòng mà vẫn còn phát hiện** — dừng phát subagent, tự phân xử từng phát hiện còn lại:

| Loại phát hiện | Xử lý |
|---|---|
| Reviewer sai, hoặc điểm đó còn tranh cãi được | Ghi `parked` kèm lý do, đi tiếp |
| Đúng nhưng không ai phụ thuộc vào chỗ đó | Ghi `parked`, đi tiếp |
| Đúng và có task sau phụ thuộc vào chỗ này | Đây là lý do duy nhất dừng hẳn để hỏi người dùng |

### 4. Đóng task & Commit

Chỉ khi reviewer trả `Đạt`, hoặc bạn đã tự phân xử `parked` hợp lệ:
1. **Controller thực hiện commit** tại worktree:
   ```bash
   git add -A && git commit -m "feat(task-<N>): <mô tả ngắn gọn công việc>"
   ```
2. Lấy commit hash (`git rev-parse --short HEAD`) và ghi vào ledger:
   `Task N: complete — commit <hash>`
3. **Bắn thông báo tới devflow-cli (nếu có):**
   ```bash
   bash scripts/bridge-notify.sh "Task <N>" "APPROVED" "<hash>"
   ```
4. Đóng task, chuyển sang task kế tiếp.

## Khi nào tự quyết, khi nào dừng hỏi

Kế hoạch đang chạy không chờ người dùng ở giữa chừng. Mâu thuẫn giữa hai task, chỗ plan mơ
hồ, một giới hạn định vượt qua — **tự quyết**, ghi vào ledger dạng `Ruling: <đã chọn gì> —
<vì sao> — <giá nếu sai>`, rồi đi tiếp. Một quyết định sai còn sửa được và nhìn thấy được;
một phiên dừng lại chờ hỏi tốn cả buổi mà không đổi lấy gì.

Chỉ bốn việc sau khiến bạn dừng hẳn để hỏi:

1. Hành động không thể hoàn tác hoặc mang tính phá huỷ (xoá dữ liệu, migrate không rollback được)
2. Hành động ảnh hưởng bảo mật (đổi quyền truy cập, xử lý secret)
3. Tác động ra ngoài phạm vi đang làm việc (push lên nhánh chung, merge, gọi API bên thứ ba
   tính phí)
4. Plan hỏng tới mức mọi hướng đi đều là đoán mò

Ngoài bốn cái đó, đừng hỏi "có nên tiếp tục không" giữa các task — người dùng đã giao việc,
việc của bạn là chạy hết plan.

## Chạy song song

Plan đã ghi task nào độc lập. Phát nhiều implementer cùng lúc **chỉ khi** cả ba điều đúng:

- Không task nào ghi chung một file
- Không task nào phụ thuộc kết quả task kia
- Task thân (schema, interface, layout chung) đã xong trước

**Mặc định vẫn là tuần tự.** Hai task "nhìn độc lập" vẫn có thể đụng nhau ở trạng thái git
chung (cùng branch, cùng lock file) dù không chung file nội dung — nghi ngờ thì chạy tuần tự,
chờ vẫn rẻ hơn dọn xung đột.

## Ngoại lệ

**Theme WordPress không dùng quy trình này.** Chuyển đổi theme là chuỗi việc phụ thuộc chặt
vào nhau (header, footer, functions.php đều liên quan), chia nhỏ ra chỉ tốn thêm. Dùng
`wp-theme-converter` với quy trình theo đợt của nó.

## Kết thúc & Bàn giao

Hết task thì gọi `verify-done` để chạy kiểm chứng toàn bộ, rồi báo cáo: số task, file đã đổi,
các mục đã `parked` kèm ruling, lệnh kiểm chứng và output.

Nếu đã chạy trong worktree cô lập (`devflow:isolate-worktree`): báo đường dẫn worktree,
tên nhánh, và hỏi người dùng muốn làm gì tiếp theo:
1. **Merge vào nhánh chính:** Hướng dẫn chạy `git checkout <nhánh-gốc> && git merge --no-ff <tên-nhánh>`
2. **Dọn dẹp worktree:** Hướng dẫn dọn dẹp bằng `git worktree remove .worktrees/<tên-nhánh> --force` và `git branch -d <tên-nhánh>`
3. **Mở PR hoặc giữ lại:** Giữ nguyên worktree để kiểm tra thủ công.
