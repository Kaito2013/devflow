# Quy tắc Tối ưu Hiệu năng Laravel

Khi review code liên quan đến Database và Eloquent trong Laravel:

## 1. Triệt Tiêu N+1 Query
- **Bắt buộc Eager Loading:** Khi duyệt qua một danh sách model và truy cập quan hệ của nó trong Blade hoặc Resource, phải nạp trước bằng `with(...)`:
  ```php
  // Sai (Gây N+1 query):
  $orders = Order::all();
  foreach ($orders as $order) { echo $order->user->name; }

  // Đúng:
  $orders = Order::with('user')->get();
  ```
- Sử dụng `loadMissing()` khi quan hệ chưa được nạp sẵn.
- Bật cơ chế phát hiện N+1 trong môi trường local (`Model::preventLazyLoading(!app()->isProduction())`).

## 2. Quản lý Bộ Nhớ với Tập Dữ Liệu Lớn
- Tuyệt đối không dùng `Model::all()` hoặc `Model::get()` khi số lượng bản ghi có thể vượt quá vài trăm.
- **Xử lý hàng loạt:** Dùng `chunk()`, `chunkById()`, hoặc `lazy()` (LazyCollection) để tránh tràn RAM PHP:
  ```php
  Order::where('status', 'pending')->chunkById(200, function ($orders) {
      foreach ($orders as $order) { ... }
  });
  ```
- **Phân trang:** Mọi API danh sách phải dùng `paginate($limit)` hoặc `simplePaginate($limit)`.

## 3. Caching Chiến Lược
- Dùng `Cache::remember('key', $ttl, function () { ... })` cho dữ liệu đọc nhiều nhưng ít thay đổi (Cài đặt hệ thống, danh mục gốc, danh sách quyền).
- Xóa hoặc cập nhật cache thông qua Eloquent Model Events (`saved`, `deleted`) hoặc Observer để tránh stale data.

## 4. Tránh Query Trong Accessor
- Không gọi quan hệ hoặc chạy query database bên trong Attribute Accessor (`getSomeAttribute()`). Điều này biến mỗi lần truy cập thuộc tính thành một query ẩn.
