# Quy ước Code Review cho Node / TypeScript

Khi review code Node.js / Express / NestJS / TypeScript, tập trung vào các điểm sau:

## 1. Async & Error Handling
- Mọi hàm `async` hoặc Promise phải có `try/catch` hoặc middleware bắt lỗi tập trung; tuyệt đối không để xảy ra `UnhandledPromiseRejection`.
- Tránh Promise hell / callback hell; ưu tiên `async/await`.
- Chạy các thao tác bất đồng bộ độc lập bằng `Promise.all()` thay vì `await` tuần tự gây chậm.

## 2. Input Validation & Type Safety
- Không dùng kiểu `any` vô tội vạ trong TypeScript; dùng `unknown` nếu chưa rõ kiểu và kết hợp type narrowing / Zod validation.
- Mọi dữ liệu đầu vào từ client (`req.body`, `req.query`, `req.params`) phải được parse & validate qua Zod, Yup, hoặc class-validator trước khi xử lý.

## 3. Bảo mật & Tài nguyên
- Không bao giờ log secret, password, private key hoặc token JWT ra console.
- Đóng kết nối DB pool, file stream đúng cách để tránh memory leak.
- Sanitization cho SQL/NoSQL queries để chống Injection.
