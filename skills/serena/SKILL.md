---
name: serena
description: "Serena code intelligence — LSP-powered symbol navigation, diagnostics, and targeted code surgery. Activate before complex refactors, cross-file analysis, or when graph tools need symbol-level depth."
---

# Serena — Điều hướng Code bằng LSP (/devflow:serena)

Kích hoạt Serena MCP để khai thác trí thông minh code chuẩn LSP: điều hướng symbol, chẩn đoán kiểu dữ liệu (diagnostics), và sửa code chính xác theo cấu trúc AST.

**BẮT BUỘC:** Luôn gọi `initial_instructions` trước tiên khi bắt đầu phiên làm việc với Serena.

## Khởi tạo & Cấu hình

1. **Nạp hướng dẫn**: `serena:initial_instructions()`
2. **Kích hoạt project**: `serena:activate_project()`
3. **Lấy tổng quan symbol**: `serena:get_symbols_overview()`

## Khi nào dùng Serena vs Native Tools

- **Dùng Serena khi:** Cần tìm chính xác định nghĩa/triển khai của interface (`find_declaration`, `find_implementations`), tìm toàn bộ nơi gọi hàm xuyên qua nhiều file (`find_referencing_symbols`), đổi tên symbol an toàn (`rename_symbol`), hoặc sửa đúng thân hàm (`replace_symbol_body`).
- **Dùng Native Tools (`grep_search`, `find_by_name`, `view_file`) khi:** Tìm chuỗi text đơn thuần, tìm file theo tên, đọc nhanh một đoạn code ngắn hoặc khi MCP Serena không khả dụng trong môi trường.

## Các công cụ chính
- **Điều hướng:** `find_symbol`, `find_declaration`, `find_implementations`, `find_referencing_symbols`
- **Chẩn đoán:** `get_diagnostics_for_file` (phát hiện lỗi type, syntax warning cấp độ IDE)
- **Thao tác code:** `replace_symbol_body`, `insert_after_symbol`, `insert_before_symbol`, `rename_symbol`
- **Bộ nhớ:** `write_memory`, `read_memory`
