# ⚡ devflow

<p align="center">
  <strong>Bộ skill phát triển AI tinh gọn, thực chiến dành riêng cho stack WordPress · Laravel · Node · Flutter.</strong>
</p>

<p align="center">
  <a href="#benchmark"><img src="https://img.shields.io/badge/Always--on%20Tokens-~720%20tokens-brightgreen?style=flat-square" alt="Token Budget"></a>
  <a href="#danh-mục-skill"><img src="https://img.shields.io/badge/Skills-15%20Skills-blue?style=flat-square" alt="Skill Count"></a>
  <img src="https://img.shields.io/badge/Stack-WordPress%20%7C%20Laravel%20%7C%20Node%20%7C%20Flutter-orange?style=flat-square" alt="Supported Stacks">
  <img src="https://img.shields.io/badge/Architecture-Zero--Submodule-purple?style=flat-square" alt="Zero Submodule">
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License">
</p>

---

<a name="benchmark"></a>
## ⚡ So sánh Benchmark: `devflow` vs `supercoders`

| Tiêu chí | `supercoders` (Upstream) | `devflow` (Repo này) | Lợi thế của devflow |
| :--- | :---: | :---: | :--- |
| **Always-on Token** | ~3.345 token | **~720 token** | 🟢 **Tiết kiệm ~78% context** |
| **Số lượng Skill** | 56 skills | **15 skills** | 🟢 Tinh gọn, không trùng lặp |
| **Cấu trúc Git** | Git Submodules | **Zero Submodule** | 🟢 Độc lập 100%, không lo mất code |
| **Nguyên tắc hành vi** | 10+ skills riêng lẻ (~2.100 dòng) | **`CLAUDE.md` + Hook (~80 dòng)** | 🟢 Tự động nạp, hiệu lực sắt đá |
| **Hỗ trợ WordPress** | Không có hoặc bị xóa đè | **Bộ 3 skill chuyên sâu + WPCS** | 🟢 Đầy đủ ACF, Polylang, Seeder |
| **Cô lập an toàn** | Sửa trực tiếp trên main repo | **`isolate-worktree` tự động** | 🟢 Không làm bẩn nhánh đang xem |

---

## 🚀 Cài đặt nhanh

### 1. Cài đặt Plugin

```bash
git clone <repo-url> ~/devflow
claude plugin marketplace add ~/devflow
claude plugin install devflow@devflow
```

> **Mẹo:** Nếu đang cài `supercoders`, hãy tắt đi để tránh xung đột lệnh:
> ```bash
> claude plugin disable supercoders --scope project
> ```

### 2. Cài đặt Pre-commit Hook tự động (Tùy chọn nhưng khuyến nghị)

Tự động kiểm tra cú pháp PHP (`php -l`), Laravel Pint, ESLint, hoặc Flutter analyze trước mỗi lần `git commit`:

```bash
bash ~/devflow/scripts/setup-pre-commit.sh
```

---

## 🔄 Chuỗi phát triển & 3 Luồng thực thi

### Sơ đồ toàn trình (The Main Flow)

```text
clarify-requirements ──> write-plan ──> isolate-worktree ──> subagent-execution ──> review-changes ──> verify-done
                                                                   │           │
                                                                   ▼           ▼
                                                              test-first   ui-design
```

### 3 Luồng thực thi theo tính chất công việc

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ 1. VIỆC LỚN (Tính năng mới, đổi kiến trúc)                                            │
│    clarify-requirements ──> write-plan ──> isolate-worktree ──> SDD ──> verify-done     │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ 2. VIỆC GỌN (Sửa đổi cục bộ trong vài file)                                           │
│    clarify-requirements (chốt chat) ──> [test-first / ui-design] ──> verify-done ──> commit │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ 3. SỬA BUG (Truy nguyên nhân gốc)                                                      │
│    diagnose-bug (Feedback loop đỏ) ──> test-first (Test đỏ) ──> Fix ──> verify-done       │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

<a name="danh-mục-skill"></a>
## 🛠️ Danh mục 15 Skills

### 1. Chuỗi phát triển cốt lõi (8 skills)

| Skill | Lệnh gọi | Vai trò & Nhiệm vụ |
| :--- | :--- | :--- |
| **`clarify-requirements`** | `/devflow:clarify-requirements` | Phỏng vấn làm rõ yêu cầu ("Vặt/Gọn/Lớn"), xuất đặc tả vào `devflow/specs/` |
| **`write-plan`** | `/devflow:write-plan` | Lập kế hoạch, chia task độc lập gắn tag `[UI]`/`[Backend]`, xuất `devflow/plans/` |
| **`isolate-worktree`** | `/devflow:isolate-worktree` | Tạo workspace cô lập tại `.worktrees/`, copy `.env`, build assets trước khi chạy |
| **`subagent-execution`** | `/devflow:subagent-execution` | Điều phối SDD trong worktree: 1 Implementer + 1 Reviewer/task, ghi ledger |
| **`test-first`** | `/devflow:test-first` | Ép viết test đỏ trước khi code (Laravel, Node, Flutter). Bỏ qua cho theme WP |
| **`ui-design`** | `/devflow:ui-design` | Cam kết định hướng thẩm mỹ (Chữ, Màu, Bố cục) trước khi viết markup |
| **`review-changes`** | `/devflow:review-changes` | Tiền kiểm linter + review 2 trục: Quy ước repo (đối chiếu references) và Đặc tả |
| **`verify-done`** | `/devflow:verify-done` | Nghiệm thu thực tế: dán output thật, kiểm tra đường dẫn vào UI từ màn hình chính |

### 2. Sửa Bug & Quản lý Ngữ cảnh (2 skills)

| Skill | Lệnh gọi | Vai trò & Nhiệm vụ |
| :--- | :--- | :--- |
| **`diagnose-bug`** | `/devflow:diagnose-bug` | Thiết lập Tight Feedback Loop tái hiện lỗi < 5s, khoanh vùng nguyên nhân gốc |
| **`handoff`** | `/devflow:handoff` | Tạo checkpoint bàn giao phiên vào `devflow/handoffs/` khi context chạm Smart Zone (~150k) |

### 3. Bộ Skill Chuyên biệt theo Stack & Công cụ (5 skills)

| Skill | Lệnh gọi | Stack mục tiêu | Vai trò & Nhiệm vụ |
| :--- | :--- | :--- | :--- |
| **`wp-theme-converter`** | `/devflow:wp-theme-converter` | WordPress | Chuyển đổi HTML template sang theme WordPress hoàn chỉnh (CPT, ACF, Polylang Shim, Seeder) |
| **`wp-security-audit`** | `/devflow:wp-security-audit` | WordPress | Audit bảo mật & chất lượng code theo WPCS và Plugin Check (40+ rules của DevVN) |
| **`wp-responsive-check`** | `/devflow:wp-responsive-check` | Web / WP | Tự động kiểm thử responsive đa kích thước (320px–1440px) bằng Playwright MCP |
| **`analyze`** | `/devflow:analyze` | Toàn bộ stack | Quét kiến trúc codebase bằng Graph/LSP (hoặc native fallback), sinh `CONTEXT.md` |
| **`serena`** | `/devflow:serena` | Toàn bộ stack | Điều hướng symbol theo chuẩn LSP AST, chẩn đoán lỗi kiểu dữ liệu và sửa code an toàn |

---

## 💡 Cách sử dụng

Skill **tự kích hoạt thông minh** dựa trên ngữ cảnh bạn yêu cầu, không bắt buộc phải gõ lệnh:

* *"Tôi muốn thêm tính năng thanh toán VNPay vào module đơn hàng"* $\rightarrow$ kích hoạt `clarify-requirements`
* *"App này đang bị lỗi 500 khi nhấn nút đặt hàng"* $\rightarrow$ kích hoạt `diagnose-bug`
* *"Kiểm tra bảo mật và chất lượng code plugin này"* $\rightarrow$ kích hoạt `wp-security-audit`
* *"Convert bộ HTML trong thư mục template sang theme WP"* $\rightarrow$ kích hoạt `wp-theme-converter`
* *"Quét kiến trúc dự án này giúp tôi"* $\rightarrow$ kích hoạt `analyze`

*(Bạn vẫn có thể gõ trực tiếp `/devflow:<tên-skill>` bất cứ khi nào muốn ép chạy một skill cụ thể).*

---

## 🧠 Nguyên tắc cắt ngang (Trong `CLAUDE.md`)

Thay vì tốn hàng ngàn token cho các skill rời rạc, 4 nguyên tắc cốt lõi được nạp trực tiếp qua hook `SessionStart`:

1. **Bằng chứng trước khẳng định:** Không nói "xong", "đã sửa", "test pass" nếu chưa chạy lệnh và dán output thật ra.
2. **Truy nguyên nhân gốc:** Luôn tìm nguyên nhân trước khi sửa. Nghiêm cấm vá triệu chứng.
3. **Test đỏ trước khi code:** Áp dụng cho các dự án có test suite (Laravel, Node, Flutter). Theme WordPress kiểm chứng bằng render thật.
4. **Không tự mở rộng phạm vi:** Làm đúng việc được yêu cầu. Không tự ý refactor những phần không liên quan.

---

## 📁 Cấu trúc Artifacts chuẩn

Mọi tài liệu và báo cáo do agent sinh ra đều được gom gọn gàng trong thư mục `devflow/` tại gốc dự án:

```text
devflow/
├── CONTEXT.md                       Bản đồ kiến trúc & từ điển thuật ngữ nghiệp vụ
├── specs/YYYY-MM-DD-<tên>-spec.md   Tài liệu đặc tả yêu cầu
├── plans/YYYY-MM-DD-<tên>-plan.md   Kế hoạch triển khai chia nhỏ task
├── handoffs/YYYY-MM-DD-<tên>.md     Checkpoint bàn giao tiến độ qua các phiên
└── adr/NNNN-<quyết-định>.md         Biên bản ghi nhận quyết định kiến trúc (ADR)
```

---

## 🔌 Yêu cầu MCP (Model Context Protocol)

| Skill | Yêu cầu MCP | Phương án Fallback khi thiếu MCP |
| :--- | :--- | :--- |
| `analyze` | `codebase-memory-mcp` + `serena` | Tự động phân tích file manifest (`composer.json`, `package.json`, routes) bằng native tools |
| `serena` | `serena` | Sử dụng `grep_search`, `find_by_name`, `view_file` |
| `wp-responsive-check` | Playwright MCP / Chrome DevTools MCP | Phân tích cú pháp CSS tĩnh + hướng dẫn kiểm tra trực quan trên DevTools |

---

## 🤝 Ghi công & Cảm ơn

- Phần chuỗi quy trình phát triển và `CLAUDE.md` được viết mới 100%, lấy cảm hứng từ các triết lý nền tảng của [`obra/superpowers`](https://github.com/obra/superpowers) (Jesse Vincent) và [`mattpocock/skills`](https://github.com/mattpocock/skills) (Matt Pocock).
- `wp-security-audit` kế thừa và phát triển từ bộ quy chuẩn bảo mật WordPress của **lucas (DevVN)**.

---

<p align="center">
  Phát triển bởi <strong>Hoai Minh</strong> · Phát hành theo giấy phép <strong>MIT</strong>
</p>
