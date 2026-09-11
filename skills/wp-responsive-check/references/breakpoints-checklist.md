# Checklist Toàn Diện Kiểm Tra Responsive Design Cho WordPress Theme

Bộ quy tắc 13 hạng mục kiểm tra tính thích ứng (responsive) trên mọi thiết bị, dùng làm tiêu chuẩn đánh giá tự động bằng Playwright MCP hoặc review thủ công.

---

## 1. Các Mốc Breakpoint Tiêu Chuẩn

| Nhóm thiết bị | Chiều rộng Viewport (Width) | Chiều cao kiểm thử (Height) | Thiết bị đại diện |
| :--- | :--- | :--- | :--- |
| **Mobile nhỏ** | `320px` – `374px` | `667px` | iPhone SE, Galaxy A series đời cũ |
| **Mobile chuẩn** | `375px` – `428px` | `812px` | iPhone 12/13/14/15/16, Pixel, Galaxy S |
| **Tablet dọc** | `768px` – `834px` | `1024px` | iPad Mini, iPad 10.2", Galaxy Tab |
| **Tablet ngang / Laptop nhỏ** | `1024px` – `1280px` | `800px` | iPad Pro ngang, Macbook Air 13" |
| **Desktop tiêu chuẩn** | `1440px` – `1920px` | `900px` | Màn hình Full HD, iMac, Laptop 15.6" |
| **Desktop siêu rộng** | `≥ 2560px` | `1440px` | Màn hình 2K, 4K Ultrawide |

**Quy tắc kiểm thử:**
- Không được có hiện tượng "gãy layout": chữ chồng lên ảnh, thanh cuộn ngang xuất hiện toàn trang, menu che lấp nút bấm.
- Kiểm tra cả 2 chiều: co nhỏ dần (scale down) và mở rộng dần (scale up).
- Kiểm tra cả xoay ngang (Landscape) trên thiết bị di động.

---

## 2. Layout & Bố Cục Không Gian

- [ ] **Tuyệt đối không có thanh cuộn ngang (horizontal scrollbar)** ở bất kỳ breakpoint nào (`body { overflow-x: hidden; }` không phải giải pháp thay thế cho việc sửa lỗi tràn phần tử con).
- [ ] Grid / Flexbox chuyển đổi cột nhịp nhàng: 4 cột (Desktop) ➔ 2 cột (Tablet) ➔ 1 cột (Mobile).
- [ ] Khoảng cách lề (`padding`, `margin`) co giãn hợp lý (khuyến nghị dùng `clamp(1rem, 3vw, 3rem)`).
- [ ] Các khối nội dung không bị đè chồng lên nhau khi thu nhỏ màn hình.
- [ ] Container chính có `max-width` giới hạn (VD: 1200px - 1400px), không bị kéo dãn bẹt hình trên màn 2K/4K.

---

## 3. Typography & Đọc Nội Dung

- [ ] Cỡ chữ body text tối thiểu **14px – 16px** trên mobile để đảm bảo khả năng đọc không cần zoom.
- [ ] Sử dụng đơn vị tương đối (`rem`, `em`) hoặc hàm `clamp()` cho các thẻ heading `h1`, `h2`, `h3`.
- [ ] Line-height thoáng đãng (1.4 – 1.6) tránh các dòng chữ dính sát nhau.
- [ ] Không bị vỡ từ bất thường (word-break xấu), không để rớt 1 chữ mồ côi đơn độc ở dòng cuối.
- [ ] Sử dụng `overflow-wrap: break-word;` hoặc `word-break: break-word;` cho các văn bản dài (URL, mã code).

---

## 4. Hình Ảnh & Đa Phương Tiện (Media)

- [ ] Toàn bộ thẻ `<img>` có CSS nền tảng: `max-width: 100%; height: auto; display: block;`.
- [ ] Video nhúng iframe (YouTube, Vimeo, Google Maps) được bọc trong container tỷ lệ (aspect-ratio 16/9) co giãn mượt mà, không bị tràn ra ngoài khung.
- [ ] Ảnh nền (`background-image`) dùng `background-size: cover; background-position: center;` để giữ vùng trọng tâm trên mọi tỷ lệ màn hình.
- [ ] Logo website trên mobile co giãn cân đối (chiều cao 38px – 46px), không lấn chiếm toàn bộ thanh điều hướng.

---

## 5. Vùng Chạm Cảm Ứng (Touch Targets)

- [ ] Mọi nút bấm, link icon, checkbox, radio có kích thước vùng chạm tối thiểu **44x44px** (theo chuẩn Apple Human Interface & Google Material Design).
- [ ] Khoảng cách giữa các nút cạnh nhau tối thiểu 8px để tránh bấm nhầm.
- [ ] Không phụ thuộc vào sự kiện `:hover`: Mọi menu xổ xuống hoặc tooltip phải mở được bằng thao tác chạm (Tap/Click).

---

## 6. Điều Hướng & Menu Mobile (Navigation)

- [ ] Menu chính tự động chuyển thành **Hamburger Menu** hoặc **Mobile Drawer** trên màn hình nhỏ (< 992px).
- [ ] Menu phân cấp nhiều tầng (Submenu) hoạt động dạng **Accordion** hoặc bấm mũi tên để mở rộng mượt mà.
- [ ] Nút đóng menu mobile (`.close-btn`) và lớp phủ mờ (`backdrop`) nhạy bén, dễ bấm tắt.
- [ ] Khóa cuộn trang nền (`overflow: hidden` trên `<body>`) khi Drawer Menu đang mở để tránh cuộn kép.

---

## 7. Biểu Mẫu & Form Nhập Liệu (Forms & Inputs)

- [ ] Các ô input, textarea tự động mở rộng 100% chiều ngang (Full-width) trên màn hình mobile.
- [ ] Định dạng input type đúng chuẩn HTML5 (`type="tel"`, `type="email"`, `type="number"`) để mở đúng bàn phím ảo chuyên dụng.
- [ ] Nút Submit to rõ, dễ bấm, canh giữa hoặc full-width trên mobile.
- [ ] Khung thông báo gửi form (Contact Form 7, WPForms) hiển thị gọn gàng, không bị tràn viền.

---

## 8. Bảng Biểu & Dữ Liệu (Tables & Datasheets)

- [ ] Toàn bộ bảng `<table>` dài phải được bọc trong thẻ `<div class="table-responsive">` có `overflow-x: auto;`.
- [ ] Tuyệt đối không để một bảng thông số kỹ thuật làm phát sinh thanh cuộn ngang cho cả trang web.

---

## 9. Hiệu Năng & Trải Nghiệm Responsive (CLS)

- [ ] Không để xảy ra hiện tượng giật cục bố cục (Cumulative Layout Shift - CLS) khi ảnh tải xong. Đặt sẵn `width` và `height` hoặc thuộc tính `aspect-ratio` cho ảnh.
- [ ] Tích hợp `loading="lazy"` cho các ảnh và iframe nằm dưới nếp gấp màn hình (below the fold).

---

## 10. Các Thành Phần Đặc Thù Của WordPress Theme

### A. Cụm Nút Liên Hệ Nổi (Floating Contact Buttons)
- Nút Zalo, Hotline, Messenger nổi góc màn hình không được đè lên nút Gửi Form hoặc nút Mua Hàng/Đặt Lịch trên mobile.
- Không che lấp dòng bản quyền Copyright dưới chân trang.

### B. Thanh Điều Hướng Phân Cấp (Breadcrumbs)
- Hỗ trợ vuốt ngang cảm ứng (`white-space: nowrap; overflow-x: auto;`) hoặc tự động rút gọn bằng dấu `...` (`text-overflow: ellipsis`) trên mobile nhỏ.

### C. Lưới Thẻ Bài Viết / Sản Phẩm (Cards Grid)
- Chuyển đổi chuẩn: 3 hoặc 4 cột (Desktop ≥ 992px) ➔ 2 cột (Tablet 768px – 991px) ➔ 1 cột (Mobile < 768px).
- Tỷ lệ khung hình thumbnail giữ nguyên chuẩn (`aspect-ratio: 4/3` hoặc `16/9`), không bị méo hay co dãn ảnh.

---

## 11. Bảng Phân Loại Mức Độ Lỗi (Severity Rating)

| Mức độ | Ký hiệu | Định nghĩa | Hành động khắc phục |
| :--- | :--- | :--- | :--- |
| **Critical** | 🔴 | Tràn ngang toàn trang, gãy vỡ layout hoàn toàn, nút chính hoặc menu mobile không bấm được. | Bắt buộc sửa ngay lập tức trước khi tiếp tục. |
| **Major** | 🟠 | Chữ chồng lên ảnh, icon bị cắt nửa, bảng dữ liệu tràn viền, nút bấm quá bé (< 32px). | Cần khắc phục để đảm bảo trải nghiệm người dùng. |
| **Minor** | 🟡 | Khoảng cách margin/padding hơi chật hoặc quá rộng, chữ heading hơi to trên màn nhỏ. | Tinh chỉnh CSS hoàn thiện. |
| **Nitpick** | ⚪ | Có thể tối ưu thêm font chữ hoặc hiệu ứng chuyển động khi xoay màn hình. | Cải thiện nếu còn thời gian. |
