# Quy ước Hợp Đồng API & Schema Validation (Node/TS)

Khi xây dựng hoặc review REST API trong môi trường Node.js / TypeScript:

## 1. Xác Thực Đầu Vào Bằng Schema (Zod / Joi)
- Mọi endpoint nhận dữ liệu từ client (`req.body`, `req.query`, `req.params`) bắt buộc phải có schema validation rõ ràng trước khi đi vào controller:
  ```typescript
  import { z } from 'zod';

  export const CreateOrderSchema = z.object({
    items: z.array(z.object({
      productId: z.string().uuid(),
      quantity: z.number().int().positive()
    })).nonempty(),
    paymentMethod: z.enum(['vnpay', 'cod', 'momo']),
  });

  export type CreateOrderInput = z.infer<typeof CreateOrderSchema>;
  ```

## 2. Chuẩn Hóa Cấu Trúc Response Thống Nhất
Mọi API response phải tuân thủ format tiêu chuẩn:
- **Thành công:**
  ```json
  {
    "success": true,
    "data": { ... },
    "meta": { "page": 1, "limit": 20, "total": 100 } // nếu có phân trang
  }
  ```
- **Thất bại:**
  ```json
  {
    "success": false,
    "error": {
      "code": "VALIDATION_FAILED",
      "message": "Dữ liệu gửi lên không hợp lệ",
      "details": [ ... ]
    }
  }
  ```

## 3. Mã HTTP Status Chuẩn
- `200 OK`: Truy vấn thành công, cập nhật thành công.
- `201 Created`: Tạo mới resource thành công (kèm URI nếu có).
- `204 No Content`: Xóa thành công, không cần trả về body.
- `400 Bad Request`: Sai format dữ liệu, vi phạm schema validation.
- `401 Unauthorized`: Chưa đăng nhập hoặc token hết hạn/không hợp lệ.
- `403 Forbidden`: Đã đăng nhập nhưng không có quyền thực hiện hành động này.
- `404 Not Found`: Không tìm thấy resource.
- `500 Internal Server Error`: Lỗi logic máy chủ (phải log lại stack trace, không trả stack trace cho client).
