---
name: test-first
description: Viết test thất bại trước, rồi mới viết code cho nó pass. Dùng khi thêm tính năng hoặc sửa bug trong project có sẵn test (Laravel, Node, Flutter). Bỏ qua với theme WordPress.
---

# Test trước, code sau

## Khi nào áp dụng

| Stack | Áp dụng | Lệnh chạy test |
|---|---|---|
| Laravel | có | `php artisan test` hoặc `vendor/bin/phpunit` |
| Node/JS | có, nếu `package.json` có script test | `npm test` |
| Flutter | có | `flutter test` |
| WordPress theme | **không** | kiểm bằng render thật |
| WordPress plugin | có, nếu đã cài PHPUnit | `vendor/bin/phpunit` |

Project chưa có hạ tầng test thì **đừng dựng nó giữa chừng một task tính năng**. Nói với
người dùng đó là việc riêng, rồi kiểm chứng bằng cách chạy thật.

## Ba bước

### Đỏ — viết test thất bại

Viết test mô tả hành vi mong muốn. **Chạy nó và xem nó fail.**

Bước "xem nó fail" không được bỏ. Test pass ngay từ đầu nghĩa là nó không kiểm cái bạn nghĩ
— có thể assert sai, có thể hành vi đã tồn tại. Test không bao giờ đỏ là test vô dụng.

Đọc cả **thông báo lỗi**. Nó phải fail vì lý do đúng (chưa có hàm, chưa có cột), không phải
vì lỗi cú pháp hay import sai.

### Xanh — viết code tối thiểu

Viết vừa đủ để test pass. Không thêm tính năng chưa có test, không tối ưu sớm.

Chạy lại, dán output.

### Refactor — dọn dẹp

Giờ mới dọn tên biến, tách hàm, bỏ trùng lặp. Chạy test lại sau mỗi thay đổi.

## Với bug

Thứ tự đặc biệt quan trọng:

1. Viết test **tái hiện đúng bug** — phải thấy nó fail đúng kiểu người dùng báo
2. Sửa code
3. Test chuyển xanh
4. Chạy toàn bộ suite để chắc không gây hồi quy

Không tái hiện được bằng test thì bạn chưa hiểu bug. Quay lại tìm nguyên nhân gốc trước.

## Test tốt

- **Một test một hành vi.** Fail là biết ngay hỏng chỗ nào.
- **Tên nói rõ hành vi**: `don_hang_da_huy_khong_tinh_vao_doanh_thu`, không phải `test_order_2`.
- **Kiểm hành vi, không kiểm cách cài đặt.** Test gọi hàm private hoặc đếm số lần gọi nội bộ
  sẽ vỡ mỗi lần refactor dù phần mềm vẫn đúng.
- **Ưu tiên test tích hợp hơn mock.** Mock nhiều thì test xanh trong khi hệ thống thật hỏng.
  Mock những gì chậm hoặc ngoài tầm kiểm soát (API bên thứ ba, gửi mail), không mock code
  của chính mình.

## Không được làm

Sửa test cho khớp code sai. Test đỏ nghĩa là **một trong hai** sai — xác định cái nào trước
khi động vào. Đổi assert để hết đỏ là xoá mất thứ duy nhất đang bảo vệ bạn.

Bỏ qua test (`skip`, `only`) rồi quên bật lại. Cần bỏ qua thì nói rõ với người dùng và ghi lý do.
