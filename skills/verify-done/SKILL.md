---
name: verify-done
description: Final verification gate ("kiểm chứng trước khi xong") — run real commands, read real output, only then say it's done. Use before claiming completion, before committing, before opening a PR.
---

# Kiểm chứng trước khi nói xong

Quy tắc một dòng: **không có output thì không có tuyên bố**.

"Chắc là chạy được", "về logic thì đúng", "thay đổi này an toàn" — đều không phải bằng chứng.

## Chạy gì

Lấy lệnh từ plan (mục Kiểm chứng của từng task) hoặc từ cấu hình project. Nếu đang ở trong worktree cô lập (`WORKTREE_PATH`), chạy lệnh tại thư mục worktree đó:

| Stack | Lệnh |
|---|---|
| Laravel | `php artisan test` · `php -l` file đã sửa · `[ -f vendor/bin/pint ] && vendor/bin/pint --test` |
| Node | `npm test` · `npm run build` · `npm run lint` |
| Flutter | `flutter test` · `flutter analyze` |
| WordPress | `php -l` **mọi file đã sửa** · mở trang render thật |

`php -l` với WordPress là bắt buộc chứ không phải tuỳ chọn: lỗi cú pháp trong `functions.php`
làm trắng toàn site.

## Cách báo cáo

Dán output thật, không tóm tắt:

```
$ php artisan test
  Tests:  24 passed (89 assertions)
  Time:   1.42s
```

Đúng một lệnh mỗi dòng, kèm kết quả. Lệnh nào không chạy được thì nói rõ vì sao chưa chạy,
đừng bỏ qua im lặng.

## Khi có test fail

Nói thẳng là fail. Dán output. Đừng viết "hầu hết test đã pass".

Rồi chọn một:
- Sửa được ngay → sửa, chạy lại, dán output mới
- Không liên quan thay đổi này → nói rõ nó đã fail từ trước, kèm bằng chứng (`git stash` rồi chạy lại)
- Không sửa được → báo cáo nguyên trạng, để người dùng quyết

## Tính năng có giao diện — kiểm đường vào, không chỉ kiểm route

Test tự động trả `200` cho một route không chứng minh người dùng thật **tới được** route
đó. Route đúng, layout đúng, test pass — nhưng nếu không có link nào từ màn hình mặc định
sau đăng nhập dẫn tới nó, tính năng vô hình với người dùng dù mọi thứ "Đạt" trên giấy.

Với bất kỳ tính năng nào có giao diện (không phải API thuần), việc chạy `verify-done` phải
gồm một bước không thay bằng test tự động: đăng nhập bằng tài khoản thật của đúng vai trò,
xuất phát từ màn hình mặc định sau đăng nhập — **không** gõ thẳng URL tính năng — và xác
nhận có đường bấm tới được. Route test và feature test kiểm được "trang này hoạt động đúng
khi tới nơi"; chúng không kiểm được "có tới nơi được không".

## Tính năng có áp dụng `ui-design`

Test tự động và việc "route trả về được" không kiểm được thẩm mỹ. Route đúng, không có
`console.error`, đúng luồng — mà vẫn có thể là một trang không ai muốn dùng vì chỉ toàn
input xám xếp chồng.

Có Playwright MCP: chụp ảnh màn hình thật của trang vừa dựng, nhìn lại đối chiếu với hướng
thẩm mỹ đã chọn ở `devflow:ui-design` Bước 1 — có đúng tông đã cam kết không, có rơi vào bốn
mặc định cần tránh không (font hệ thống, gradient tím-trắng, cột dọc đơn điệu, không chi
tiết). Không có Playwright MCP: tự mô tả những gì thấy được từ markup đã sinh, đối chiếu
cùng bốn khoảng ở Bước 2 của `ui-design`.

## Với việc không có test

WordPress theme, thay đổi giao diện, script một lần — bằng chứng là **kết quả quan sát được**:

- Mở trang thật, mô tả thấy gì
- Chụp màn hình nếu có Playwright MCP
- Kiểm tra console trình duyệt không có lỗi
- Với responsive: gọi `devflow:wp-responsive-check`

"Tôi đã sửa CSS" không phải bằng chứng. "Mở trang, nút giờ nằm giữa, console sạch" mới là.

## Checklist trước khi tuyên bố xong

- [ ] Đã chạy lệnh test/build, đã dán output
- [ ] Test fail đã nêu rõ, không giấu
- [ ] Mọi tiêu chí nghiệm thu trong spec đã đối chiếu từng cái
- [ ] Việc bị bỏ dở đã nói rõ là bỏ dở và vì sao
- [ ] Không có file tạm, `console.log`, `dd()`, `var_dump()` sót lại

## Việc làm chưa xong

Làm được 3/5 task thì báo 3/5, kèm lý do 2 task còn lại chưa xong. Đừng báo "đã hoàn thành"
rồi liệt kê phần thiếu ở cuối — người đọc dừng ở dòng đầu.
