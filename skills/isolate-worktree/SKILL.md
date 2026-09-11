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

path=".worktrees/<tên-nhánh>"
git worktree add "$path" -b "<tên-nhánh>"
cd "$path"
```

Không tự bỏ qua bước `git check-ignore` — thư mục worktree không bị ignore thì lần commit
sau sẽ đưa nguyên workspace phụ vào repo chính.

**Sandbox chặn `git worktree add`** (lỗi permission): báo cho người dùng biết sandbox chặn
tạo worktree, làm tiếp ngay tại thư mục hiện tại, ghi vào ledger rằng lần chạy này **không**
được cô lập.

## Bước 2 — Cài đặt dự án trong workspace mới

Tự nhận diện theo stack, chạy đúng lệnh:

```bash
[ -f composer.json ] && composer install   # Laravel, PHP
[ -f package.json ]   && npm install        # Node
[ -f pubspec.yaml ]   && flutter pub get    # Flutter
```

Theme/plugin WordPress đứng ngoài `subagent-execution` (xem phần Ngoại lệ trong đó) nên
không cần bước này.

## Bước 3 — Xác nhận baseline sạch trước khi bắt đầu

Chạy test suite (nếu plan ghi **Có test: có**) **một lần**, trước khi phát Task 1:

```bash
php artisan test / npm test / flutter test
```

**Baseline đã đỏ sẵn** — đây là trường hợp hiếm hoi controller **nên hỏi thay vì tự quyết**:
không phải vì phá huỷ hay ảnh hưởng ra ngoài phạm vi, mà vì không có cách nào tự phân biệt
lỗi này với lỗi do task sau đó gây ra — mọi phát hiện của `review-changes` và `verify-done`
từ giờ đều mơ hồ nếu không biết baseline vốn đã đỏ. Hỏi một câu: *"Baseline đang có N test
fail trước khi bắt đầu — tiếp tục hay dừng lại kiểm tra?"*

**Baseline sạch** → ghi vào ledger, sang phát Task 1.

## Kết thúc — không tự merge

Khi `verify-done` xác nhận toàn bộ plan xong, báo đường dẫn worktree và tên nhánh cho người
dùng, hỏi họ muốn merge, mở PR, hay để đó xem lại thủ công. **Không tự merge vào nhánh
chung** — đây là hành động ảnh hưởng ra ngoài phạm vi đang làm việc, đúng một trong bốn điều
buộc dừng của `subagent-execution`, khác hẳn với việc tự tạo worktree ở Bước 1.
