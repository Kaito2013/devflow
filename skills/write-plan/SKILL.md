---
name: write-plan
description: Chia việc nhiều bước thành các task độc lập, mỗi task có tiêu chí kiểm chứng riêng. Dùng sau khi đã có spec hoặc yêu cầu rõ, trước khi chạm vào code. Xuất ra devflow/plans/.
---

# Lập kế hoạch triển khai

Mục tiêu: chia việc thành các task mà **một subagent làm được trọn vẹn trong một lượt**, và
kiểm chứng được độc lập.

## Đọc trước

Nếu có spec trong `devflow/specs/`, đọc nó. Nếu chưa có và yêu cầu còn mơ hồ, dừng lại và
gọi `devflow:clarify-requirements` trước — lập kế hoạch trên nền mơ hồ chỉ đẩy sự mơ hồ xuống dưới.

Nếu là codebase có sẵn và bạn chưa nắm cấu trúc, gọi `devflow:analyze` trước để có `CONTEXT.md`.

## Một task tốt trông thế nào

| Tiêu chí | Vì sao |
|---|---|
| Làm xong trong một lượt subagent | Task quá to thì subagent hết context giữa chừng |
| Có tiêu chí kiểm chứng cụ thể | Không có thì reviewer không biết dựa vào đâu |
| Nêu rõ file sẽ đụng tới | Để phát hiện hai task tranh nhau một file |
| Độc lập, hoặc ghi rõ phụ thuộc | Quyết định task nào chạy song song được |

Task kiểu *"làm phần backend"* là sai. Task kiểu *"thêm bảng `orders` với migration, model và
factory; kiểm bằng `php artisan migrate:fresh --seed` chạy sạch"* là đúng.

## Thứ tự task

Đặt task **thân** trước — thứ mà nhiều task khác phụ thuộc vào (schema, interface, layout
chung). Rồi mới tới các task **nhánh** có thể chạy song song.

Ghi rõ nhóm nào song song được. `devflow:subagent-execution` sẽ dùng thông tin này.

## Xung đột ghi file

Hai task cùng ghi một file thì **không** song song được, kể cả khi về logic chúng độc lập.
Trường hợp hay gặp: nhiều task cùng thêm route vào một file, cùng đăng ký service provider,
cùng tạo một partial dùng chung. Gộp lại thành một task, hoặc đẩy phần chung lên task thân.

## Định dạng file

Ghi vào `devflow/plans/YYYY-MM-DD-<tên>-plan.md`:

```markdown
# Kế hoạch: <tên>

Spec: devflow/specs/<file>.md
Stack: Laravel | Node | WordPress | Flutter
Có test: có / không   ← quyết định task có áp dụng test-first hay không

## Task 1 — <tên ngắn>
**Làm gì:** ...
**File đụng tới:** `path/a.php`, `path/b.php`
**Phụ thuộc:** không / Task N
**Kiểm chứng:** lệnh cụ thể, hoặc thao tác cụ thể và kết quả mong đợi

## Task 2 — ...
```

Dòng **Có test** quan trọng: nó quyết định implementer có chạy `devflow:test-first` hay không. Theme
WordPress ghi "không" — kiểm chứng bằng render thật thay vì unit test.

## Bàn giao

Kế hoạch xong thì báo: *"Kế hoạch đã lưu ở `devflow/plans/<file>.md`, gồm N task. Bắt đầu
triển khai bằng subagent?"*

Người dùng đồng ý → gọi `devflow:subagent-execution`. Đây là đường đi mặc định khi môi trường có
subagent. Không có subagent thì nói rõ và làm tuần tự, review sau mỗi task.
