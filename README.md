# devflow

Bộ skill phát triển tinh gọn cho stack WordPress · Laravel · Node · Flutter.

**11 skill · always-on ~561 token** (so với `supercoders` 56 skill ≈ 3.345 token).

## Vì sao có repo này

`supercoders` gộp 53 skill từ hai upstream (`mattpocock/skills`, `obra/superpowers`) qua git
submodule. Bộ máy đồng bộ đó sinh 6 lỗi trong một tháng, trong đó `sync.py` xoá sạch các
skill WordPress tự viết mỗi lần chạy. Đo trên 19 transcript: **21 lần gõ lệnh quản lý plugin
so với 5 lần thực sự gọi skill**.

`devflow` viết mới toàn bộ phần quy trình, không submodule, không upstream, không CI đồng bộ.

## Cài đặt

```bash
git clone <repo> ~/devflow
claude plugin marketplace add ~/devflow
claude plugin install devflow@devflow
```

Chạy so sánh với `supercoders` thì tắt bên kia đi — hai bộ chồng chức năng:

```bash
claude plugin disable supercoders --scope project
```

## Chuỗi phát triển

```
clarify-requirements → write-plan → subagent-execution → review-changes → verify-done
                                            ↓
                                       test-first
```

| Skill | Làm gì |
| :--- | :--- |
| `clarify-requirements` | Phỏng vấn làm rõ yêu cầu, xuất spec vào `devflow/specs/` |
| `write-plan` | Chia task độc lập, mỗi task có tiêu chí kiểm chứng, xuất `devflow/plans/` |
| `subagent-execution` | Mỗi task một implementer + một reviewer độc lập, giữ context chính sạch |
| `test-first` | Test đỏ trước, code sau — chỉ cho project có test |
| `review-changes` | Hai reviewer song song: đúng quy ước repo, đúng spec |
| `verify-done` | Chạy lệnh thật, dán output thật, rồi mới được nói xong |
| `ui-design` | Cam kết hướng thẩm mỹ trước khi viết markup — tránh giao diện "mặc định AI" |

## Skill theo stack

| Skill | Làm gì |
| :--- | :--- |
| `analyze` | Index codebase bằng knowledge graph + LSP, sinh `CONTEXT.md` |
| `serena` | Điều hướng symbol bằng LSP, chẩn đoán, sửa code có chủ đích |
| `wp-theme-converter` | HTML template → WordPress theme (CPT, ACF, Polylang, demo seeder) |
| `wp-security-audit` | Audit bảo mật & chất lượng code theo WPCS / Plugin Check |
| `wp-responsive-check` | Audit responsive 320–1440px bằng Playwright MCP |

## Cách dùng

Skill **tự kích hoạt** khi bạn mô tả nhu cầu, không cần gõ lệnh:

> *"Tôi muốn thêm cổng thanh toán VNPay vào module đơn hàng"* → `clarify-requirements`
>
> *"Kiểm tra bảo mật plugin này"* → `wp-security-audit`
>
> *"Quét kiến trúc dự án này giúp tôi"* → `analyze`

Gọi thẳng thì gõ `/devflow:<tên-skill>`.

## Nguyên tắc không nằm trong skill

Bốn nguyên tắc cắt ngang nằm trong [`CLAUDE.md`](./CLAUDE.md) chứ không phải skill, vì chúng
áp dụng cho **mọi** việc chứ không phải một loại việc — và `CLAUDE.md` luôn được nạp, còn
skill phải được gọi mới có tác dụng:

bằng chứng trước khẳng định · truy nguyên nhân gốc · test đỏ trước khi code (project có test) ·
không tự mở rộng phạm vi

Đây là lý do bộ này chỉ có 11 skill: phần lớn "skill" của upstream thực ra là nguyên tắc.
Khoảng 2.100 dòng của họ gói lại thành ~15 dòng `CLAUDE.md`, và hiệu lực mạnh hơn.

## Yêu cầu MCP

| Skill | Cần |
| :--- | :--- |
| `analyze` | `codebase-memory-mcp` + `serena` |
| `serena` | `serena` |
| `wp-responsive-check` | Playwright MCP |

Plugin không tự cấu hình MCP — khai báo trong `~/.claude.json` hoặc `.mcp.json` của project.

## Ghi công

Phần quy trình (6 skill + `CLAUDE.md`) viết mới, không dùng lại mã nguồn của upstream nào.
Các khái niệm nền — TDD, subagent-driven development, evidence before assertions, grilling —
lấy cảm hứng từ [`obra/superpowers`](https://github.com/obra/superpowers) (Jesse Vincent) và
[`mattpocock/skills`](https://github.com/mattpocock/skills) (Matt Pocock), cả hai đều MIT.

`wp-security-audit` dựa trên bộ rule của lucas (DevVN).
