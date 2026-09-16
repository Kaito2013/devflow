---
name: write-plan
description: Split multi-step work ("lập kế hoạch") into independent tasks, each with its own verification criteria. Use once a spec or clear requirement exists, before touching code. Outputs into devflow/plans/.
---

# Lập kế hoạch triển khai

Mục tiêu: chia việc thành các task mà **một subagent làm được trọn vẹn trong một lượt**, và
kiểm chứng được độc lập.

## Đọc trước

Nếu có spec trong `devflow/specs/`, đọc nó. Nếu chưa có và yêu cầu còn mơ hồ, dừng lại và
gọi `devflow:clarify-requirements` trước — lập kế hoạch trên nền mơ hồ chỉ đẩy sự mơ hồ xuống dưới.

Nếu là codebase có sẵn và bạn chưa nắm cấu trúc, gọi `devflow:analyze` trước để có `CONTEXT.md`.

## Môi trường chạy thật — hỏi, đừng tự chọn

Task đầu tiên của một dự án mới (hoặc bất kỳ task nào chọn hạ tầng: DB engine, cache
driver, queue driver) **không được tự mặc định** kiểu "sqlite là đủ cho dev". Trước khi viết
task đó:

- Có `.env` hoặc `.env.example` sẵn trong repo với giá trị thật (host, user, tên DB) — dùng
  đúng cái đó, đừng ghi đè bằng mặc định của framework.
- Không có gì sẵn — hỏi một câu: *"Dự án chạy trên môi trường nào? (MySQL/Postgres/SQLite,
  host, tên DB nếu đã có sẵn)"*. Một câu này rẻ hơn nhiều so với cả plan chạy xong rồi
  `migrate` fail vì không có DB thật, hoặc chạy được trên SQLite nhưng production dùng MySQL
  nên hành vi khác đi (charset, giới hạn độ dài chuỗi, kiểu enum).
- Ghi giá trị đã xác nhận vào task đó luôn (host, user, tên DB) — implementer không tự đoán
  lại lần nữa.

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

## Task cuối của một tính năng có giao diện — kiểm đường vào, không chỉ kiểm route

Task "nối dây cuối" (đăng ký route, thêm link vào layout) rất dễ khiến reviewer thấy
`route:list` liệt kê đủ, test feature trả `200`, rồi kết luận xong — trong khi route đó
**không ai tới được** nếu không gõ thẳng URL. Route sống một mình trong Postman không phải
tính năng sống trong app.

Tiêu chí kiểm chứng của task này phải viết rõ một dòng không thể bỏ qua: *"đăng nhập bằng
tài khoản thật của vai trò liên quan, xuất phát từ màn hình mặc định sau đăng nhập (không
gõ URL tính năng trực tiếp), xác nhận có đường bấm tới được tính năng"*. Thiếu dòng này,
`subagent-execution` rất dễ coi "test tự động pass" là xong dù tính năng vô hình với người
dùng thật.

## Xung đột ghi file

Hai task cùng ghi một file thì **không** song song được, kể cả khi về logic chúng độc lập.
Trường hợp hay gặp: nhiều task cùng thêm route vào một file, cùng đăng ký service provider,
cùng tạo một partial dùng chung. Gộp lại thành một task, hoặc đẩy phần chung lên task thân.

## Khi nào ghi ADR (Architectural Decision Record)

Khi kế hoạch chứa một **quyết định kỹ thuật khó đảo ngược** (chọn cơ chế Auth, thư viện State Management, kiến trúc lưu file S3 vs Local, chọn DB Engine, đổi cấu trúc schema lớn):
- Tạo một file tại `devflow/adr/NNNN-<tên-quyết-định>.md` (dựa theo mẫu `devflow/adr/0000-template.md`).
- Ghi rõ: lý do chọn, các phương án đã loại bỏ, và cái giá phải trả (trade-offs). Điều này ngăn AI ở các phiên sau tự ý đổi kiến trúc.

## Định dạng file

Ghi vào `devflow/plans/YYYY-MM-DD-<tên>-plan.md`:

```markdown
# Kế hoạch: <tên>

Spec: devflow/specs/<file>.md
Stack: Laravel | Node | WordPress | Flutter
Có test: có / không   ← quyết định task có áp dụng test-first hay không

## Task 1 [Backend] — <tên ngắn>
**Làm gì:** ...
**File đụng tới:** `path/a.php`, `path/b.php`
**Phụ thuộc:** không / Task N
**Kiểm chứng:** lệnh cụ thể, hoặc thao tác cụ thể và kết quả mong đợi

## Task 2 [UI] — <tên màn hình>
**Làm gì:** ...
**File đụng tới:** `resources/views/...`
**Phụ thuộc:** Task 1
**Kiểm chứng:** thao tác bấm từ menu điều hướng, ảnh chụp màn hình hoặc render thật
```

**Quy tắc gắn nhãn task:**
- Gắn nhãn `[UI]` cho mọi task đụng đến giao diện mà người dùng nhìn thấy (Blade, Livewire, React, Vue, Flutter UI, HTML/CSS). `subagent-execution` sẽ tự động yêu cầu implementer đọc `devflow:ui-design` trước khi viết markup.
- Gắn nhãn `[Backend]` hoặc `[DB/Migration]` cho logic nghiệp vụ, schema, API.
- Dòng **Có test** quan trọng: nó quyết định implementer có chạy `devflow:test-first` hay không.

Ghi file xong thì **commit ngay**, cùng với spec nếu spec đó chưa commit
(`git add devflow/ && git commit -m "docs: add plan for <tên>"`). Kế
hoạch chưa commit thì không có mặt trong worktree mà `devflow:isolate-worktree` sắp tạo.

## Bàn giao

Kế hoạch xong thì báo: *"Kế hoạch đã lưu ở `devflow/plans/<file>.md`, gồm N task. Bắt đầu
triển khai bằng subagent?"*

- **Môi trường có subagent:** Người dùng đồng ý → gọi `devflow:isolate-worktree` rồi chuyển sang `devflow:subagent-execution`.
- **Môi trường không có subagent (hoặc người dùng muốn chạy trong session hiện tại):** Làm tuần tự từng task:
  1. Với mỗi task: chạy `devflow:test-first` (nếu có test) hoặc `devflow:ui-design` (nếu là task `[UI]`).
  2. Viết code tối thiểu để hoàn thành task.
  3. Tự kiểm tra lệnh ở mục **Kiểm chứng**, chạy linter.
  4. Commit task (`git commit -m "feat(task-<N>): ..."`).
  5. Hết các task thì gọi `devflow:verify-done` để nghiệm thu toàn bộ.
