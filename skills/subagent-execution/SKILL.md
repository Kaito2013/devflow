---
name: subagent-execution
description: Thực thi kế hoạch bằng subagent — mỗi task một implementer, rồi một reviewer độc lập, có ledger sống sót qua compaction và vòng sửa giới hạn. Dùng khi đã có plan trong devflow/plans/ và môi trường có subagent.
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

Gọi `Agent` với `subagent_type: general-purpose`. Đưa **một** task mỗi lần — gộp nhiều task
vào một subagent quay lại đúng vấn đề context mà cơ chế này sinh ra để tránh.

**Ngoại lệ:** nhiều task nhỏ, cùng dạng thay đổi lặp lại (đổi một hằng số ở N file, thêm cùng
một field vào N model) thì gộp thành **một** dispatch liệt kê đủ từng file — không phát N
subagent cho N việc giống hệt nhau.

Trong prompt đưa đủ:

- Nội dung task lấy nguyên từ plan (làm gì, file nào, kiểm chứng ra sao)
- Đường dẫn spec và `CONTEXT.md` để nó tự đọc khi cần
- Stack và dòng **Có test** từ plan — có thì yêu cầu chạy `devflow:test-first`
- Nếu task tạo hoặc sửa giao diện (Blade, Livewire, React, Vue, HTML/CSS) mà người dùng thật
  nhìn thấy: yêu cầu đọc `devflow:ui-design` trước khi viết markup. Không có bước này,
  implementer mặc định xếp component thư viện theo thứ tự thẳng đứng, không màu, không
  phân cấp — đúng thứ mà reviewer không bắt được vì test tự động không kiểm thẩm mỹ.
- Yêu cầu trả về: file đã đổi, lệnh đã chạy, **output thật** của lệnh đó
- **Không được tự phát subagent khác**, kể cả để tự review. Review là việc của điều phối,
  sau khi nhận báo cáo — subagent tự gọi reviewer chỉ tốn thêm một lượt vô nghĩa vì kết quả
  đó không được tính.

### 2. Kiểm trước khi review

Đọc báo cáo của implementer. Nó có dán output lệnh không? Output đó có thật sự pass không?
Không có bằng chứng thì phát lại, đừng chuyển sang reviewer.

### 3. Reviewer

Gọi `devflow:review-changes` cho diff của task này. Reviewer nhận: nội dung task, tiêu chí nghiệm
thu, và diff — **không** nhận lịch sử hội thoại của implementer.

Không đạt thì vào **vòng sửa**, tối đa **3 vòng** cho một task:

- **Vòng 1–2:** phát lại đúng implementer đó, kèm nguyên văn các phát hiện của reviewer. Nó
  còn nhớ task và lựa chọn của mình.
- **Vòng 3:** phát implementer **mới**, nói rõ *"task này đã thử 2 lần trước, bạn tiếp quản"*
  — một vòng lặp sống sót 2 lần thử thường là implementer không thấy được vấn đề của chính
  mình, cần góc nhìn mới.

Sau mỗi vòng, ghi ledger: `Task N: fix round R/3 (X đạt, Y còn) — commit <hash>`.

**Hết 3 vòng mà vẫn còn phát hiện** — dừng phát subagent, tự phân xử từng phát hiện còn lại:

| Loại phát hiện | Xử lý |
|---|---|
| Reviewer sai, hoặc điểm đó còn tranh cãi được | Ghi `parked` kèm lý do, đi tiếp |
| Đúng nhưng không ai phụ thuộc vào chỗ đó | Ghi `parked`, đi tiếp |
| Đúng và có task sau phụ thuộc vào chỗ này | Đây là lý do duy nhất dừng hẳn để hỏi người dùng |

Chỉ đóng task khi reviewer trả `Đạt`, hoặc bạn đã tự phân xử và ghi ledger.

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

## Kết thúc

Hết task thì gọi `verify-done` để chạy kiểm chứng toàn bộ, rồi báo cáo: số task, file đã đổi,
các mục đã `parked` kèm ruling, lệnh kiểm chứng và output.
