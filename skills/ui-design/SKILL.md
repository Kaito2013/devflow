---
name: ui-design
description: Commit to one concrete aesthetic direction ("thiết kế giao diện") before writing any interface — avoid "default AI" UI (stacked gray forms, purple-white gradients, system fonts). Use when a task creates or edits a page, component, or dashboard a real user sees — Blade, Livewire, React, Vue, or plain HTML/CSS.
---

# Thiết kế giao diện

Chất lượng UI không tự nhiên mà có — nó là hệ quả của một **quyết định thẩm mỹ được đưa ra
trước khi gõ dòng code đầu tiên**. Bỏ qua bước này, kết quả luôn là cùng một thứ: xếp chồng
input mặc định của thư viện, không màu, không phân cấp, không ai nhớ nổi trông nó thế nào.

## Bước 1 — Chọn hướng, nói ra trước khi code

Trước khi viết bất kỳ markup nào, chọn **một** hướng rõ ràng và giữ nhất quán suốt cả trang:

- **Tông**: tối giản khắc kỷ / rực rỡ tối đa / editorial / luxury / công nghiệp thô mộc /
  ấm áp bo tròn... — chọn một cực, đừng lưng chừng.
- **Điểm khác biệt**: người dùng sẽ nhớ gì về màn hình này sau khi rời đi?
- **Ràng buộc**: framework/thư viện UI đã có sẵn trong dự án (Flux, shadcn, Bootstrap...),
  yêu cầu accessibility, hiệu năng.

Nói ra hướng đã chọn thành một câu trước khi bắt tay viết — kể cả khi làm một mình, việc
phát biểu ra buộc phải quyết định thật, không lưng chừng ở giữa nhiều hướng.

## Bước 2 — Bốn thứ luôn phải có quyết định, không được mặc định

Bốn khoảng devflow từng bỏ trống hoàn toàn trong dự án Laravel/Livewire thực tế — mỗi cái
cần một câu trả lời rõ ràng, không phải giá trị mặc định của thư viện:

| Khoảng | Mặc định (tránh) | Có chủ đích |
|---|---|---|
| **Chữ** | Font hệ thống (Arial/Inter/Roboto trần) | Một cặp font có cá tính, phân cấp rõ (kích cỡ, độ đậm, tracking) giữa tiêu đề và nội dung |
| **Màu** | Xám đơn sắc, hoặc gradient tím-trắng mặc định | Một thang màu nhất quán — màu nền, màu nhấn theo ngữ nghĩa (thành công/cảnh báo/thông tin), và **chế độ tối** nếu dự án dùng Tailwind (`dark:` có sẵn miễn phí, bỏ qua là lãng phí) |
| **Bố cục** | Cột dọc xếp chồng đơn điệu | Lưới, khoảng trắng có nhịp điệu, nhóm nội dung liên quan lại gần nhau bằng khoảng cách khác nhóm không liên quan |
| **Chi tiết** | Không icon, không trạng thái hover, không chuyển động | Icon mang ngữ nghĩa (không trang trí suông), trạng thái hover/focus rõ ràng, một chuyển động nhỏ tinh tế nếu hợp ngữ cảnh (không lạm dụng) |

Bốn cột "mặc định" bên trái chính là thứ mọi thư viện UI (Flux, Bootstrap, MUI) tự vẽ ra khi
không ai can thiệp — dùng nguyên trạng nghĩa là chưa thiết kế gì cả.

## Bước 3 — Không phải mọi màn hình đều cần mức đầu tư như nhau

Áp dụng đủ Bước 1–2 cho: dashboard, trang danh sách chính, landing page, bất kỳ màn hình
nào người dùng nhìn thấy thường xuyên.

Với form nội bộ dùng một lần, trang cấu hình ít người thấy: vẫn cần nhất quán với hướng
thẩm mỹ chung của dự án (dùng lại màu/font/spacing đã chọn), nhưng không cần sáng tạo bố
cục riêng — dùng lại pattern đã có.

## Bước 4 — Bàn giao

Sinh code thật, chạy được, không phải mô tả hay mockup. Đưa cho `devflow:verify-done` để
xác nhận render đúng — bằng ảnh chụp màn hình thật nếu có Playwright MCP, không chỉ đọc
markup bằng mắt.

## Quy tắc

- **Không** dùng font hệ thống trần (Arial/Inter/Roboto) làm lựa chọn duy nhất — nếu dự án
  đã có sẵn hệ font riêng (theme, design system công ty) thì dùng đúng cái đó, đừng đổi.
- **Không** dùng gradient tím-trắng làm màu nền mặc định — đây là dấu hiệu rõ nhất của
  "chưa ai nghĩ về màu sắc".
- **Không** để hai màn hình trong cùng một dự án trông như hai sản phẩm khác nhau — hướng
  thẩm mỹ chọn ở Bước 1 áp dụng cho toàn bộ dự án, chọn lại từ đầu cho mỗi trang là sai.
- Độ phức tạp của code phải khớp độ phức tạp của hướng đã chọn: hướng tối giản cần từng
  khoảng cách chính xác chứ không phải ít code hơn; hướng rực rỡ cần nhiều chi tiết hơn
  chứ không phải cẩu thả hơn.
