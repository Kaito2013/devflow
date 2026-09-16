# Quy ước Code Review cho Laravel

Khi review code Laravel, tập trung vào các điểm sau:

## 1. Controllers & Requests
- Không viết logic nghiệp vụ phức tạp trực tiếp trong Controller; đẩy về Action, Service hoặc Job.
- Toàn bộ dữ liệu từ request người dùng phải qua **FormRequest** với rules validation rõ ràng, không dùng `$request->validate()` tùy tiện hoặc đọc raw input không qua validation.
- Sử dụng `$request->validated()` thay vì `$request->all()`.

## 2. Eloquent & Database
- **Chống N+1 Query:** Luôn eager loading (`with(['relation'])`) khi lấy danh sách liên kết. Không gọi quan hệ bên trong vòng lặp `foreach`.
- **Transactions:** Khi có từ 2 thao tác ghi/sửa/xóa database liên quan nhau, bắt buộc bọc trong `DB::transaction(function () { ... })`.
- **Mass Assignment:** Model phải khai báo rõ `$fillable` (ưu tiên hơn `$guarded = []`).

## 3. Authorization & Security
- Luôn kiểm tra quyền bằng Policy hoặc Gate (`$this->authorize()` hoặc `Gate::allows()`) trước các hành động nhạy cảm.
- Tránh lộ thông tin nhạy cảm qua API: sử dụng **API Resource** (`JsonResource`) thay vì trả trực tiếp Eloquent model ra JSON.

## 4. Code Style & Testing
- Format chuẩn PSR-12 / Laravel Pint.
- Feature test phải bao phủ các luồng: Happy path (200/201), Unauthenticated (401), Unauthorized (403), Validation fail (422).
