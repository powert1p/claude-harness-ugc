#!/bin/bash
# sync.sh — синк харнеса с GitHub без участия владелицы.
# Зовётся на SessionStart (подтянуть правки Есета) и на Stop (сохранить её правки).
# Работа уходит в фон и хук возвращается сразу: Stop срабатывает на каждом ходе,
# ожидание сети здесь тормозило бы каждый ответ.
# Конфликт rebase → откат, флаг state/sync-conflict; soul-inject попросит агента починить.

C="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
[ -d "$C/.git" ] || exit 0
cat >/dev/null  # stdin хука не нужен

mkdir -p "$C/logs" "$C/state" 2>/dev/null
nohup bash -c '
  C="$1"; cd "$C" || exit 0
  # Лок: Stop и SessionStart могут прийти почти одновременно
  mkdir state/sync.lock 2>/dev/null || exit 0
  trap "rmdir state/sync.lock" EXIT
  echo "[$(date "+%F %T")] sync"
  git add -A
  git diff --cached --quiet || git commit -qm "sync: $(date "+%F %H:%M")"
  if ! git pull -q --rebase --autostash; then
    git rebase --abort 2>/dev/null
    date > state/sync-conflict
    echo "[conflict] rebase отменён"
    exit 0
  fi
  rm -f state/sync-conflict
  git push -q || echo "[push failed]"
' _ "$C" >>"$C/logs/sync.log" 2>&1 </dev/null &
disown 2>/dev/null
exit 0
