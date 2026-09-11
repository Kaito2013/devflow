---
name: subagent-execution
description: Thực thi kế hoạch bằng subagent — mỗi task một implementer, rồi một reviewer độc lập. Dùng khi đã có plan trong devflow/plans/ và môi trường có subagent. Giữ context session chính sạch.
---

# Thực thi bằng subagent

Session chính đóng vai **điều phối**: đọc plan, phát task, nhận báo cáo. Nó **không** tự viết
code — làm vậy thì context đầy sau vài task và các task sau mất chất lượng.

## Vì sao không làm tuần tự trong session chính

Mỗi task đọc vào hàng nghìn dòng code. Sau 5 task, context chính chứa toàn bộ source của 5
vùng khác nhau, và agent bắt đầu lẫn. Subagent đọc code rồi chỉ trả về **kết quả**, source
không bao giờ vào context chính.

Đây cũng là lý do reviewer phải là agent **riêng**: reviewer dùng chung context với người viết
sẽ thấy code "hợp lý" vì nó vừa tự nghĩ ra logic đó.

## Vòng lặp mỗi task

```
1. Phát Implementer  →  2. Kiểm kết quả  →  3. Phát Reviewer  →  4. Đóng task
                             ↓ fail                  ↓ có vấn đề
                        phát lại task           phát task sửa
```

### 1. Implementer

Gọi `Agent` với `subagent_type: general-purpose`. Trong prompt đưa đủ:

- Nội dung task lấy nguyên từ plan (làm gì, file nào, kiểm chứng ra sao)
- Đường dẫn spec và `CONTEXT.md` để nó tự đọc khi cần
- Stack và dòng **Có test** từ plan
- Nếu có test: yêu cầu chạy `devflow:test-first` — viết test đỏ trước, rồi code
- Yêu cầu trả về: file đã đổi, lệnh đã chạy, **output thật** của lệnh đó

Đưa **một** task mỗi lần. Gộp nhiều task vào một subagent là quay lại đúng vấn đề context.

### 2. Kiểm trước khi review

Đọc báo cáo của implementer. Nó có dán output lệnh không? Output đó có thật sự pass không?
Không có bằng chứng thì phát lại, đừng chuyển sang reviewer — reviewer không có nhiệm vụ
phát hiện việc test chưa từng chạy.

### 3. Reviewer

Gọi `devflow:review-changes` cho diff của task này. Reviewer nhận: nội dung task, tiêu chí nghiệm
thu, và diff — **không** nhận lịch sử hội thoại của implementer.

Chỉ đóng task khi reviewer trả `Đạt`. Có vấn đề thì phát task sửa, rồi review lại.

## Chạy song song

Plan đã ghi task nào độc lập. Phát nhiều implementer cùng lúc **chỉ khi** cả ba điều đúng:

- Không task nào ghi chung một file
- Không task nào phụ thuộc kết quả task kia
- Task thân (schema, interface, layout chung) đã xong trước

Nghi ngờ thì chạy tuần tự. Hai subagent ghi đè lên nhau tốn nhiều thời gian hơn là chờ.

## Ngoại lệ

**Theme WordPress không dùng quy trình này.** Chuyển đổi theme là chuỗi việc phụ thuộc chặt
vào nhau (header, footer, functions.php đều liên quan), chia nhỏ ra chỉ tốn thêm. Dùng
`devflow:wp-theme-converter` với quy trình theo đợt của nó.

## Kết thúc

Hết task thì gọi `devflow:verify-done` để chạy kiểm chứng toàn bộ, rồi báo cáo:
số task, file đã đổi, lệnh kiểm chứng và output.
