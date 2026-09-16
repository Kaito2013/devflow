# Quy ước Code Review cho Flutter / Dart

Khi review code Flutter, tập trung vào các điểm sau:

## 1. Widget Tree & Hiệu năng
- Sử dụng constructor `const` cho mọi Widget bất biến để Flutter engine không build lại không cần thiết.
- Tránh đặt các phép tính nặng hoặc gọi API trực tiếp trong hàm `build()`.
- Tách nhỏ các widget phức tạp thành các class riêng biệt thay vì viết các hàm trả về widget `_buildWidget()` (để tận dụng cơ chế element caching của Flutter).

## 2. Quản lý Tài nguyên (Lifecycle)
- Mọi `Controller` (`TextEditingController`, `AnimationController`, `ScrollController`, `StreamSubscription`) bắt buộc phải được giải phóng trong hàm `dispose()`.
- Kiểm tra `if (!mounted) return;` trước khi gọi `setState()` hoặc sử dụng `BuildContext` sau một khoảng chờ bất đồng bộ (`await`).

## 3. State Management & Layering
- Giữ UI tách biệt khỏi Business Logic (dùng BLoC, Riverpod, Provider).
- Không truyền `BuildContext` sâu vào các service layer hoặc repository layer.
- Bắt lỗi mạng/API bằng try-catch và hiển thị trạng thái Empty / Loading / Error rõ ràng cho người dùng.
