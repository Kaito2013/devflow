---
name: handoff
description: Preserve context across sessions or phase boundaries ("bàn giao phiên", "lưu ngữ cảnh"). Summarizes completed work, blockers, decisions, and exact next steps into devflow/handoffs/ before /clear or /compact.
---

# Bàn giao phiên & Bảo toàn ngữ cảnh (/devflow:handoff)

Mục tiêu: tạo một **checkpoint bằng văn bản** khi phiên làm việc sắp hết ngữ cảnh hữu dụng (ngưỡng Smart Zone ~150k token), khi chuẩn bị `/clear` hoặc `/compact`, hoặc khi bàn giao việc cho phiên làm việc khác.

Trí nhớ hội thoại sẽ mất hoặc mờ đi qua compaction. Một file markdown lưu trên đĩa là sự thật bất biến.

---

## Khi nào sử dụng

- Session kéo dài, context đạt > 100k–150k token và mô hình bắt đầu phản hồi chậm hoặc quên chi tiết.
- Cần đổi nhánh, đổi thư mục làm việc, hoặc chuyển sang chế độ thực thi khác.
- Kết thúc ngày làm việc và muốn ngày mai tiếp tục mà không cần giải thích lại từ đầu.

---

## Cấu trúc file bàn giao

Xuất file vào `devflow/handoffs/YYYY-MM-DD-<tên-tính-năng>.md`:

```markdown
# Bàn giao: <Tên tính năng / Công việc>

- **Thời điểm:** YYYY-MM-DD HH:mm
- **Nhánh Git:** `<tên-nhánh>` (Worktree: `<đường-dẫn-nếu-có>`)
- **Plan liên quan:** `devflow/plans/<file>-plan.md` (nếu có)
- **Spec liên quan:** `devflow/specs/<file>-spec.md` (nếu có)

## 1. Việc đã hoàn thành
- [x] Task 1: <Mô tả ngắn> — Commit: `abc1234`
- [x] Task 2: <Mô tả ngắn> — Commit: `def5678`

## 2. Việc đang dở dang (In Progress)
- **Đang làm:** Task N — <Mô tả điểm đang dừng>
- **File đang sửa dở:** `path/to/file.php`
- **Khó khăn / Điểm nghẽn (Blockers):** [Nếu có]

## 3. Quyết định kỹ thuật đã chốt trong phiên này
- Đã chọn phương án [A] thay vì [B] vì: [Lý do]
- Cấu trúc dữ liệu đã thống nhất: [Mô tả ngắn]

## 4. Hành động chính xác cho phiên tiếp theo
Chạy câu lệnh sau ngay khi mở session mới:
> *"Đọc file `devflow/handoffs/YYYY-MM-DD-<tên>.md` và tiếp tục triển khai [Task N] trong plan `devflow/plans/<file>-plan.md`"*
```

---

## Quy tắc

1. **Commit code trước khi handoff:** Không để file sửa dở ở trạng thái mất dấu. Nếu chưa xong hẳn, tạo commit tạm (`git commit -m "wip: <nội dung dở dang>"`).
2. **Commit luôn file handoff:**
   ```bash
   git add devflow/handoffs/ && git commit -m "docs: handoff for <tên>"
   ```
3. **Chỉ dẫn dứt khoát cho người dùng:** Sau khi xuất file xong, nói rõ với người dùng:
   *"Bàn giao đã lưu tại `devflow/handoffs/<file>.md`. Bạn có thể an tâm gõ `/clear` để làm sạch context và bắt đầu phiên mới."*
