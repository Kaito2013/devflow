---
name: diagnose-bug
description: Diagnose hard or unfamiliar bugs before touching code ("chẩn đoán lỗi", "tìm nguyên nhân gốc"). Enforces a tight feedback loop, isolates the root cause, and hands off to test-first.
---

# Chẩn đoán lỗi & Truy nguyên nhân gốc (/devflow:diagnose-bug)

Mục tiêu: bắt được con bọ vào trong lồng trước khi tìm cách tiêu diệt nó. **Tuyệt đối không chạm vào code sửa khi chưa chứng minh được nguyên nhân gốc.**

Một giả thuyết sai dẫn tới sửa sai, tạo thêm nợ kỹ thuật và làm hỏng các phần khác.

---

## Ba nguyên tắc bất biến khi sửa bug

1. **Không có vòng lặp phản hồi (Feedback Loop) = Không sửa code.** Phải có đúng một lệnh chạy được để chứng minh bug đang tồn tại.
2. **Không vá triệu chứng.** Thấy lỗi `null pointer` hay `undefined index` mà chỉ thêm `if ($x !== null)` để tắt báo lỗi là tạo nợ. Phải trả lời được: *Vì sao nó lại null ở đây? Ai đã truyền giá trị này vào?*
3. **Mọi bug đều phải kết thúc bằng một bài test hồi quy (Regression Test)** trên các project có test suite.

---

## Quy trình 4 bước

```
1. Tái hiện bằng lệnh  →  2. Khoanh vùng & Bisection  →  3. Xác định nguyên nhân gốc  →  4. Bàn giao test-first
```

### Bước 1: Thiết lập Tight Feedback Loop (Lệnh tái hiện lỗi)

Trước khi mở bất kỳ file nào để sửa, tạo một lệnh chạy trong < 5 giây để tái hiện đúng lỗi:

- **Laravel:** Viết 1 test feature nhanh trong `tests/Feature/...` hoặc 1 câu lệnh `php artisan tinker --execute="..."`.
- **Node:** Viết 1 test Vitest/Jest hoặc chạy 1 script tái hiện: `node -e "..."`.
- **Flutter:** Viết 1 widget test hoặc unit test tái hiện trường hợp biên.
- **WordPress:** Mở URL render thật (bằng Playwright MCP hoặc curl có cookie/nonce).

**Chạy lệnh đó và xác nhận nó ĐỎ (trả về đúng lỗi mà người dùng báo).** Nếu lệnh vẫn xanh, bạn chưa tái hiện được lỗi — dừng lại và thu thập thêm log.

---

### Bước 2: Khoanh vùng & Phân lập (Isolation)

1. **Đọc Stack Trace từ điểm phát nổ:** Tìm file đầu tiên thuộc mã nguồn dự án của bạn trong stack trace (bỏ qua vendor/node_modules).
2. **Loại trừ lỗi môi trường:**
   - Đã chạy migration chưa? (`php artisan migrate:status`)
   - File `.env` có thiếu biến không?
   - Assets build đã được cập nhật chưa? (`npm run build`)
3. **Với lỗi hồi quy (Regression - trước đây chạy được, giờ hỏng):**
   - Dùng `git log -p -S "<tên-hàm-hoặc-biến>"` để xem commit nào vừa thay đổi logic này.
   - Dùng `git bisect` nếu khoảng commit nghi ngờ quá rộng.

---

### Bước 3: Xác định Nguyên nhân gốc (Root Cause)

Phát biểu nguyên nhân thành một câu rõ ràng theo cấu trúc:
> *"Lỗi xảy ra vì khi [Tình huống X], hàm [Y] nhận [Dữ liệu Z], dẫn đến [Hành vi sai W] thay vì [Hành vi đúng]."*

Nếu chưa nói được câu này, bạn vẫn đang phỏng đoán. Hãy thêm log tạm (`Log::info()`, `console.log()`) tại các điểm nghi vấn, chạy lại lệnh ở Bước 1 để kiểm tra dòng dữ liệu.

---

### Bước 4: Bàn giao

Khi đã tìm ra nguyên nhân gốc:

- **Dự án có test (Laravel, Node, Flutter):** Chuyển sang `devflow:test-first`. Biến lệnh ở Bước 1 thành bài test chính thức trong `tests/`, chuyển code sang xanh, rồi refactor.
- **Dự án không có test (WordPress Theme):** Sửa code tối thiểu tại đúng điểm gây lỗi, chạy lại lệnh/URL ở Bước 1 để chứng minh lỗi đã biến mất, xóa sạch các log tạm, rồi gọi `devflow:verify-done`.
