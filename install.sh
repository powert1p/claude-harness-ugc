#!/bin/bash
# install.sh — ставит харнес в ~/.claude поверх того, что Claude Code уже создал.
# Запуск из склонированной копии: bash /tmp/h/install.sh
# Повторный запуск безопасен: уже установленный харнес просто обновится.
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"

SRC="$(cd "$(dirname "$0")" && pwd)"
C="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
TS=$(date +%F-%H%M)

command -v git >/dev/null || { echo "FAIL: нет git — сначала xcode-select --install"; exit 1; }
mkdir -p "$C"

if [ -d "$C/.git" ]; then
  echo "харнес уже стоит — обновляю"
  git -C "$C" pull -q --rebase --autostash
else
  # ~/.claude уже живой (сессии, кэши) — его не сносим. Переносим .git внутрь
  # и раскладываем файлы харнеса; рантайм закрыт .gitignore и не трогается.
  for f in $(git -C "$SRC" ls-files); do
    [ -e "$C/$f" ] && { mkdir -p "$(dirname "$C/$f.bak-$TS")"; cp -p "$C/$f" "$C/$f.bak-$TS"; echo "бэкап: $f.bak-$TS"; }
  done
  cp -R "$SRC/.git" "$C/.git"
  git -C "$C" checkout -f -q main
fi

chmod +x "$C"/hooks/*.sh

# Push без вопросов: git берёт токен у gh
command -v gh >/dev/null && gh auth setup-git >/dev/null 2>&1 || echo "WARN: gh не залогинен — синк не будет пушить"
git -C "$C" config user.name >/dev/null || git -C "$C" config user.name "$(id -F 2>/dev/null || whoami)"
git -C "$C" config user.email >/dev/null || git -C "$C" config user.email "$(whoami)@$(hostname -s).local"

mkdir -p "$HOME/Blog"

# Плагин humanizer. settings.json тоже его включает, но без CLI-установки он
# появляется только после подтверждения в интерфейсе — ставим сразу.
if command -v claude >/dev/null; then
  claude plugin marketplace add blader/humanizer >/dev/null 2>&1 || true
  claude plugin install humanizer@humanizer >/dev/null 2>&1 && echo "плагин humanizer: ok" || echo "WARN: humanizer не встал — поставится из settings при старте"
else
  echo "WARN: нет claude CLI — humanizer поставится из settings при старте"
fi

echo "OK: харнес в $C, рабочая папка ~/Blog. Открой новую сессию."
