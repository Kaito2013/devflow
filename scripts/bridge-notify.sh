#!/usr/bin/env bash
# scripts/bridge-notify.sh in devflow repo
set -euo pipefail

TASK_NAME="${1:-}"
STATUS="${2:-APPROVED}"
COMMIT_HASH="${3:-}"

if command -v devflow-cli >/dev/null 2>&1; then
  devflow-cli notify --task "$TASK_NAME" --status "$STATUS" --commit "$COMMIT_HASH" 2>/dev/null || true
elif [ -f "$HOME/devflow-cli/devflow-cli" ]; then
  "$HOME/devflow-cli/devflow-cli" notify --task "$TASK_NAME" --status "$STATUS" --commit "$COMMIT_HASH" 2>/dev/null || true
fi
