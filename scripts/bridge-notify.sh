#!/usr/bin/env bash
# scripts/bridge-notify.sh in devflow repo
set -euo pipefail

DEVFLOW_BIN=""
if command -v devflow-cli >/dev/null 2>&1; then
  DEVFLOW_BIN="devflow-cli"
elif [ -f "$HOME/devflow-cli/devflow-cli" ]; then
  DEVFLOW_BIN="$HOME/devflow-cli/devflow-cli"
fi

if [ -z "$DEVFLOW_BIN" ]; then
  exit 0
fi

# If arguments start with flags, pass them through directly
if [ $# -gt 0 ] && [[ "$1" == -* ]]; then
  "$DEVFLOW_BIN" notify "$@" 2>/dev/null || true
else
  TASK_NAME="${1:-}"
  STATUS="${2:-APPROVED}"
  COMMIT_HASH="${3:-}"
  EVENT="${4:-task_update}"
  "$DEVFLOW_BIN" notify --event "$EVENT" --task "$TASK_NAME" --status "$STATUS" --commit "$COMMIT_HASH" 2>/dev/null || true
fi
