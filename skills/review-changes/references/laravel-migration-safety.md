# Quy tắc An toàn Database Migration (Laravel)

Khi review hoặc viết Migration trong Laravel, bắt buộc tuân thủ các nguyên tắc sau để bảo vệ dữ liệu production:

## 1. Tính Khả Nghịch (Rollback Safety)
- **Mọi migration đều phải có phương thức `down()` hoàn chỉnh**: Nếu `up()` tạo bảng $\rightarrow$ `down()` xóa bảng (`dropIfExists`). Nếu `up()` thêm cột $\rightarrow$ `down()` xóa cột (`dropColumn`).
- Kiểm tra tính hoàn nguyên bằng lệnh:
  ```bash
  php artisan migrate && php artisan migrate:rollback
  ```

## 2. Thao tác trên Bảng Lớn (Production Table)
- **Không thêm cột `NOT NULL` mà không có giá trị mặc định**: Với bảng đã có dữ liệu, thêm cột bắt buộc phải là `nullable()` hoặc có `default(...)`.
- **Tránh Lock Bảng:**
  - Không chạy các phép tính nặng hoặc update dữ liệu hàng loạt bên trong file migration.
  - Sử dụng Seeder hoặc Artisan Command riêng biệt cho việc migrate dữ liệu (Data Migration).
- Luôn đặt vị trí cột hợp lý bằng `after('column_name')` trên MySQL để giữ cấu trúc bảng gọn gàng.

## 3. Khóa Ngoại & Index (Indexing)
- Mọi cột dùng làm Foreign Key (`*_id`) hoặc thường xuyên xuất hiện trong mệnh đề `WHERE`, `ORDER BY` bắt buộc phải được đánh **Index**:
  ```php
  $table->foreignId('user_id')->constrained()->cascadeOnDelete()->index();
  ```
- Khi xóa cột có Foreign Key trong `down()`, phải xóa Foreign Key trước khi xóa cột:
  ```php
  $table->dropForeign(['user_id']);
  $table->dropColumn('user_id');
  ```

## 4. Tương thích Đa Database (MySQL vs SQLite)
- Khi dùng SQLite cho testing (`phpunit` / `:memory:`), tránh đổi kiểu dữ liệu cột phức tạp (`change()`) mà không cài thư viện `doctrine/dbal`.
- Không dùng các kiểu dữ liệu đặc thù của MySQL (`json`, `geometry`) mà không có fallback hoặc kiểm tra driver nếu dự án chạy test trên SQLite.
