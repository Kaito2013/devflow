# devflow — hướng dẫn cho agent

## Chuỗi phát triển

```
clarify-requirements → write-plan → subagent-execution → review-changes → verify-done
                                            ↓
                                       test-first
```

Mỗi mắt xích là một skill. Skill trước bàn giao cho skill sau; không nhảy cóc.

**Quy tắc bắt buộc:** khi kế hoạch đã viết xong và môi trường có subagent, **phải** dùng
`subagent-execution`. Không thực thi tuần tự trong session chính — làm vậy làm bẩn context
và bỏ qua vòng review độc lập.

## Nơi lưu tài liệu

Mọi artifact agent sinh ra nằm trong `devflow/` ở gốc project:

```
devflow/
├── CONTEXT.md                       bản đồ kiến trúc, từ điển nghiệp vụ
├── specs/YYYY-MM-DD-<tên>-spec.md
├── plans/YYYY-MM-DD-<tên>-plan.md
└── adr/NNNN-<quyết-định>.md
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
| WordPress theme/plugin | không | không — kiểm chứng bằng render |
| Flutter | có | có |

## Danh mục skill

**Chuỗi phát triển:** `clarify-requirements` `write-plan` `subagent-execution`
`test-first` `review-changes` `verify-done`

**Chất lượng giao diện:** `ui-design` — bắt buộc trước khi viết markup cho bất kỳ trang/
component nào người dùng thật nhìn thấy. Không có bước này, kết quả mặc định là component
thư viện xếp chồng, không màu, không phân cấp.

**Hiểu codebase:** `analyze` `serena`

**WordPress:** `wp-theme-converter` `wp-security-audit` `wp-responsive-check`
