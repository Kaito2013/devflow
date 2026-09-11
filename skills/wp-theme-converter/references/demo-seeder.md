# Hệ Thống Tự Động Hóa Dữ Liệu Demo (Universal Seeder Engine) & Kiểm Thử QA

Tài liệu này hướng dẫn cách xây dựng bộ Seeder tự thích ứng (`core/demo-data.php`) cho bất kỳ loại website nào bằng cách **trích xuất trực tiếp nội dung và hình ảnh từ chính HTML template**, cùng quy trình kiểm thử QA tiêu chuẩn cao.

---

## 1. Nguyên Tắc Trích Xuất Dữ Liệu Thực (No Dummy Content)

> ⚠️ **Quy tắc vàng**: Dữ liệu demo **BẮT BUỘC** phải được trích xuất từ chính các file HTML gốc của template dự án đó. Không tự ý bịa nội dung giả vô nghĩa (không dùng Lorem Ipsum khi template đã có sẵn chữ).

1. **Thông tin liên hệ & Theme Options**:
   - Đọc thẻ Header và Footer trong `index.html`: Trích xuất số điện thoại, email, địa chỉ thực tế có trong HTML.
2. **Danh sách Trang Tĩnh (Pages)**:
   - Quét các file `*.html` đơn (như `about.html`, `contact.html`, `services.html`, `faq.html`...): Tự động tạo trang WordPress tương ứng và gán template `page-{name}.php`.
3. **Cấu trúc Menu Chính**:
   - Đọc khối thẻ `<nav>` trong `header.php`: Lấy chính xác danh sách nhãn menu (Label) và đường dẫn tương ứng để tạo WordPress Navigation Menu.
4. **Bài Viết & Thực Thể Mẫu (CPT Items)**:
   - Đọc các card có sẵn trong file danh sách (`projects.html`, `courses.html`, `products.html`...):
   - Lấy tiêu đề, đoạn mô tả ngắn, và tên file ảnh trong `images/` được nhúng trên card đó.

---

## 2. Mã Nguồn Mẫu Đa Năng: `core/demo-data.php`

Tệp này cung cấp các hàm helper tổng quát để tự động gieo dữ liệu (seeding) cho bất kỳ CPT hay Taxonomy nào:

```php
<?php
/**
 * Universal Demo Data Seeder cho Theme WordPress
 */
if (!defined('ABSPATH')) exit;

/**
 * Helper 1: Upload ảnh từ thư mục theme images/ vào WordPress Media Library
 * @param string $filename Tên file ảnh (VD: 'hero-banner.jpg')
 * @return int Attachment ID (0 nếu thất bại)
 */
function theme_import_image($filename) {
    if (empty($filename)) return 0;

    $theme_image_path = get_template_directory() . '/images/' . $filename;
    if (!file_exists($theme_image_path)) {
        return 0;
    }

    // Tránh upload trùng lặp nếu đã import trước đó
    $existing = get_posts(array(
        'post_type'      => 'attachment',
        'meta_key'       => '_demo_source_file',
        'meta_value'     => $filename,
        'posts_per_page' => 1,
        'post_status'    => 'inherit',
    ));
    if (!empty($existing)) {
        return $existing[0]->ID;
    }

    require_once ABSPATH . 'wp-admin/includes/file.php';
    require_once ABSPATH . 'wp-admin/includes/media.php';
    require_once ABSPATH . 'wp-admin/includes/image.php';

    $upload_dir = wp_upload_dir();
    $dest_path  = $upload_dir['path'] . '/' . sanitize_file_name($filename);
    copy($theme_image_path, $dest_path);

    $filetype   = wp_check_filetype($filename, null);
    $attachment = array(
        'guid'           => $upload_dir['url'] . '/' . basename($dest_path),
        'post_mime_type' => $filetype['type'],
        'post_title'     => preg_replace('/\.[^.]+$/', '', basename($filename)),
        'post_content'   => '',
        'post_status'    => 'inherit',
    );

    $attach_id = wp_insert_attachment($attachment, $dest_path);
    if (!is_wp_error($attach_id)) {
        $attach_data = wp_generate_attachment_metadata($attach_id, $dest_path);
        wp_update_attachment_metadata($attach_id, $attach_data);
        update_post_meta($attach_id, '_demo_source_file', $filename);
        return $attach_id;
    }

    return 0;
}

/**
 * Helper 2: Tạo một bài viết / mục CPT mẫu kèm Thumbnail và ACF Fields
 */
function theme_create_demo_item($post_type, $title, $excerpt, $image_file, $tax_terms = array(), $acf_fields = array()) {
    // Kiểm tra xem đã tồn tại chưa
    $existing = get_page_by_title($title, OBJECT, $post_type);
    if ($existing) {
        $post_id = $existing->ID;
    } else {
        $post_id = wp_insert_post(array(
            'post_title'   => $title,
            'post_excerpt' => $excerpt,
            'post_status'  => 'publish',
            'post_type'    => $post_type,
        ));
    }

    if (!$post_id || is_wp_error($post_id)) return 0;

    // Gán Ảnh đại diện (Featured Image)
    if (!empty($image_file)) {
        $attach_id = theme_import_image($image_file);
        if ($attach_id) {
            set_post_thumbnail($post_id, $attach_id);
        }
    }

    // Gán Taxonomies
    if (!empty($tax_terms) && is_array($tax_terms)) {
        foreach ($tax_terms as $taxonomy => $terms) {
            wp_set_object_terms($post_id, (array)$terms, $taxonomy);
        }
    }

    // Điền các trường ACF (nếu plugin ACF Pro đang hoạt động)
    if (function_exists('update_field') && !empty($acf_fields) && is_array($acf_fields)) {
        foreach ($acf_fields as $field_key => $field_value) {
            update_field($field_key, $field_value, $post_id);
        }
    }

    return $post_id;
}

/**
 * Helper 3: Tạo Trang Tĩnh Chuẩn
 */
function theme_create_demo_page($title, $slug, $template_file = '') {
    $existing = get_page_by_path($slug);
    if ($existing) return $existing->ID;

    $page_id = wp_insert_post(array(
        'post_title'   => $title,
        'post_name'    => $slug,
        'post_status'  => 'publish',
        'post_type'    => 'page',
    ));

    if ($page_id && !empty($template_file) && $template_file !== 'page.php') {
        update_post_meta($page_id, '_wp_page_template', $template_file);
    }
    return $page_id;
}

/**
 * Điều phối Thực thi Import Toàn Bộ Dữ Liệu
 */
function theme_execute_universal_import() {
    // 1. Cấu hình Theme Options từ HTML Header/Footer thật
    if (function_exists('update_field')) {
        // Thay các giá trị bên dưới bằng thông tin trích xuất từ HTML
        update_field('hotline', '{extracted_hotline}', 'option');
        update_field('email', '{extracted_email}', 'option');
        update_field('company_address', '{extracted_address}', 'option');

        $logo_id = theme_import_image('logo.png');
        if ($logo_id) {
            update_field('header_logo', $logo_id, 'option');
        }
    }

    // 2. Tự động tạo các Trang tĩnh được phát hiện từ template
    $pages_config = array(
        'Trang chủ'  => array('slug' => 'home', 'tpl' => 'index.php'),
        'Giới thiệu' => array('slug' => 'about', 'tpl' => 'page-about.php'),
        'Liên hệ'    => array('slug' => 'contact', 'tpl' => 'page-contact.php'),
        'Tin tức'    => array('slug' => 'blogs', 'tpl' => 'page.php'),
        // Thêm các trang khác tìm thấy trong template (services, projects, menu...)
    );

    $created_pages = array();
    foreach ($pages_config as $title => $conf) {
        $created_pages[$conf['slug']] = theme_create_demo_page($title, $conf['slug'], $conf['tpl']);
    }

    // Gán Trang chủ tĩnh
    if (!empty($created_pages['home'])) {
        update_option('show_on_front', 'page');
        update_option('page_on_front', $created_pages['home']);
    }
    if (!empty($created_pages['blogs'])) {
        update_option('page_for_posts', $created_pages['blogs']);
    }

    // 3. Tự động tạo Menu Điều Hướng và gán vị trí 'primary'
    $menu_name   = 'Menu Chính';
    $menu_exists = wp_get_nav_menu_object($menu_name);
    if (!$menu_exists) {
        $menu_id = wp_create_nav_menu($menu_name);
        wp_update_nav_menu_item($menu_id, 0, array(
            'menu-item-title'   => 'Trang chủ',
            'menu-item-url'     => home_url('/'),
            'menu-item-status'  => 'publish',
        ));
        foreach ($created_pages as $slug => $pid) {
            if ($slug === 'home') continue;
            wp_update_nav_menu_item($menu_id, 0, array(
                'menu-item-title'     => get_the_title($pid),
                'menu-item-object'    => 'page',
                'menu-item-object-id' => $pid,
                'menu-item-type'      => 'post_type',
                'menu-item-status'    => 'publish',
            ));
        }
        $locations = get_theme_mod('nav_menu_locations');
        $locations['primary'] = $menu_id;
        set_theme_mod('nav_menu_locations', $locations);
    }

    // 4. Khởi tạo các bài viết mẫu CPT từ card HTML thực tế
    // Ví dụ mẫu:
    // theme_create_demo_item('{cpt_slug}', 'Tên mục mẫu 1', 'Mô tả ngắn...', 'anh-mau-1.jpg', array('{tax_slug}' => 'Danh mục A'), array('item_price' => 1000000));
}

// Đăng ký trang quản trị 1-Click Import tại: Tools ➔ Import Demo Theme
add_action('admin_menu', function() {
    add_management_page('Import Demo Data', 'Import Demo Theme', 'manage_options', 'theme-import-demo', function() {
        if (isset($_POST['theme_run_import']) && check_admin_referer('theme_import_action', 'theme_import_nonce')) {
            theme_execute_universal_import();
            echo '<div class="updated"><p><b>Đã hoàn tất Import toàn bộ Demo Data và Media chuẩn từ HTML Template!</b></p></div>';
        }
        ?>
        <div class="wrap">
            <h1>Cài Đặt Dữ Liệu Mẫu Cho Theme</h1>
            <p>Hệ thống sẽ tự động tạo bài viết mẫu, upload ảnh vào Thư viện Media và thiết lập Menu chuẩn xác.</p>
            <form method="post">
                <?php wp_nonce_field('theme_import_action', 'theme_import_nonce'); ?>
                <input type="submit" name="theme_run_import" class="button button-primary button-hero" value="🚀 Bắt đầu Import Demo Data">
            </form>
        </div>
        <?php
    });
});
```

---

## 3. Quy Trình Kiểm Thử QA 4 Bước Toàn Diện

Trước khi hoàn tất dự án, Agent bắt buộc chạy quy trình kiểm thử 4 bước:

### Bước 1: Syntax Linter Check (PHP CLI)
Kiểm tra cú pháp 100% file PHP không có lỗi syntax:
```bash
php -l functions.php
php -l header.php
php -l footer.php
php -l index.php
for f in core/*.php template-parts/*.php; do php -l "$f"; done
```

### Bước 2: Kiểm Tra Tuyệt Đối Không Sót Đường Dẫn Tĩnh
```bash
# Kiểm tra còn sót ảnh tĩnh chưa qua hàm get_template_directory_uri()
grep -rn 'src="images/' *.php template-parts/

# Kiểm tra còn sót link tĩnh .html
grep -rn 'href=".*\.html"' *.php template-parts/
```
*Kết quả bắt buộc: Hoàn toàn không tìm thấy dòng nào.*

### Bước 3: Kiểm Tra WordPress Debug Log (`debug.log`)
Quét file `wp-content/debug.log`:
- Đảm bảo **không có bất kỳ PHP Warning, Notice, hoặc Deprecated** nào được ghi nhận khi tải Trang chủ, Trang danh sách và Trang chi tiết.

### Bước 4: So Sánh Đối Chiếu UI Trực Quan
- Kiểm tra các font chữ, khoảng cách các section, độ responsive của thanh menu trên thiết bị di động xem có khớp 100% với file HTML template ban đầu không.
