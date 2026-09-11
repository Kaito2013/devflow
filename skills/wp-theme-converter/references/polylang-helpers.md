# Polylang Multi-Language Integration & Fallback Helpers

Tài liệu hướng dẫn chuẩn hóa đa ngôn ngữ (Multi-language) cho WordPress Theme sử dụng **Polylang**. Đảm bảo theme có sẵn tầng **Fallback Functions Shim** (chống Fatal Error khi chưa kích hoạt Polylang), hệ thống **Tự động đăng ký chuỗi giao diện (String Registration)**, và chuẩn hóa **Late Escaping** trong toàn bộ template PHP.

---

## 1. Nguyên Tắc Cốt Lõi (Core Principles)

1. **Tuyệt đối không để xảy ra Fatal Error**:
   - Nếu gọi trực tiếp `pll__()`, `pll_e()`, `pll_register_string()` khi Polylang chưa được cài đặt hoặc bị Deactivate, WordPress sẽ lập tức sập với lỗi:
     `Fatal error: Uncaught Error: Call to undefined function pll__()`
   - **Bắt buộc**: Luôn cung cấp tầng Fallback Shim trong `core/polylang.php` để nếu không có Polylang, theme vẫn chạy mượt mà 100%.

2. **100% Text giao diện tĩnh phải được đăng ký**:
   - Mọi chuỗi text không lấy từ Database (Database gồm: tiêu đề post, nội dung, ACF fields) như: nút bấm *"Xem thêm"*, nhãn form *"Họ và tên"*, placeholder *"Nhập từ khóa..."*, tiêu đề *"Bài viết liên quan"*, thông báo 404 *"Trang không tồn tại"*... đều phải được khai báo qua `pll_register_string()` để người quản trị dịch được trong **WP Admin ➔ Languages ➔ String translations**.

3. **Luôn kết hợp Late Escaping chuẩn WPCS**:
   - Không xuất chuỗi dịch trần trụi. Luôn bọc trong các hàm thoát bảo mật:
     - `esc_html(pll__('Xem thêm'))` hoặc `pll_e('Xem thêm')`.
     - `esc_attr(pll__('Tìm kiếm...'))` cho attributes (`placeholder`, `title`, `aria-label`).
     - `wp_kses_post(pll__('Chuỗi có <strong>HTML</strong> an toàn'))`.

---

## 2. File Triển Khai Hoàn Chỉnh: `core/polylang.php`

Tạo file `core/polylang.php` trong thư mục theme và nạp vào `functions.php` qua `require_once get_template_directory() . '/core/polylang.php';`:

```php
<?php
/**
 * Polylang Integration & Fallback Helpers
 * 
 * Cung cấp Fallback functions chống Fatal Error và tự động đăng ký chuỗi text UI.
 * 
 * @package UniversalTheme
 */

if (!defined('ABSPATH')) {
    exit;
}

/* ==========================================================================
   1. POLYLANG FALLBACK SHIM LAYER (Chống Fatal Error khi tắt Polylang)
   ========================================================================== */

if (!function_exists('pll__')) {
    /**
     * Fallback cho pll__() - Lấy chuỗi đã dịch
     *
     * @param string $string Chuỗi cần dịch
     * @return string
     */
    function pll__($string) {
        // Fallback sang hàm Gettext mặc định của WordPress hoặc trả về chính nó
        return __($string, 'theme-textdomain');
    }
}

if (!function_exists('pll_e')) {
    /**
     * Fallback cho pll_e() - In chuỗi đã dịch
     *
     * @param string $string Chuỗi cần in
     * @return void
     */
    function pll_e($string) {
        echo esc_html(pll__($string));
    }
}

if (!function_exists('pll_register_string')) {
    /**
     * Fallback cho pll_register_string() - Đăng ký chuỗi
     *
     * @param string $name Tên định danh chuỗi
     * @param string $string Nội dung chuỗi
     * @param string $group Nhóm hiển thị trong admin
     * @param bool   $multiline Có phải dạng textarea nhiều dòng không
     * @return void
     */
    function pll_register_string($name, $string, $group = 'Theme', $multiline = false) {
        // Không làm gì nếu Polylang chưa active
        return;
    }
}

if (!function_exists('pll_current_language')) {
    /**
     * Fallback cho pll_current_language() - Lấy mã ngôn ngữ hiện tại
     *
     * @param string $value Kiểu giá trị trả về ('slug', 'name', 'locale')
     * @return string
     */
    function pll_current_language($value = 'slug') {
        $locale = function_exists('determine_locale') ? determine_locale() : get_locale();
        if ($value === 'slug') {
            return substr($locale, 0, 2); // 'vi', 'en'...
        }
        return $locale;
    }
}

if (!function_exists('pll_default_language')) {
    /**
     * Fallback cho pll_default_language() - Lấy ngôn ngữ mặc định
     *
     * @param string $value Kiểu giá trị trả về ('slug', 'name', 'locale')
     * @return string
     */
    function pll_default_language($value = 'slug') {
        return 'vi';
    }
}

if (!function_exists('pll_the_languages')) {
    /**
     * Fallback cho pll_the_languages() - Bộ chuyển đổi ngôn ngữ
     *
     * @param array $args Tham số hiển thị
     * @return string|array
     */
    function pll_the_languages($args = array()) {
        if (!empty($args['raw'])) {
            return array();
        }
        return '';
    }
}


/* ==========================================================================
   2. TỰ ĐỘNG ĐĂNG KÝ CHUỖI GIAO DIỆN (STRING REGISTRATION)
   ========================================================================== */

/**
 * Đăng ký tập trung toàn bộ chuỗi text UI tĩnh của theme vào Polylang
 */
function theme_register_polylang_strings() {
    // Chỉ đăng ký khi hàm tồn tại
    if (!function_exists('pll_register_string')) {
        return;
    }

    $strings = array(
        // Group: UI Buttons & CTA
        'Buttons' => array(
            'btn_read_more'     => 'Xem thêm',
            'btn_view_details'  => 'Xem chi tiết',
            'btn_contact_now'   => 'Liên hệ ngay',
            'btn_send_message'  => 'Gửi tin nhắn',
            'btn_submit'        => 'Gửi đi',
            'btn_register'      => 'Đăng ký ngay',
            'btn_download'      => 'Tải xuống',
            'btn_back_home'     => 'Về trang chủ',
            'btn_filter'        => 'Lọc kết quả',
            'btn_reset'         => 'Thiết lập lại',
        ),

        // Group: Header & Navigation
        'Header' => array(
            'nav_home'          => 'Trang chủ',
            'nav_search_placeholder' => 'Tìm kiếm thông tin...',
            'nav_hotline_label' => 'Hotline tư vấn',
            'nav_switch_lang'   => 'Ngôn ngữ',
        ),

        // Group: Forms & Inputs
        'Forms' => array(
            'form_fullname'     => 'Họ và tên',
            'form_phone'        => 'Số điện thoại',
            'form_email'        => 'Địa chỉ Email',
            'form_message'      => 'Nội dung yêu cầu',
            'form_placeholder_name'  => 'Nhập họ và tên...',
            'form_placeholder_phone' => 'Nhập số điện thoại...',
            'form_placeholder_email' => 'Nhập địa chỉ email...',
            'form_placeholder_msg'   => 'Nhập nội dung cần hỗ trợ...',
            'form_success'      => 'Cảm ơn bạn đã gửi thông tin! Chúng tôi sẽ liên hệ lại sớm nhất.',
            'form_error'        => 'Đã có lỗi xảy ra. Vui lòng thử lại sau ít phút.',
        ),

        // Group: Single & Archive
        'Archive & Details' => array(
            'related_items'     => 'Thông tin liên quan',
            'latest_posts'      => 'Bài viết mới nhất',
            'published_on'      => 'Ngày đăng: %s',
            'category_label'    => 'Chuyên mục:',
            'share_post'        => 'Chia sẻ bài viết:',
            'no_results'        => 'Không tìm thấy kết quả nào phù hợp.',
            'search_results_for'=> 'Kết quả tìm kiếm cho: "%s"',
            'view_all'          => 'Xem tất cả',
        ),

        // Group: Footer & Copyright
        'Footer' => array(
            'footer_about_us'   => 'Về chúng tôi',
            'footer_quick_links'=> 'Liên kết nhanh',
            'footer_contact_info'=> 'Thông tin liên hệ',
            'footer_address'    => 'Địa chỉ:',
            'footer_phone'      => 'Điện thoại:',
            'footer_email'      => 'Email:',
            'footer_copyright'  => 'Bản quyền thuộc về',
            'all_rights_reserved' => 'Đã đăng ký bản quyền.',
        ),

        // Group: 404 Error Page
        '404 Page' => array(
            '404_title'         => '404 - Không tìm thấy trang',
            '404_subtitle'      => 'Rất tiếc! Trang bạn đang tìm kiếm không tồn tại hoặc đã được chuyển đi.',
            '404_back_to_home'  => 'Quay lại Trang Chủ',
        ),
    );

    // Vòng lặp đăng ký chuỗi vào Polylang
    foreach ($strings as $group => $items) {
        $group_name = 'Theme - ' . $group;
        foreach ($items as $name => $text) {
            pll_register_string($name, $text, $group_name, false);
        }
    }
}
add_action('init', 'theme_register_polylang_strings');


/* ==========================================================================
   3. LANGUAGE SWITCHER HELPER (Hiển thị nút chuyển ngôn ngữ trên Header)
   ========================================================================== */

/**
 * Render thanh chọn ngôn ngữ tùy biến (Custom Language Switcher)
 *
 * @param array $options Tùy chọn hiển thị
 * @return string HTML output
 */
function theme_render_language_switcher($options = array()) {
    if (!function_exists('pll_the_languages')) {
        return '';
    }

    $default_args = array(
        'dropdown'               => 0,
        'show_names'             => 1,
        'display_names_as'       => 'slug', // 'name' hoặc 'slug' (VI / EN)
        'show_flags'             => 1,
        'hide_if_empty'          => 0,
        'force_home'             => 0,
        'echo'                   => 0,
        'hide_if_no_translation' => 0,
        'raw'                    => 1, // Lấy mảng raw để tự do dựng HTML
    );

    $args = wp_parse_args($options, $default_args);
    $languages = pll_the_languages($args);

    if (empty($languages) || !is_array($languages)) {
        return '';
    }

    ob_start();
    ?>
    <div class="c-lang-switcher dropdown">
        <button class="c-lang-switcher__btn dropdown-toggle" type="button" data-bs-toggle="dropdown" aria-expanded="false">
            <?php foreach ($languages as $lang): ?>
                <?php if ($lang['current_lang']): ?>
                    <?php if (!empty($lang['flag'])): ?>
                        <img src="<?php echo esc_url($lang['flag']); ?>" alt="<?php echo esc_attr($lang['name']); ?>" class="c-lang-switcher__flag" width="20" height="14">
                    <?php endif; ?>
                    <span class="c-lang-switcher__label"><?php echo esc_html(strtoupper($lang['slug'])); ?></span>
                <?php endif; ?>
            <?php endforeach; ?>
        </button>
        <ul class="c-lang-switcher__menu dropdown-menu">
            <?php foreach ($languages as $lang): ?>
                <li>
                    <a class="dropdown-item <?php echo $lang['current_lang'] ? 'active' : ''; ?>" href="<?php echo esc_url($lang['url']); ?>">
                        <?php if (!empty($lang['flag'])): ?>
                            <img src="<?php echo esc_url($lang['flag']); ?>" alt="<?php echo esc_attr($lang['name']); ?>" class="me-2" width="18" height="12">
                        <?php endif; ?>
                        <span><?php echo esc_html($lang['name']); ?></span>
                    </a>
                </li>
            <?php endforeach; ?>
        </ul>
    </div>
    <?php
    return ob_get_clean();
}
```

---

## 3. Quy Tắc Sử Dụng Trong Template PHP

### 3.1. In chuỗi đơn giản
- **Cách 1 (Khuyên dùng với escaping)**:
  ```php
  <button type="submit" class="btn btn-primary">
      <?php echo esc_html(pll__('Xem chi tiết')); ?>
  </button>
  ```
- **Cách 2 (In trực tiếp qua `pll_e`)**:
  ```php
  <span class="badge"><?php pll_e('Mới nhất'); ?></span>
  ```

### 3.2. Chuỗi trong Attribute (Placeholder, Title, Aria-label)
```php
<input type="text" 
       name="s" 
       class="form-control" 
       placeholder="<?php echo esc_attr(pll__('Tìm kiếm thông tin...')); ?>"
       aria-label="<?php echo esc_attr(pll__('Tìm kiếm thông tin...')); ?>">
```

### 3.3. Chuỗi có tham số động (printf / sprintf)
Tuyệt đối không nối chuỗi biến động vào chuỗi cần dịch (như `pll__('Trang ' . $paged)`). Hãy dùng định dạng format placeholder `%s`, `%d`:

```php
<div class="search-meta">
    <p>
        <?php 
        printf(
            esc_html(pll__('Kết quả tìm kiếm cho: "%s"')),
            '<span>' . esc_html(get_search_query()) . '</span>'
        ); 
        ?>
    </p>
</div>
```

---

## 4. Polylang & ACF Pro (Advanced Custom Fields)

Khi theme sử dụng cả ACF Pro và Polylang:

1. **ACF Options Page theo ngôn ngữ**:
   - Nếu dự án cần Theme Options riêng cho từng thứ tiếng (Logo, Hotline, Giới thiệu công ty):
   ```php
   // Lấy mã ngôn ngữ hiện tại: 'vi', 'en'
   $lang = pll_current_language('slug');

   // Cách 1: Tạo field theo hậu tố trong ACF: hotline_vi, hotline_en
   $hotline = get_field('hotline_' . $lang, 'option') ?: get_field('hotline', 'option');

   // Cách 2: Nếu dùng addon Polylang ACF, ACF tự động phân tách post ID options:
   $hotline = get_field('hotline', 'option'); // Tự động lấy theo ngôn ngữ đang kích hoạt
   ```

2. **Dữ liệu Fallback mặc định**:
   - Luôn đặt fallback để nếu ngôn ngữ thứ hai (như English) người quản trị chưa nhập đầy đủ field thì vẫn hiển thị nội dung mẫu:
   ```php
   $heading = get_field('hero_heading');
   if (empty($heading)) {
       $heading = pll__('Tiêu đề mặc định dự án');
   }
   echo esc_html($heading);
   ```

---

## 5. Checklist Kiểm Thử Đa Ngôn Ngữ (Phase 5 QA)

- [ ] File `core/polylang.php` đã được require trong `functions.php`.
- [ ] Tắt hoàn toàn plugin Polylang trong WP Admin ➔ Truy cập lại trang chủ, trang single, trang archive ➔ **Không xuất hiện bất kỳ lỗi Fatal / Warning nào**.
- [ ] Bật lại plugin Polylang ➔ Truy cập **Languages ➔ String translations** ➔ Thấy toàn bộ các nhóm chuỗi (*Theme - Buttons*, *Theme - Forms*, *Theme - Header*...).
- [ ] Không còn chuỗi text UI cứng nào bằng tiếng Việt chưa qua `pll__()` hoặc `pll_e()`.
- [ ] Toàn bộ chuỗi trong input attributes đã được escape bằng `esc_attr(pll__(...))`.
