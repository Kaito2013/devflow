---
name: isolate-worktree
description: Ensure subagent execution happens in an isolated workspace ("cô lập worktree"), so a failed run never dirties the branch the user is looking at. Use at the start of subagent-execution, before dispatching the first task.
---

# Cô lập workspace

Mục tiêu: nếu một lần chạy SDD đi sai hướng giữa chừng, người dùng vẫn còn nguyên nhánh
đang làm việc để quay lại — không phải dọn dẹp thủ công một đống commit dở dang trên chính
nhánh họ đang xem.

## Bước 0 — Kiểm tra đã cô lập sẵn chưa

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
```

`GIT_DIR != GIT_COMMON` nghĩa là đang **ở trong một worktree liên kết rồi** — bỏ qua bước
tạo mới, sang thẳng Bước 2.

**Bẫy submodule:** điều kiện trên cũng đúng khi đang ở trong git submodule, không chỉ
worktree. Kiểm thêm trước khi kết luận:

```bash
git rev-parse --show-superproject-working-tree 2>/dev/null
```

Có output (đường dẫn) → đang trong submodule, coi như repo bình thường, không phải worktree
đã cô lập.

`GIT_DIR == GIT_COMMON` (và không phải submodule) → đang ở checkout bình thường, sang Bước 1.

## Bước 1 — Tạo workspace cô lập

**Tự quyết, không dừng hỏi.** Tạo một worktree cục bộ là hành động **hoàn toàn cục bộ và dễ
hoàn tác** — không nằm trong 4 điều buộc dừng của `subagent-execution` (không phá huỷ, không
chạm bảo mật, không ảnh hưởng ra ngoài phạm vi, không phải plan hỏng). Tạo luôn, ghi vào
ledger dạng `Ruling: tạo worktree tại <path>, nhánh <tên> — cô lập khỏi <nhánh gốc>`.

**Có tool cô lập sẵn của harness thì dùng tool đó trước** (ví dụ `EnterWorktree`/
`ExitWorktree` nếu môi trường có) — nó tự lo việc đặt thư mục, tạo nhánh, và dọn dẹp khi
xong. Dùng `git worktree add` thủ công trong khi đã có tool sẵn tạo ra trạng thái "ma" mà
harness không quản lý được.

**Không có tool sẵn — làm thủ công:**

```bash
ls -d .worktrees 2>/dev/null || ls -d worktrees 2>/dev/null   # đã có sẵn thì dùng lại
git check-ignore -q .worktrees || { echo ".worktrees/" >> .gitignore; git add .gitignore; git commit -m "chore: ignore .worktrees/"; }

MAIN_REPO="$(pwd -P)"
path=".worktrees/<tên-nhánh>"
git worktree add "$path" -b "<tên-nhánh>"
WORKTREE_PATH="$(cd "$path" && pwd -P)"
```

**Lưu ý cốt lõi:** Lệnh `cd` trong subshell không thay đổi CWD của tiến trình chính hay subagent. Controller **bắt buộc phải lưu biến `WORKTREE_PATH`** để truyền tường minh cho mọi subagent trong `subagent-execution`. Mọi lệnh thực thi công cụ (file edit, run_command) phải trỏ vào đường dẫn này.

Không tự bỏ qua bước `git check-ignore` — thư mục worktree không bị ignore thì lần commit
sau sẽ đưa nguyên workspace phụ vào repo chính.

**Sandbox chặn `git worktree add`** (lỗi permission): báo cho người dùng biết sandbox chặn
tạo worktree, làm tiếp ngay tại thư mục hiện tại, ghi vào ledger rằng lần chạy này **không**
được cô lập.

## Bước 2 — Sao chép file bị git ignore

Worktree mới chỉ có đúng nội dung đã **commit** — mọi file bị `.gitignore` (config môi
trường, artifact build, local SQLite) không tự có, dù cần thiết để app chạy được:

```bash
[ -f "$MAIN_REPO/.env" ] && cp "$MAIN_REPO/.env" "$WORKTREE_PATH/"   # bắt buộc, app không khởi động nổi nếu thiếu
[ -f "$MAIN_REPO/.env.testing" ] && cp "$MAIN_REPO/.env.testing" "$WORKTREE_PATH/"
[ -f "$MAIN_REPO/database/database.sqlite" ] && mkdir -p "$WORKTREE_PATH/database" && cp "$MAIN_REPO/database/database.sqlite" "$WORKTREE_PATH/database/"
```

Không đoán còn thiếu gì khác — nếu Bước 3 (baseline) đỏ vì lý do liên quan tới file cấu hình
hay artifact build, đó là dấu hiệu cần copy thêm, xem hướng dẫn ở Bước 3.

## Bước 3 — Cài đặt và build dự án trong workspace mới

Thực thi trong `$WORKTREE_PATH`. Tự nhận diện theo stack, chạy đúng lệnh:

```bash
[ -f composer.json ] && composer install   # Laravel, PHP
[ -f package.json ]   && npm install        # Node
[ -f pubspec.yaml ]   && flutter pub get    # Flutter
```

**Có Vite/webpack (kiểm bằng `[ -f vite.config.js ]` hoặc script `build` trong
`package.json`): bắt buộc chạy thêm `npm run build`.** `public/build/manifest.json` cũng bị
git ignore như `.env` — thiếu nó, mọi trang Blade có `@vite(...)` trả lỗi 500
(`ViteManifestNotFoundException`), nhưng lỗi hiển thị ra ngoài qua Blade thường là một thông
báo khác hẳn (`No hint path defined for [...]`) khiến dễ tưởng nhầm là lỗi view/namespace
thay vì tra đúng gốc là thiếu manifest. Test lẻ (`--filter`) có thể vẫn pass trong khi cả
suite fail hàng loạt — đây chính là dấu hiệu để nghi ngờ thiếu build, không phải lỗi code.

```bash
[ -f package.json ] && grep -q '"build"' package.json && npm run build
```

Theme/plugin WordPress đứng ngoài `subagent-execution` (xem phần Ngoại lệ trong đó) nên
không cần bước này.

## Bước 4 — Xác nhận baseline sạch trước khi bắt đầu

Chạy test suite (nếu plan ghi **Có test: có**) **một lần** tại `$WORKTREE_PATH`, trước khi phát Task 1:

```bash
php artisan test / npm test / flutter test
```

**Baseline đã đỏ sẵn — trước khi hỏi, tự loại trừ nguyên nhân do chính worktree gây ra.** So
với kết quả chạy cùng lệnh ở checkout gốc: nếu checkout gốc sạch mà worktree đỏ, đây thường
là hệ quả của Bước 2/3 làm chưa đủ (thiếu file bị ignore, thiếu build) chứ không phải baseline
thật của dự án — root-cause trước khi kết luận. Dấu hiệu hay gặp: **nhiều test cùng fail vì
một lỗi trông không liên quan gì tới bug thật** (ví dụ lỗi view/namespace trong khi gốc là
thiếu Vite manifest) — đọc stack trace đầy đủ, đừng dừng ở dòng lỗi đầu tiên.

Sau khi đã loại trừ nguyên nhân môi trường mà vẫn đỏ — đây là trường hợp hiếm hoi controller
**nên hỏi thay vì tự quyết**: không phải vì phá huỷ hay ảnh hưởng ra ngoài phạm vi, mà vì
không có cách nào tự phân biệt lỗi này với lỗi do task sau đó gây ra — mọi phát hiện của
`review-changes` và `verify-done` từ giờ đều mơ hồ nếu không biết baseline vốn đã đỏ. Hỏi
một câu: *"Baseline đang có N test fail trước khi bắt đầu — tiếp tục hay dừng lại kiểm tra?"*

**Baseline sạch** → ghi vào ledger, chuyển sang `subagent-execution` cùng biến `WORKTREE_PATH`.

## Kết thúc & Dọn dẹp — không tự merge

Khi `verify-done` xác nhận toàn bộ plan xong, báo đường dẫn worktree và tên nhánh cho người
dùng, hỏi họ muốn merge, mở PR, hay để lại xem thủ công. **Không tự merge vào nhánh
chung** mà không có sự đồng ý của người dùng — đây là hành động ảnh hưởng ra ngoài phạm vi đang làm việc.

Khi người dùng đồng ý merge hoặc yêu cầu dọn dẹp:

```bash
# 1. Nếu người dùng chọn Merge vào nhánh chính:
git checkout <nhánh-gốc>
git merge --no-ff "<tên-nhánh>" -m "feat: hoàn tất triển khai plan <tên>"

# 2. Dọn dẹp worktree sau khi merge hoặc khi người dùng muốn hủy:
git worktree remove ".worktrees/<tên-nhánh>" --force
git branch -d "<tên-nhánh>"   # hoặc -D nếu hủy bỏ
```
