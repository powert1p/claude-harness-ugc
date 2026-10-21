#!/bin/bash
# block-destructive.sh
# PreToolUse hook для Bash. Блокирует ТОЛЬКО реально катастрофичное / утечку секретов.
# Всё остальное (force-push, DROP TABLE, миграции, деплой, мерж) — разрешено: полная автономия.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$COMMAND" ] && exit 0

# rm -rf корня или home — необратимое уничтожение машины/домашней папки
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]+\s+)+(/|/\*|~|\$HOME)(\s|$)'; then
  echo '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "rm -rf / или home — необратимо. Если правда нужно — запусти вручную."}}'
  exit 0
fi

# DROP DATABASE — уничтожение всей БД целиком
if echo "$COMMAND" | grep -qiE 'DROP\s+DATABASE'; then
  echo '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "DROP DATABASE — сносит всю базу. Если правда нужно — запусти вручную."}}'
  exit 0
fi

# Чтение .env — секреты не должны попадать в контекст агента
if echo "$COMMAND" | grep -qE '(cat|less|head|tail|more|source|grep|sed|awk|bat)\s+\.env\b|echo.*\$\(.*\.env'; then
  echo '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "Чтение .env заблокировано — секреты не должны попадать в контекст."}}'
  exit 0
fi

exit 0
