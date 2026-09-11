# Chuẩn Thiết Lập ACF Pro Local PHP & Ráp Backend Đa Năng

Tài liệu hướng dẫn cách ánh xạ bất kỳ khối giao diện HTML nào thành **ACF Pro Local PHP Field Groups** (`core/acf-fields.php`) và kỹ thuật ráp dynamic content an toàn, có dữ liệu fallback cho mọi loại website.

---

## 1. Nguyên Tắc Cốt Lõi

1. **Đăng ký 100% bằng PHP Code**:
   - Sử dụng `acf_add_options_page()` và `acf_add_local_field_group()` trong hook `acf/init`.
   - Theme có thể kích hoạt trên bất kỳ hosting/server nào mà không cần file JSON export thủ công.
2. **Hướng Dẫn `instructions` Tiếng Việt Chi Tiết**:
   - Mọi field phải có `instructions` ghi rõ vị trí hiển thị, kích thước ảnh đề xuất (VD: *"Kích thước khuyến nghị: 1920x800px"*), hoặc ví dụ cụ thể.
3. **Nguyên Tắc Dự Phòng (Fallback Data)**:
   - Tuyệt đối không để trang bị trắng/vỡ giao diện nếu người dùng chưa kịp điền nội dung trong WP Admin. Luôn cung cấp text/ảnh mặc định từ template HTML gốc.

---

## 2. Quy Tắc Đặt Tên Field Đa Lĩnh Vực

| Phạm vi | Quy tắc đặt Name | Quy tắc Group Key | Ví dụ thực tế |
| :--- | :--- | :--- | :--- |
| **Theme Options Toàn Site** | `{context}_{field}` | `group_opt_{context}` | `hotline`, `email`, `company_address`, `header_logo`, `social_facebook` |
| **Section Trang Chủ** | `home_{section}_{field}` | `group_opt_home_{section}` | `home_hero_slides`, `home_about_title`, `home_stats_counters` |
| **Chi Tiết Thực Thể (CPT)** | `{cpt}_{field}` | `group_{cpt}_details` | `project_price`, `course_duration`, `doctor_degree`, `car_specs` |
| **Trang Tĩnh Đơn Lẻ** | `{page_slug}_{section}_{field}` | `group_page_{page_slug}` | `about_vision_desc`, `contact_map_iframe` |
| **Trường con trong Repeater** | `{field_ngắn_gọn}` | N/A | `item_title`, `item_desc`, `item_image`, `item_link` |

---

## 3. Ma Trận Ánh Xạ UI Component Sang ACF Field (Component-to-Field Matrix)

Mọi template HTML đều được cấu thành từ các UI component phổ biến dưới đây. Hãy đối chiếu trực tiếp để sinh ACF field tương ứng:

### A. Nhóm Theme Options Toàn Site
- **Header Topbar / Main**:
  - Logo chính & Logo mobile (`image`, return: `id` hoặc `array`).
  - Hotline, Email, Giờ làm việc (`text`).
  - Nút Call-To-Action trên menu (`text` label + `url` link).
- **Footer**:
  - Mô tả ngắn công ty (`textarea`).
  - Địa chỉ văn phòng, Mã số thuế (`textarea` / `text`).
  - Danh sách mạng xã hội: Repeater `social_links` (`platform_icon`, `social_url`).
  - Dòng Copyright (`text`).
  - Mã script Header/Footer tracking (`textarea`).

### B. Nhóm Các Section Trang Chủ & Landing Page
- **Hero / Banner Slider**:
  - Repeater `hero_slides`: `slide_image` (image), `slide_subtitle` (text), `slide_title` (text), `slide_desc` (textarea), `btn_text` (text), `btn_url` (url).
- **Khối Giới Thiệu / Story (About Section)**:
  - `about_badge` (text), `about_title` (text), `about_content` (wysiwyg), `about_featured_image` (image).
  - Repeater `about_counters`: `stat_number` (text, VD: "15+"), `stat_label` (text, VD: "Năm kinh nghiệm").
- **Lưới Tính Năng / Dịch Vụ Nổi Bật (Features/Services Grid)**:
  - Repeater `features_list`: `feature_icon` (image hoặc fontawesome class), `feature_title` (text), `feature_desc` (textarea), `feature_link` (url).
- **Bảng Báo Giá / Gói Dịch Vụ (Pricing Tables)**:
  - Repeater `pricing_plans`: `plan_name` (text), `plan_price` (text), `plan_unit` (text, VD: "/tháng"), `is_popular` (true_false), `plan_features` (repeater: `feature_text`), `btn_text`, `btn_url`.
- **Đánh Giá Của Khách Hàng (Testimonials / Reviews)**:
  - Repeater `testimonials`: `client_avatar` (image), `client_name` (text), `client_role` (text), `rating_stars` (number, 1-5), `review_quote` (textarea).
- **Câu Hỏi Thường Gặp (FAQ Accordion)**:
  - Repeater `faq_items`: `faq_question` (text), `faq_answer` (wysiwyg).
- **Đội Ngũ Nhân Sự / Chuyên Gia (Team / Experts)**:
  - Repeater `team_members`: `member_photo` (image), `member_name` (text), `member_position` (text), `member_bio` (textarea).
- **Đối Tác / Khách Hàng (Brand Logos / Partners)**:
  - `brand_logos` (gallery) hoặc Repeater: `partner_logo` (image), `partner_name` (text), `partner_url` (url).

### C. Nhóm Chi Tiết Thực Thể (CPT Detail Fields)
- **Thông Số Kỹ Thuật / Đặc Điểm (Specs / Attributes)**:
  - Repeater `item_specs`: `spec_label` (text, VD: "Diện tích", "Số chỗ ngồi", "Thời lượng"), `spec_value` (text, VD: "120 m²", "7 chỗ", "36 giờ").
- **Thư Viện Ảnh (Gallery / Album)**:
  - `item_gallery` (gallery).
- **Lịch Trình / Quy Trình / Lộ Trình (Timeline / Itinerary / Roadmap)**:
  - Repeater `item_timeline`: `step_number` (text), `step_title` (text), `step_content` (wysiwyg).
- **Bao Gồm & Không Bao Gồm (Includes / Excludes)**:
  - Repeater `includes_list`: `item_text` (text).
  - Repeater `excludes_list`: `item_text` (text).
- **Tài Liệu Đính Kèm (Downloadable Attachments)**:
  - Repeater `attachments`: `file_title` (text), `file_download` (file).

---

## 4. Khung Mẫu Hoàn Chỉnh Cho `core/acf-fields.php`

```php
<?php
/**
 * Đăng ký ACF Pro Field Groups bằng PHP Thuần
 */
if (!defined('ABSPATH')) exit;

// 1. Tạo Trang Theme Options
if (function_exists('acf_add_options_page')) {
    acf_add_options_page(array(
        'page_title' => 'Cấu hình Giao diện',
        'menu_title' => 'Theme Options',
        'menu_slug'  => 'theme-options',
        'capability' => 'edit_posts',
        'icon_url'   => 'dashicons-admin-generic',
        'redirect'   => false,
    ));
}

// 2. Khởi tạo Field Groups
add_action('acf/init', 'theme_register_all_acf_field_groups');
function theme_register_all_acf_field_groups() {
    if (!function_exists('acf_add_local_field_group')) return;

    // A. Nhóm Theme Options Toàn Site
    acf_add_local_field_group(array(
        'key'      => 'group_opt_general',
        'title'    => '1. Thông tin Chung & Liên hệ (Header/Footer)',
        'fields'   => array(
            array(
                'key'          => 'field_opt_hotline',
                'label'        => 'Số Điện thoại Hotline',
                'name'         => 'hotline',
                'type'         => 'text',
                'instructions' => 'Số hotline chính hiển thị ở Header và Footer. VD: 0912 345 678',
            ),
            array(
                'key'          => 'field_opt_email',
                'label'        => 'Email liên hệ',
                'name'         => 'email',
                'type'         => 'email',
                'instructions' => 'Email tiếp nhận liên hệ từ khách hàng.',
            ),
            array(
                'key'          => 'field_opt_address',
                'label'        => 'Địa chỉ trụ sở',
                'name'         => 'company_address',
                'type'         => 'textarea',
                'rows'         => 3,
                'instructions' => 'Địa chỉ đầy đủ hiển thị ở Footer và Trang liên hệ.',
            ),
            array(
                'key'          => 'field_opt_copyright',
                'label'        => 'Dòng bản quyền Footer',
                'name'         => 'footer_copyright',
                'type'         => 'text',
                'instructions' => 'Dòng chữ bản quyền ở chân trang. VD: © 2026 Tên Công Ty. All Rights Reserved.',
            ),
        ),
        'location' => array(
            array(
                array(
                    'param'    => 'options_page',
                    'operator' => '==',
                    'value'    => 'theme-options',
                ),
            ),
        ),
    ));

    // B. Nhóm Chi Tiết Thực Thể (CPT) Mẫu
    acf_add_local_field_group(array(
        'key'      => 'group_cpt_item_details',
        'title'    => 'Thông tin Chi tiết của Mục',
        'fields'   => array(
            array(
                'key'          => 'field_cpt_price',
                'label'        => 'Mức giá / Chi phí',
                'name'         => 'item_price',
                'type'         => 'number',
                'instructions' => 'Mức giá (nhập số không kèm ký tự đặc biệt). VD: 5000000',
            ),
            array(
                'key'          => 'field_cpt_gallery',
                'label'        => 'Album / Thư viện ảnh',
                'name'         => 'item_gallery',
                'type'         => 'gallery',
                'instructions' => 'Chọn hoặc tải lên các hình ảnh liên quan.',
            ),
            array(
                'key'          => 'field_cpt_specs',
                'label'        => 'Bảng Thông số / Đặc tính',
                'name'         => 'item_specs',
                'type'         => 'repeater',
                'layout'       => 'table',
                'button_label' => 'Thêm thông số',
                'sub_fields'   => array(
                    array(
                        'key'   => 'field_sub_spec_name',
                        'label' => 'Tên thông số',
                        'name'  => 'spec_name',
                        'type'  => 'text',
                    ),
                    array(
                        'key'   => 'field_sub_spec_value',
                        'label' => 'Giá trị',
                        'name'  => 'spec_value',
                        'type'  => 'text',
                    ),
                ),
            ),
        ),
        'location' => array(
            array(
                array(
                    'param'    => 'post_type',
                    'operator' => '==',
                    'value'    => '{cpt_slug}', // Thay thế bằng CPT thực tế
                ),
            ),
        ),
    ));
}
```

---

## 5. Kỹ Thuật Ráp Backend Linh Hoạt & An Toàn

### A. Ráp Theme Options Kèm Fallback Mặc Định
```php
<?php
$hotline = get_field('hotline', 'option') ?: '0912.345.678';
$email   = get_field('email', 'option') ?: 'contact@domain.com';
?>
<a href="tel:<?php echo esc_attr(preg_replace('/[^0-9]/', '', $hotline)); ?>" class="hotline-btn">
    <i class="fas fa-phone-alt"></i> <?php echo esc_html($hotline); ?>
</a>
```

### B. Ráp Bảng Thông Số Repeater
```php
<?php if (have_rows('item_specs')): ?>
    <div class="specs-table-wrapper">
        <table class="table table-bordered specs-table">
            <tbody>
                <?php while (have_rows('item_specs')): the_row(); 
                    $spec_name  = get_sub_field('spec_name');
                    $spec_value = get_sub_field('spec_value');
                ?>
                    <tr>
                        <th class="spec-label"><?php echo esc_html($spec_name); ?></th>
                        <td class="spec-val"><?php echo esc_html($spec_value); ?></td>
                    </tr>
                <?php endwhile; ?>
            </tbody>
        </table>
    </div>
<?php endif; ?>
```

### C. Ráp Thư Viện Ảnh (Gallery)
```php
<?php 
$gallery = get_field('item_gallery');
if (!empty($gallery) && is_array($gallery)): 
?>
    <div class="gallery-slider owl-carousel">
        <?php foreach ($gallery as $image): ?>
            <div class="gallery-item">
                <a href="<?php echo esc_url($image['url']); ?>" data-lightbox="gallery">
                    <img src="<?php echo esc_url($image['sizes']['medium_large'] ?? $image['url']); ?>" 
                         alt="<?php echo esc_attr($image['alt'] ?: get_the_title()); ?>" class="img-fluid">
                </a>
            </div>
        <?php endforeach; ?>
    </div>
<?php endif; ?>
```
