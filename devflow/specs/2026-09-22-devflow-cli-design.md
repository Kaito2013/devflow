# Spec: devflow-cli — Companion TUI Dashboard & Telegram Remote Control

- **Tài liệu:** Thiết kế kiến trúc & Đặc tả kỹ thuật (Technical Specification)
- **Dự án:** `devflow-cli` (Module vệ tinh độc lập cho `devflow`)
- **Ngày lập:** 2026-09-22
- **Trạng thái:** Approved / Ready for Planning

---

## 1. Bối cảnh & Mục tiêu (Context & Goals)

### 1.1 Bối cảnh
`devflow` là bộ skill AI phát triển phần mềm tinh gọn (~720 tokens, zero-submodule), vận hành theo mô hình SDD (Subagent-Driven Development) và cô lập workspace qua git worktree. Khi thực thi các kế hoạch dài hơi (tính năng lớn, tái cấu trúc mã nguồn, chuyển đổi theme WordPress), người dùng gặp hai rào cản:
1. **Quá tải thông tin trong terminal:** Output của subagent, test run và linter cuộn liên tục khiến việc theo dõi tiến độ tổng thể trở nên khó khăn.
2. **Bị trói chân tại máy tính:** Không thể rời máy trong thời gian AI thực thi vì cần theo dõi lỗi kiểm thử hoặc phê duyệt thủ công từng bước chuyển task.

### 1.2 Mục tiêu
Xây dựng `devflow-cli` dưới dạng một công cụ dòng lệnh đồng hành (companion CLI) độc lập bằng **Go (Golang)**:
- **TUI Dashboard:** Bảng điều khiển trực quan bằng Bubbletea/Lipgloss hiển thị tiến độ kế hoạch, trạng thái từng task, trạng thái worktree và log phản hồi của reviewer.
- **Telegram Bot Remote Control:** Nhận thông báo thời gian thực khi task hoàn thành hoặc gặp lỗi, cung cấp cổng phê duyệt (Gate Approval) hai chiều qua các lệnh `/status`, `/approve`, `/diff`, `/stop` và nút bấm tương tác (Inline Buttons).
- **Nguyên tắc không xâm lấn (Non-intrusive):** Giao tiếp qua File Watcher và IPC Socket cục bộ; không bọc PTY terminal, không can thiệp vào tiến trình của Claude Code/AGY, không làm thay đổi bản sắc siêu nhẹ của core `devflow`.

---

## 2. Kiến trúc tổng thể (System Architecture)

```text
┌────────────────────────────────────────────────────────────────────────┐
│                              devflow-cli                               │
│                                                                        │
│   ┌──────────────────────────┐         ┌───────────────────────────┐   │
│   │      TUI Dashboard       │         │       Telegram Bot        │   │
│   │ (Bubbletea / Lipgloss)   │         │ (Goroutine / Long-polling)│   │
│   └────────────┬─────────────┘         └─────────────┬─────────────┘   │
│                │                                     │                 │
│                ▼                                     ▼                 │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │                       State Engine Hub                         │   │
│   │   - Session State (In-Memory + .devflow/session.json)          │   │
│   │   - Plan Markdown Parser (Checkbox parser)                     │   │
│   │   - Worktree Inspector (Git worktree state)                    │   │
│   │   - Gate Lock Manager (.devflow/gate.lock)                     │   │
│   └───────────────▲────────────────────────────────▲───────────────┘   │
│                   │                                │                   │
│   ┌───────────────┴───────────────┐ ┌──────────────┴───────────────┐   │
│   │      File Watcher Module      │ │     Unix Socket IPC Server   │   │
│   │     (fsnotify trên devflow/)  │ │     (~/.devflow/ipc.sock)    │   │
│   └───────────────────────────────┘ └──────────────────────────────┘   │
└───────────────────────────────────────────────────▲────────────────────┘
                                                    │
                 Sự kiện từ Hook                   │ CLI: devflow-cli notify ...
                 (subagent-execution, verify-done)  │ CLI: devflow-cli gate wait ...
┌───────────────────────────────────────────────────┴────────────────────┐
│                    devflow Core Skill Suite                            │
│                 (Chạy trong Claude Code / AGY)                         │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Đặc tả chi tiết từng Module (Component Specifications)

### 3.1 Module Cấu hình (`internal/config`)
- File cấu hình lưu tại: `~/.devflow/config.yaml`.
- Nếu chưa có, lệnh `devflow-cli init` sẽ tự động tạo file mẫu.
- Cấu trúc file cấu hình:
  ```yaml
  telegram:
    enabled: true
    bot_token: "YOUR_TELEGRAM_BOT_TOKEN"
    chat_id: 123456789             # Bắt buộc: Whitelist chỉ phản hồi 1 chat_id duy nhất
    notification_level: "all"      # all | approvals_only | errors_only
  tui:
    refresh_rate_ms: 500
    theme: "dark"                  # dark | light
  ipc:
    socket_path: "~/.devflow/ipc.sock"
  ```
- **Bảo mật:** Nghiêm cấm nhận lệnh từ bất kỳ Telegram `chat_id` nào ngoài ID đã cấu hình.

### 3.2 Module Quản lý Trạng thái (`internal/state`)
- **State Model:**
  ```go
  type TaskStatus string
  const (
      StatusTodo       TaskStatus = "TODO"
      StatusInProgress TaskStatus = "IN_PROGRESS"
      StatusReviewing  TaskStatus = "REVIEWING"
      StatusApproved   TaskStatus = "APPROVED"
      StatusFailed     TaskStatus = "FAILED"
  )

  type TaskItem struct {
      Index       int        `json:"index"`
      Title       string     `json:"title"`
      Tag         string     `json:"tag"` // e.g. "[UI]", "[Backend]"
      Status      TaskStatus `json:"status"`
      CommitHash  string     `json:"commit_hash,omitempty"`
      ReviewNotes string     `json:"review_notes,omitempty"`
  }

  type SessionState struct {
      PlanFile       string     `json:"plan_file"`
      FeatureName    string     `json:"feature_name"`
      WorktreePath   string     `json:"worktree_path"`
      Branch         string     `json:"branch"`
      Tasks          []TaskItem `json:"tasks"`
      GateWaiting    bool       `json:"gate_waiting"`
      WaitingTask    int        `json:"waiting_task"`
      LastUpdated    time.Time  `json:"last_updated"`
  }
  ```
- **Plan Markdown Parser:**
  - Định tuyến quét thư mục `devflow/plans/*.md`.
  - Phân tích cú pháp task dạng chuẩn markdown:
    - `- [ ] Task title` -> `StatusTodo`
    - `- [/] Task title` hoặc `- [>] Task title` -> `StatusInProgress`
    - `- [x] Task title` -> `StatusApproved`
  - Trích xuất tag chuyên biệt: `[UI]`, `[Backend]`, `[WP]`, `[Test]`.

### 3.3 Module File Watcher (`internal/watcher`)
- Sử dụng `github.com/fsnotify/fsnotify`.
- Giám sát 2 vị trí quan trọng:
  1. Thư mục `devflow/plans/`: Cập nhật lại `SessionState` ngay khi file kế hoạch có chỉnh sửa.
  2. Thư mục `.worktrees/`: Nhận biết worktree nào đang tồn tại và phát hiện sự thay đổi `HEAD`.
- Cơ chế Debounce: Gộp các sự kiện thay đổi file trong 200ms để tránh kích hoạt tính toán dư thừa.

### 3.4 Module IPC & Daemon (`internal/ipc`)
- Cung cấp giao tiếp cục bộ tốc độ cao thông qua **Unix Domain Socket** (`~/.devflow/ipc.sock`).
- Các lệnh CLI gửi qua IPC:
  - `devflow-cli notify --event <event_type> --task <task_name> --status <status> --commit <hash> --note <note>`
  - `devflow-cli gate wait --task <task_index>`: Block tiến trình cho đến khi nhận được tín hiệu `/approve` hoặc timeout.
  - `devflow-cli gate release --task <task_index>`: Mở khóa thủ công từ terminal.
- Định dạng gói tin: JSON truyền tải qua socket stream, phản hồi `{"status": "ok"}`.

### 3.5 Module TUI Dashboard (`internal/tui`)
- Xây dựng bằng framework **Bubbletea** (`github.com/charmbracelet/bubbletea`) và thư viện phối màu **Lipgloss** (`github.com/charmbracelet/lipgloss`).
- Giao diện chia 3 khối:
  1. **Header Block:** Tên Plan, Nhánh git, Đường dẫn worktree hiện tại, Trạng thái Daemon & Telegram (`Connected` / `Disabled`).
  2. **Task Progress Block:** Thanh tiến độ phần trăm `[██████░░░░] 60%`, danh sách các task với icon màu (`✔`, `▶`, `✖`, `○`), tag nghiệp vụ và commit hash.
  3. **Review / Log Block:** Khung hiển thị ghi chú mới nhất từ Reviewer subagent hoặc kết quả lệnh kiểm thử gần nhất.
  4. **Footer Hotkeys:**
     - `a`: Phê duyệt nhanh gate (Approve).
     - `d`: Xem diff git nhanh của worktree hiện tại.
     - `p`: Bật/tắt trạng thái tạm dừng (Pause).
     - `r`: Buộc đồng bộ lại file từ disk.
     - `q` / `Ctrl+C`: Thoát giao diện TUI.

### 3.6 Module Telegram Remote Control (`internal/telegram`)
- Sử dụng thư viện Telegram Bot API chính thống (`github.com/go-telegram-bot-api/telegram-bot-api/v5`).
- Chạy bằng cơ chế **Long-Polling** trong một Goroutine riêng biệt bên trong daemon.
- **Hệ thống Lệnh & Tương tác:**
  - `/status`: Trả về tiến độ hiện tại kèm thanh tiến độ ASCII, số task đã xong/tổng task.
  - `/approve`: Mở khóa gate đang đợi, cho phép AI tiếp tục sang task tiếp theo.
  - `/diff`: Chạy `git diff --stat` trong worktree hiện tại và gửi tóm tắt các file đã thay đổi.
  - `/stop`: Đặt trạng thái khẩn cấp, ghi file `.devflow/abort.lock` để các hook kế tiếp của AI tự động dừng lại.
- **Thông báo chủ động (Proactive Push):**
  - Khi Reviewer hoàn thành review task: Gửi tin nhắn kèm 2 nút bấm Inline Keyboard: `[ ✅ Approve ]` và `[ 📄 View Diff ]`.
  - Khi Test thất bại: Bắn cảnh báo màu đỏ kèm trích đoạn log lỗi.

---

## 4. Giao diện Dòng lệnh (CLI Interface)

Binary được đóng gói với tên `devflow`:

```bash
# Khởi tạo cấu hình và mẫu
devflow-cli init

# Mở giao diện TUI giám sát trực quan
devflow-cli tui

# Quản lý tiến trình daemon chạy ngầm (Telegram Bot & IPC Socket)
devflow-cli daemon start
devflow-cli daemon status
devflow-cli daemon stop

# Lệnh dành cho Hook của devflow gọi tự động
devflow-cli notify --task "Task 1" --status "APPROVED" --commit "f00c087"
devflow-cli gate wait --task "Task 1" --timeout 30m
devflow-cli gate release --task "Task 1"
```

---

## 5. Tích hợp với `devflow` Core (Integration Contract)

1. **Tính độc lập:**
   - Nếu máy tính **chưa cài** `devflow-cli`: `devflow` vẫn vận hành bình thường thông qua chat terminal như từ trước tới nay.
2. **Kích hoạt tự động khi có mặt:**
   - Trong script của skill `subagent-execution`:
     ```bash
     if command -v devflow-cli >/dev/null 2>&1; then
       # Gửi thông báo kết quả task
       devflow-cli notify --task "$TASK_TITLE" --status "$VERDICT" --commit "$COMMIT_HASH"
       
       # Nếu bật chế độ Gate Approval, đợi phê duyệt từ Telegram hoặc TUI
       if [ "${DEVFLOW_GATE_APPROVAL:-0}" = "1" ]; then
         echo "⏳ Đang đợi phê duyệt từ devflow-cli / Telegram..."
         devflow-cli gate wait --task "$TASK_INDEX"
       fi
     fi
     ```

---

## 6. Yêu cầu Phi chức năng & Kiểm thử (Non-Functional Requirements)

- **Hiệu năng & Tài nguyên:**
  - Tiêu thụ RAM khi chạy daemon + Telegram: **< 20MB**.
  - Mức chiếm dụng CPU khi nhàn rỗi: **< 0.5%**.
- **Tính tự phục hồi (Resilience):**
  - Mất kết nối internet: Telegram bot tự động reconnect theo thuật toán exponential backoff mà không làm sập daemon.
  - File kế hoạch bị hỏng cú pháp markdown: Parser bỏ qua phần lỗi, không panic, hiển thị thông báo "Kế hoạch đang cập nhật".
- **Kiểm thử tự động:**
  - Unit test cho parser markdown kế hoạch (`plan_test.go`).
  - Unit test cho state machine và gate lock (`state_test.go`).
  - Mock Telegram Bot API để kiểm tra luồng tin nhắn và xử lý command.
