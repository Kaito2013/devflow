# Quy trình Build Runner & Sinh Code (Flutter)

Khi dự án Flutter sử dụng các thư viện sinh code (Freezed, JsonSerializable, Riverpod Generator, AutoRoute, Drift/Floor):

## 1. Dấu hiệu cần chạy Build Runner
Bắt buộc phải chạy `build_runner` khi:
- Thêm hoặc sửa model có annotation `@freezed`, `@JsonSerializable()`.
- Định nghĩa lại State, Event trong BLoC / Riverpod / MobX generator.
- Thay đổi cấu hình routes (AutoRoute) hoặc database schema (Drift).
- Sau khi pull code mới về mà thấy các file `.g.dart` hoặc `.freezed.dart` báo đỏ (missing members).

## 2. Lệnh Chạy Chuẩn
- **Chạy một lần và ghi đè file xung đột:**
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
- **Chạy ở chế độ lắng nghe (Watch mode) khi đang code:**
  ```bash
  dart run build_runner watch --delete-conflicting-outputs
  ```

## 3. Xử lý Lỗi Xung Đột Code Gen
Nếu gặp lỗi `Conflicting outputs was detected` hoặc build runner bị treo cache:
```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

## 4. Quy ước Git cho File Sinh Ra
- Kiểm tra `.gitignore` của dự án:
  - Nếu dự án **commit** code gen: Bắt buộc chạy build runner và commit cả file `.g.dart` / `.freezed.dart` cùng với model chính.
  - Nếu dự án **ignore** code gen: Đảm bảo script CI/CD có bước chạy `dart run build_runner build` trước khi chạy test.
