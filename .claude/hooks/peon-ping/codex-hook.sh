#!/bin/bash
# Best-effort Codex adapter for peon-ping hook events.
set -u

event="${1:-SessionStart}"
case "$event" in
  SessionStart|UserPromptSubmit|Stop|PermissionRequest|PostToolUse|PreToolUse|Notification|PreCompact|SubagentStop|SubagentStart) ;;
  *) event="SessionStart" ;;
esac

peon_script="${PEON_HOOK_SCRIPT:-/Users/ab/.claude/hooks/peon-ping/peon.sh}"
log_file="${PEON_HOOK_LOG:-/tmp/peon-ping-hook.log}"

payload=""
if [ ! -t 0 ]; then
  if command -v timeout >/dev/null 2>&1; then
    payload=$(timeout 2 cat 2>/dev/null || true)
  elif command -v gtimeout >/dev/null 2>&1; then
    payload=$(gtimeout 2 cat 2>/dev/null || true)
  else
    IFS= read -r -t 2 payload || true
  fi
fi

if [ -z "$payload" ]; then
  payload="{\"hook_event_name\":\"$event\",\"source\":\"codex\"}"
fi

if [ -x "$peon_script" ]; then
  printf '%s' "$payload" | PEON_ALLOW_HEADLESS="${PEON_ALLOW_HEADLESS:-1}" "$peon_script" >/dev/null 2>>"$log_file" || true
fi

exit 0
