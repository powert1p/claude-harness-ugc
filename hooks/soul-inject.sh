#!/bin/bash
# soul-inject.sh — SessionStart hook.
# Кладёт SOUL.md и USER.md одним блоком в начало сессии.
# Плюс два флага: USER.md не заполнен → онбординг; синк упал на конфликте → починить.
# Fail-open: любая ошибка → тихий exit 0, хук не роняет сессию.
set -uo pipefail

C="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
mkdir -p "$C/logs" 2>/dev/null
exec 2>>"$C/logs/soul-inject.log"

/usr/bin/python3 - "$C" <<'PY' || exit 0
import sys, json, pathlib

c = pathlib.Path(sys.argv[1])
# Потолок stdout хука ~10000 символов; режем по строкам, чтобы JSON не битый
CAP = 9000

parts = []
for name, title in (("SOUL.md", "Характер и голос"), ("USER.md", "Владелица — кто она")):
    p = c / name
    if p.is_file():
        body = p.read_text(encoding="utf-8", errors="ignore").strip()
        if body:
            parts.append("### %s\n%s" % (title, body))

notes = []
user = c / "USER.md"
if user.is_file() and "ONBOARDING: pending" in user.read_text(encoding="utf-8", errors="ignore"):
    notes.append(
        "### Первая встреча\n"
        "USER.md ещё пустой. Первым ответом поздоровайся, скажи одной фразой, чем можешь помочь, "
        "и познакомься: по одному вопросу за раз, 5 вопросов максимум — имя; платформы и ниша; "
        "форматы роликов; бренды; какие тексты её бесят у AI. Ответы сразу записывай в USER.md, "
        "в конце удали строку-маркер ONBOARDING. Если она пришла с задачей — сначала задача, знакомство потом.")
if (c / "state" / "sync-conflict").exists():
    notes.append(
        "### Синк застрял\n"
        "Прошлый синк харнеса упал на конфликте (подробности — logs/sync.log). Молча, без вопросов к ней: "
        "в ~/.claude разреши конфликт git (её правки и правки Есета сохрани обе), закоммить, "
        "удали state/sync-conflict. Ей ничего не рассказывай, если всё получилось.")

if not parts and not notes:
    sys.exit(0)

ctx = "## Кто ты и с кем работаешь\n\n" + "\n\n".join(parts)
tail = ("\n\n" + "\n\n".join(notes)) if notes else ""
room = CAP - len(tail)
if len(ctx) > room:
    sys.stderr.write("[warn] soul clipped: %d > %d\n" % (len(ctx), room))
    out, n = [], 0
    for line in ctx.split("\n"):
        if n + len(line) + 1 > room:
            break
        out.append(line)
        n += len(line) + 1
    ctx = "\n".join(out)

print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart",
                                         "additionalContext": ctx + tail}},
                 ensure_ascii=False))
PY
exit 0
