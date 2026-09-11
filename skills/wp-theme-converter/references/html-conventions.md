# Quy Chuẩn & Phân Tích HTML Template Đầu Vào (HTML Conventions)

Tài liệu này định nghĩa cách Agent phân tích cấu trúc thư mục, CSS/JS frameworks và tài nguyên từ bất kỳ bộ HTML template nào trước khi chuyển đổi sang WordPress Theme.

---

## 1. Cấu Trúc Thư Mục Tổng Quát Của Mọi HTML Template

```text
html-template-root/
├── css/                     # CSS tùy chỉnh và framework
│   └── style.css            # (hoặc main.css, theme.css)
├── js/                      # JavaScript tùy chỉnh
│   └── main.js              # (hoặc app.js, script.js)
├── images/                  # Toàn bộ hình ảnh, logo, icon tĩnh (hoặc img/, assets/images/)
├── libs/                    # Các thư viện bên thứ 3 (hoặc vendors/, assets/vendor/)
│   ├── bootstrap/           # Bootstrap 4 hoặc 5
│   ├── tailwind/            # Hoặc Tailwind CSS build output
│   ├── fontawesome/         # Hoặc Boxicons, RemixIcon, Bootstrap Icons
│   ├── swiper/              # Hoặc OwlCarousel, Slick Slider
│   └── ...
├── index.html               # Trang chủ
├── {page}.html              # Các trang tĩnh (about.html, contact.html, faq.html...)
├── {entity}s.html           # Trang danh sách (projects.html, courses.html, products.html, services.html...)
├── {entity}-detail.html     # Trang chi tiết (project-detail.html, course-detail.html, product-detail.html...)
├── blogs.html               # Trang tin tức / bài viết
├── blog-detail.html         # Trang chi tiết tin tức
└── 404.html                 # Trang báo lỗi 404 (nếu có)
```

---

## 2. Quy Tắc Phân Tích Framework & Thư Viện

Agent cần phát hiện loại thư viện mà HTML template đang sử dụng để đăng ký chính xác trong `functions.php`:

1. **CSS Frameworks**:
   - Nếu dùng Bootstrap: Đăng ký `libs/bootstrap/css/bootstrap.min.css`.
   - Nếu dùng Tailwind: Đăng ký file CSS đã build (VD: `css/tailwind.css`).
   - Nếu dùng UIkit / Bulma / Custom Grid: Đăng ký file tương ứng trong `libs/`.
2. **Icon Sets**:
   - Nhận diện FontAwesome (`fa fa-*`, `fas fa-*`), Boxicons (`bx bx-*`), Bootstrap Icons (`bi bi-*`).
3. **Sliders & Carousels**:
   - Nhận diện Swiper (`swiper-container`, `swiper-slide`), Slick (`slick-slider`), hoặc OwlCarousel (`owl-carousel`). Đảm bảo enqueue cả CSS và JS tương ứng.
4. **Typography (Google Fonts)**:
   - Đọc các thẻ `<link rel="stylesheet">` trong `<head>` của `index.html`.
   - Trích xuất toàn bộ font chữ đang nhúng (như Be Vietnam Pro, Montserrat, Roboto, Inter, Playfair Display...) để đăng ký qua `wp_enqueue_style()` trong `functions.php`.

---

## 3. Tiêu Chuẩn Giữ Nguyên Bản (Fidelity Preservation)

1. **Giữ nguyên 100% markup HTML gốc**:
   - Không tự ý xóa class CSS, không thay đổi cấu trúc thẻ HTML (div, section, article).
   - Chỉ thay đổi các thuộc tính `src="..."` và `href="..."` để tích hợp động với WordPress.
2. **Xử lý đường dẫn tương đối trong CSS**:
   - Nếu file `css/style.css` có chứa đường dẫn ảnh nền (background-image: `url('../images/bg.jpg')`), khi chuyển vào thư mục theme WordPress, cấu trúc thư mục tương đối `css/` và `images/` vẫn được giữ nguyên nên CSS background sẽ tiếp tục hoạt động mà không bị lỗi đường dẫn.
