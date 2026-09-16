# devflow — hướng dẫn cho agent

## Chuỗi phát triển

```
clarify-requirements → write-plan → isolate-worktree → subagent-execution → review-changes → verify-done
                                                              ↓          ↓
                                                         test-first  ui-design
```

Mỗi mắt xích là một skill. Skill trước bàn giao cho skill sau; không nhảy cóc.

### Ba luồng thực thi theo tính chất công việc:

1. **Việc Lớn (Tính năng mới, đổi kiến trúc):** Bắt buộc đi hết chuỗi:
   `clarify-requirements` (xuất spec) → `write-plan` (xuất plan có tag `[UI]`/`[Backend]`) → `isolate-worktree` (cô lập) → `subagent-execution` (điều phối SDD) → `review-changes` → `verify-done`.
2. **Việc Gọn (Sửa đổi luồng có sẵn trong vài file):** Không cần spec/plan file hay subagent:
   `clarify-requirements` (chốt 1 đợt trong chat) → `[test-first / ui-design nếu cần]` → sửa code trực tiếp → `verify-done` (chạy test/lint thật) → commit.
3. **Sửa Bug (Truy nguyên nhân gốc):** Không vá triệu chứng:
   Gọi `devflow:diagnose-bug` để thiết lập lệnh tái hiện và tìm nguyên nhân gốc → Viết test đỏ tái hiện (`devflow:test-first`) → Sửa code tối thiểu → `devflow:verify-done` (chạy toàn bộ suite xác nhận không hồi quy).

**Bảo toàn ngữ cảnh:** Khi session đạt > 100k–150k token (Smart Zone) hoặc kết thúc ngày làm việc, gọi `devflow:handoff` để lưu checkpoint vào `devflow/handoffs/` trước khi gõ `/clear`.

**Quy tắc bắt buộc:** khi kế hoạch đã viết xong và môi trường có subagent, **phải** dùng
`subagent-execution`. Không thực thi tuần tự trong session chính — làm vậy làm bẩn context
và bỏ qua vòng review độc lập.

## Quy tắc Git & Worktree trong SDD

- **Thư mục cô lập:** Mọi subagent phải nhận đúng biến `WORKTREE_PATH` để thao tác, không sửa nhầm main checkout.
- **Quyền commit:** Implementer **không** tự commit. Reviewer đọc diff (`git diff HEAD`). Chỉ khi Reviewer duyệt **Đạt**, Controller mới commit và ghi hash vào ledger.
- **Dọn dẹp:** Khi xong toàn bộ plan và người dùng duyệt merge, dọn dẹp worktree (`git worktree remove`) để tránh phình ổ đĩa.

## Nơi lưu tài liệu

Mọi artifact agent sinh ra nằm trong `devflow/` ở gốc project:

```
devflow/
├── CONTEXT.md                       bản đồ kiến trúc, từ điển nghiệp vụ
├── specs/YYYY-MM-DD-<tên>-spec.md
├── plans/YYYY-MM-DD-<tên>-plan.md
├── handoffs/YYYY-MM-DD-<tên>.md     checkpoint bàn giao phiên
└── adr/NNNN-<quyết-định>.md         quyết định kiến trúc khó đảo ngược
```

Không tạo `plans/` hay `specs/` rời rạc ở gốc project.

## Nguyên tắc luôn áp dụng

Bốn điều dưới đây áp dụng cho **mọi** việc, không cần gọi skill nào:

**1. Bằng chứng trước khẳng định.** Không nói "xong", "đã sửa", "test pass" nếu chưa chạy
lệnh và đọc output thật. Dán output ra. Test fail thì nói rõ là fail.

**2. Truy nguyên nhân gốc.** Gặp lỗi thì tìm nguyên nhân trước khi sửa. Vá triệu chứng để
hết báo lỗi là tạo nợ, không phải sửa lỗi.

**3. Test đỏ trước khi viết code — với project có test.** Laravel và Node có `tests/` hoặc
script test thì viết test fail trước. Theme WordPress không có unit test: bỏ qua quy tắc này,
kiểm chứng bằng render thật.

**4. Không tự mở rộng phạm vi.** Làm đúng việc được yêu cầu. Thấy vấn đề khác thì nêu ra
bằng một câu, đừng tự sửa.

## Stack của dự án

| Stack | Có test | Áp dụng TDD |
|---|---|---|
| Laravel | có `tests/` | có |
| Node/JS | có script test | có |
| WordPress theme | không | không — kiểm chứng bằng render & Playwright |
| WordPress plugin | có, nếu có `tests/` hoặc PHPUnit | có |
| Flutter | có | có |

## Danh mục skill (15 skill)

**Chuỗi phát triển:** `clarify-requirements` `write-plan` `isolate-worktree` `subagent-execution`
`test-first` `ui-design` `review-changes` `verify-done`

**Sửa bug & Bàn giao:** `diagnose-bug` `handoff`

**Hiểu codebase:** `analyze` `serena`

**WordPress:** `wp-theme-converter` `wp-security-audit` `wp-responsive-check`
