# Hướng Dẫn Tự Động Nhận Diện CPT, Taxonomies & Template Hierarchy Đa Ngành

Tài liệu này cung cấp **thuật toán nhận diện tự động (Universal Heuristic Detection Engine)** để phân tích bất kỳ bộ HTML template nào sang Custom Post Types (CPT), Custom Taxonomies, và cấu trúc template WordPress chuẩn — áp dụng linh hoạt cho mọi lĩnh vực (Bất động sản, Nha khoa, Khóa học, Nhà hàng, Bán hàng, Dịch vụ doanh nghiệp, Khách sạn, v.v.).

---

## 1. Thuật Toán Nhận Diện Thực Thể (Entity Detection Algorithm)

```
[HTML Template Folder]
      │
      ├── 1. Quét file *-detail.html / *-single.html
      │     └── (Trừ blog/news/tin-tuc) ➔ 1 CPT tương ứng
      │
      ├── 2. Đọc file danh sách (list page) tương ứng
      │     ├── Phân tích các bộ lọc UI (tabs, dropdown, sidebar) ➔ Custom Taxonomies
      │     └── Tìm các phần tử card/item lặp lại ➔ template-parts/card-{cpt}.php
      │
      └── 3. Phân loại các trang còn lại
            ├── index.html ➔ index.php (Trang chủ)
            ├── {page}.html tĩnh (about, contact...) ➔ page-{page}.php
            ├── blog-detail.html / news-detail.html ➔ single.php
            └── blogs.html / news.html ➔ category.php / archive.php
```

---

## 2. Bảng Ánh Xạ Đa Lĩnh Vực Mẫu (Multi-Domain Mapping Matrix)

Agent sử dụng bảng này làm kim chỉ nam để tự động suy luận slug tiếng Anh và nhãn (label) tiếng Việt phù hợp với ngữ cảnh của template:

| Lĩnh vực | File Detail HTML | File List HTML | CPT Slug & Tên hiển thị | Custom Taxonomy gợi ý | Template Parts |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Bất động sản (Real Estate)** | `project-detail.html`<br/>`property-detail.html` | `projects.html`<br/>`properties.html` | • `project` (Dự án)<br/>• `property` (Bất động sản) | • `loai_bds` (Căn hộ, Đất nền, Biệt thự)<br/>• `khu_vuc` (Quận/Huyện, Tỉnh/Thành)<br/>• `trang_thai_bds` (Đang mở bán, Đã bàn giao) | `template-parts/card-project.php`<br/>`template-parts/card-property.php` |
| **Y tế & Nha khoa (Healthcare)** | `doctor-detail.html`<br/>`service-detail.html` | `doctors.html`<br/>`services.html` | • `doctor` (Bác sĩ)<br/>• `medical_service` (Dịch vụ y tế) | • `chuyen_khoa` (Nội trú, Răng sứ, Chỉnh nha)<br/>• `chi_nhanh` (Cơ sở 1, Cơ sở 2) | `template-parts/card-doctor.php`<br/>`template-parts/card-service.php` |
| **Giáo dục & Khóa học (Education)** | `course-detail.html`<br/>`instructor-detail.html` | `courses.html`<br/>`instructors.html` | • `course` (Khóa học)<br/>• `instructor` (Giảng viên) | • `chu_de_khoa_hoc` (Lập trình, Marketing, Ngoại ngữ)<br/>• `trinh_do` (Cơ bản, Nâng cao) | `template-parts/card-course.php`<br/>`template-parts/card-instructor.php` |
| **Nhà hàng & Ẩm thực (F&B)** | `dish-detail.html`<br/>`menu-detail.html` | `menu.html`<br/>`dishes.html` | • `dish` (Món ăn / Đồ uống) | • `danh_muc_mon` (Khai vị, Món chính, Tráng miệng)<br/>• `bua_an` (Sáng, Trưa, Tối, Tiệc) | `template-parts/card-dish.php` |
| **Ô tô & Thuê xe (Automotive)** | `car-detail.html`<br/>`vehicle-detail.html` | `cars.html`<br/>`rentals.html` | • `car` (Xe ô tô / Phương tiện) | • `hang_xe` (Toyota, Honda, Mercedes)<br/>• `phan_khuc` (Sedan, SUV, Bán tải)<br/>• `loai_nhien_lieu` (Xăng, Dầu, Điện) | `template-parts/card-car.php` |
| **Agency & Dịch vụ Doanh nghiệp** | `service-detail.html`<br/>`portfolio-detail.html` | `services.html`<br/>`portfolio.html` | • `service` (Dịch vụ)<br/>• `portfolio` (Dự án đã thực hiện) | • `nhom_dich_vu` (Thiết kế Web, SEO, Branding)<br/>• `linh_vuc_khach_hang` (B2B, B2C, Fintech) | `template-parts/card-service.php`<br/>`template-parts/card-portfolio.php` |
| **Khách sạn & Nghỉ dưỡng (Hospitality)** | `room-detail.html` | `rooms.html`<br/>`accommodations.html` | • `room` (Hạng phòng) | • `loai_phong` (Deluxe, Suite, Standard)<br/>• `suc_chua` (1-2 người, Gia đình) | `template-parts/card-room.php` |
| **Thương mại & Sản phẩm (E-commerce)** | `product-detail.html` | `products.html`<br/>`shop.html` | • `product` (Sản phẩm) | • `danh_muc_sp` (Thời trang, Gia dụng, Điện tử)<br/>• `thuong_hieu` (Nike, Apple...) | `template-parts/card-product.php` |

---

## 3. Cách Phân Tích Bộ Lọc UI Thành Taxonomy Động

Khi đọc trang danh sách (`*.html`), hãy chú ý các thành phần giao diện sau:
1. **Thanh Tabs / Pills**:
   - Ví dụ: `Tất cả | Dưới 2 tỷ | 2 - 5 tỷ | Trên 5 tỷ` ➔ Custom Taxonomy `muc_gia` hoặc ACF range filter.
   - Ví dụ: `Tất cả | Khóa học Online | Khóa học Offline` ➔ Custom Taxonomy `hinh_thuc_hoc`.
2. **Dropdown `<select>`**:
   - Ví dụ: `<select name="brand">` chứa các hãng ➔ Custom Taxonomy `thuong_hieu`.
3. **Sidebar Checkbox / Radio list**:
   - Ví dụ danh sách các tiện ích: `Wifi, Hồ bơi, Chỗ đỗ xe...` ➔ Custom Taxonomy `tien_ich` (dạng không phân cấp - Tags hoặc hierarchical).

---

## 4. Mã Nguồn Mẫu Đa Năng Cho `core/types.php`

Thay vì viết code thủ công lặp lại, sử dụng mảng cấu hình (Config Array) để định nghĩa mọi CPT & Taxonomy của dự án một cách chuyên nghiệp, sạch sẽ:

```php
<?php
/**
 * Đăng ký Custom Post Types và Taxonomies Đa Năng
 */
if (!defined('ABSPATH')) exit;

add_action('init', 'theme_register_dynamic_post_types_and_taxonomies');
function theme_register_dynamic_post_types_and_taxonomies() {

    // 1. CẤU HÌNH DANH SÁCH CUSTOM POST TYPES TÙY BIẾN THEO TEMPLATE
    $custom_post_types = array(
        // Ví dụ: Dự án Bất động sản / Dịch vụ / Khóa học / Xe cộ...
        '{cpt_slug}' => array(
            'name'          => '{Tên Số Nhiều}',      // VD: 'Dự án', 'Bác sĩ', 'Khóa học'
            'singular'      => '{Tên Số Ít}',        // VD: 'Dự án', 'Bác sĩ', 'Khóa học'
            'slug'          => '{url_slug}',         // VD: 'du-an', 'bac-si', 'khoa-hoc'
            'icon'          => 'dashicons-portfolio',// Dashicon phù hợp với ngành
            'supports'      => array('title', 'editor', 'thumbnail', 'excerpt', 'revisions'),
            'has_archive'   => true,
        ),
    );

    foreach ($custom_post_types as $post_type => $config) {
        $labels = array(
            'name'               => $config['name'],
            'singular_name'      => $config['singular'],
            'menu_name'          => 'Quản lý ' . $config['name'],
            'all_items'          => 'Tất cả ' . $config['name'],
            'add_new'            => 'Thêm ' . $config['singular'] . ' mới',
            'add_new_item'       => 'Thêm ' . $config['singular'] . ' mới',
            'edit_item'          => 'Sửa ' . $config['singular'],
            'search_items'       => 'Tìm kiếm ' . $config['name'],
            'not_found'          => 'Không tìm thấy ' . $config['name'],
        );

        register_post_type($post_type, array(
            'labels'             => $labels,
            'public'             => true,
            'has_archive'        => $config['has_archive'],
            'rewrite'            => array('slug' => $config['slug'], 'with_front' => false),
            'supports'           => $config['supports'],
            'menu_icon'          => $config['icon'],
            'show_in_rest'       => true, // Hỗ trợ Gutenberg & Block Editor
        ));
    }

    // 2. CẤU HÌNH DANH SÁCH CUSTOM TAXONOMIES TƯƠNG ỨNG
    $custom_taxonomies = array(
        '{tax_slug}' => array(
            'name'          => '{Tên Danh Mục}',     // VD: 'Loại bất động sản', 'Chuyên khoa'
            'post_types'    => array('{cpt_slug}'),  // Gắn với CPT nào
            'slug'          => '{url_slug}',         // VD: 'loai-bds', 'chuyen-khoa'
            'hierarchical'  => true,                 // true = Dạng danh mục cha/con
        ),
    );

    foreach ($custom_taxonomies as $taxonomy => $config) {
        $tax_labels = array(
            'name'              => $config['name'],
            'singular_name'     => $config['name'],
            'search_items'      => 'Tìm ' . $config['name'],
            'all_items'         => 'Tất cả ' . $config['name'],
            'parent_item'       => $config['name'] . ' cha',
            'parent_item_colon' => $config['name'] . ' cha:',
            'edit_item'         => 'Sửa ' . $config['name'],
            'add_new_item'      => 'Thêm ' . $config['name'] . ' mới',
        );

        register_taxonomy($taxonomy, $config['post_types'], array(
            'labels'            => $tax_labels,
            'hierarchical'      => $config['hierarchical'],
            'public'            => true,
            'show_ui'           => true,
            'show_admin_column' => true,
            'query_var'         => true,
            'rewrite'           => array('slug' => $config['slug'], 'with_front' => false),
            'show_in_rest'      => true,
        ));
    }
}

// Tự động flush rewrite rules khi kích hoạt theme
add_action('after_switch_theme', function() {
    theme_register_dynamic_post_types_and_taxonomies();
    flush_rewrite_rules();
});
```

---

## 5. Quy Tắc Tách Template Parts Thống Nhất

Mỗi component card hiển thị lặp lại trong danh sách hoặc trên trang chủ phải được bóc tách vào `template-parts/card-{entity}.php`:

```php
<?php
/**
 * Template Part: Card đại diện cho entity (Dự án, Khóa học, Sản phẩm, Bác sĩ...)
 */
$item_id = get_the_ID();
$terms   = get_the_terms($item_id, '{tax_slug}');
$primary_term = (!empty($terms) && !is_wp_error($terms)) ? $terms[0]->name : '';
?>
<div class="col-lg-4 col-md-6 mb-4">
    <div class="card-item-box">
        <div class="thumb-box">
            <a href="<?php the_permalink(); ?>">
                <?php if (has_post_thumbnail()): ?>
                    <?php the_post_thumbnail('medium_large', array('class' => 'img-fluid')); ?>
                <?php else: ?>
                    <img src="<?php echo esc_url(get_template_directory_uri()); ?>/images/placeholder.jpg" class="img-fluid" alt="<?php the_title_attribute(); ?>">
                <?php endif; ?>
            </a>
            <?php if ($primary_term): ?>
                <span class="badge-category"><?php echo esc_html($primary_term); ?></span>
            <?php endif; ?>
        </div>
        <div class="content-box">
            <h3 class="title"><a href="<?php the_permalink(); ?>"><?php the_title(); ?></a></h3>
            <div class="excerpt"><?php echo wp_trim_words(get_the_excerpt(), 15); ?></div>
            <!-- Dynamic ACF Meta Fields tại đây -->
        </div>
    </div>
</div>
```
