---
name: analyze
description: "Scan and index an existing codebase using codebase-memory-mcp (knowledge graph) and serena (LSP symbol intelligence) to build a structural knowledge graph, symbol index, and domain context in devflow/CONTEXT.md."
---

# Phân tích & Quét kiến trúc Codebase (/devflow:analyze)

Sử dụng skill này khi mới tiếp nhận một dự án có sẵn, khi khám phá vùng code xa lạ, hoặc khi người dùng gõ `/devflow:analyze`.

Mục tiêu: hiểu sâu kiến trúc hệ thống và sinh file `devflow/CONTEXT.md` mà **không tốn token quét vét file hàng loạt**.

**Thông báo khi bắt đầu:** "🔍 /devflow:analyze — Đang phân tích kiến trúc codebase..."

---

## 🛠️ Quy trình thực hiện

### Bước 1: Khám phá cấu trúc

#### Phương án A: Có MCP (`codebase-memory-mcp` & `serena`)
1. **Kiểm tra đồ thị tri thức (`codebase-memory-mcp`)**:
   - Gọi `codebase-memory-mcp:index_status` hoặc `codebase-memory-mcp:index_repository`.
   - Gọi `codebase-memory-mcp:get_architecture` để hiểu các cụm thư mục và ranh giới module.
   - Gọi `codebase-memory-mcp:search_graph` định vị các hub/bridge files (những file có bán kính ảnh hưởng lớn).
2. **Trích xuất Symbol bằng LSP (`serena`)**:
   - Gọi `serena:initial_instructions` và `serena:activate_project`.
   - Gọi `serena:get_symbols_overview` để nắm các class, method, type cốt lõi.
   - Gọi `serena:find_referencing_symbols` cho các service quan trọng.

#### Phương án B: Fallback khi không có MCP (Native Inspection)
Nếu môi trường chưa cài đặt MCP, tự động chuyển sang đọc file cấu hình hệ thống:
1. **Xác định Stack & Dependencies**:
   - Đọc `composer.json` (Laravel/PHP), `package.json` (Node), `pubspec.yaml` (Flutter), hoặc `style.css` (WordPress).
   - Xác định phiên bản framework, ORM, thư viện xác thực, test runner.
2. **Quét thư mục cốt lõi**:
   - Quét entry points: `routes/` (Laravel), `src/` hoặc `routes/` (Node), `lib/main.dart` (Flutter), `functions.php` (WordPress).
   - Quét Data Models: `app/Models/` (Laravel), `src/models/` hoặc Prisma schema (Node).
3. **Định vị Test Seam**:
   - Kiểm tra `tests/` hoặc script test trong `package.json`.

---

### Bước 2: Tổng hợp tri thức vào `devflow/CONTEXT.md`

Luôn tạo hoặc cập nhật file `devflow/CONTEXT.md` theo cấu trúc chuẩn:

```markdown
# Bối cảnh dự án & Mô hình nghiệp vụ

## 1. Tổng quan hệ thống & Tech Stack
- **Framework/Runtime**: [Ví dụ: Laravel 11 / PHP 8.3 / MySQL]
- **Thư viện chính**: [Ví dụ: Sanctum, Livewire, Tailwind]

## 2. Từ điển thuật ngữ nghiệp vụ (Glossary)
- **<Thuật ngữ A>**: [Ý nghĩa, vai trò trong hệ thống]
- **<Thuật ngữ B>**: [Ý nghĩa, vai trò trong hệ thống]

## 3. Ranh giới kiến trúc & Module cốt lõi
- **Điểm vào (Entry Points)**: [HTTP Controllers / Console Commands / API Routes]
- **Tầng nghiệp vụ (Domain/Service)**: [Services, Actions, Repositories]
- **Thực thể dữ liệu (Data Models)**: [Eloquent Models, DB Tables chính]

## 4. Các file trọng yếu (Hub & Bridge Files)
- `path/to/HubFile.php`: [Vì sao quan trọng, mức độ ảnh hưởng nếu sửa]

## 5. Điểm kiểm chứng & Hạ tầng Test
- **Lệnh chạy test**: `php artisan test` (hoặc `npm test`, `flutter test`)
- **File test mẫu**: `tests/Feature/...`, `tests/Unit/...`
```

---

### Bước 3: Bàn giao

Sau khi tạo/cập nhật `devflow/CONTEXT.md`, tóm tắt 2–3 điểm kiến trúc đáng chú ý và gợi ý bước tiếp theo:
1. **Làm rõ yêu cầu mới:** Chuyển sang `/devflow:clarify-requirements`.
2. **Lập kế hoạch làm việc:** Chuyển sang `/devflow:write-plan`.
