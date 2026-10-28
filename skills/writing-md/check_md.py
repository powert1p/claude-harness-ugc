#!/usr/bin/env python3
"""Пре-сейв гейт для md, которые читает модель.

Использование:  python3 check_md.py <файл> [<файл> ...]
Выход: 0 — всё чисто, 1 — есть FAIL. WARN не валит прогон.

Жанр определяется по пути. Лимиты — из доки Anthropic (SKILL.md ≤500 строк,
CLAUDE.md ≤200) и из замера здоровых жанров нашей среды (память/vault/карточки ≈300 слов).
"""
import re
import sys
from pathlib import Path

# жанр: (регексп пути, лимит строк, лимит слов, нужен ли frontmatter)
GENRES = [
    ("skill",     r"skills/[^/]+/SKILL\.md$",        500, 3500, True),
    ("claude_md", r"CLAUDE\.md$",                    200, 1400, False),
    ("rules",     r"/rules/[^/]+\.md$",              100,  700, False),
    ("agent",     r"/agents/[^/]+\.md$",             120,  600, True),
    ("spec",      r"/specs?/[^/]+\.md$",              60,  900, False),
    ("card",      r"/backlog/[^/]+\.md$",             40,  400, True),
    ("memory",    r"/memory/(?!MEMORY\.md)[^/]+\.md$", 30,  400, True),
    ("vault",     r"/permanent/[^/]+/[^/]+\.md$",     30,  400, False),
    ("doc",       r"\.md$",                          300, 2500, False),
]

# поля frontmatter, разрешённые в SKILL.md (allowlist Claude Code)
SKILL_FIELDS = {
    "name", "description", "when_to_use", "allowed-tools", "disallowed-tools",
    "disable-model-invocation", "user-invocable", "model", "effort", "context",
    "paths", "argument-hint", "arguments", "hooks", "shell", "license",
    "metadata", "compatibility", "triggers", "isolation", "memory", "background",
}

FIRST_PERSON = re.compile(r"^\s*(ты\b|вы\b|you\b|i\b|я\b|мы\b|we\b)", re.I)


def genre_of(path: str):
    # жанр ищем по АБСОЛЮТНОМУ пути: относительный «SKILL.md» иначе уедет в «doc»
    full = str(Path(path).expanduser().resolve())
    for name, pattern, max_lines, max_words, needs_fm in GENRES:
        if re.search(pattern, full):
            return name, max_lines, max_words, needs_fm
    return "doc", 300, 2500, False


def yaml_safe(raw: str):
    """Незакавыченный скаляр с двоеточием ломает YAML — Claude Code стерпит, спека нет."""
    bad = []
    for line in raw.split("\n"):
        m = re.match(r"^([A-Za-z_-]+):\s+(.*)$", line)
        if m and m.group(2) and m.group(2)[0] not in "\"'>|[{":
            if re.search(r":\s", m.group(2)):
                bad.append(m.group(1))
    return bad


def frontmatter(text: str):
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        return None, text, []
    body = text[m.end():]
    broken = yaml_safe(m.group(1))
    fields = {}
    for line in m.group(1).split("\n"):
        fm = re.match(r"^([A-Za-z_-]+):\s*(.*)$", line)
        if fm:
            fields[fm.group(1)] = fm.group(2).strip()
    return fields, body, broken


def check(path: Path):
    fails, warns = [], []
    text = path.read_text(errors="ignore")
    genre, max_lines, max_words, needs_fm = genre_of(str(path))
    fields, body, yaml_broken = frontmatter(text)
    for field in yaml_broken:
        fails.append(f"поле «{field}» содержит незакавыченное двоеточие — frontmatter не парсится как YAML, закавычь значение")

    lines = len(body.strip().split("\n"))
    words = len(body.split())
    if lines > max_lines:
        fails.append(f"длина {lines} строк > лимита {max_lines} для жанра «{genre}» — вынеси детали в отдельный файл")
    elif lines > max_lines * 0.8:
        warns.append(f"длина {lines} строк — подходит к лимиту {max_lines}")
    if words > max_words:
        fails.append(f"объём {words} слов > лимита {max_words} для жанра «{genre}»")

    if needs_fm and fields is None:
        fails.append("нет frontmatter, а жанр его требует")

    if fields:
        desc = fields.get("description", "")
        if genre in ("skill", "agent"):
            if not desc:
                fails.append("пустой description — по нему модель выбирает скилл среди сотни")
            else:
                if len(desc) > 1024:
                    fails.append(f"description {len(desc)} симв. > 1024 (лимит API)")
                elif len(desc) + len(fields.get("when_to_use", "")) > 1536:
                    warns.append("description + when_to_use > 1536 симв. — хвост обрежется в листинге")
                if len(desc) < 80:
                    warns.append(f"description {len(desc)} симв. — короткий, может не сматчиться на запрос")
                if FIRST_PERSON.match(desc):
                    fails.append("description от первого/второго лица — Anthropic требует третье")
                if not re.search(r"use when|когда|use if|срабатыв", desc, re.I):
                    warns.append("в description нет условия срабатывания («Use when …» / «когда …»)")
        if genre == "skill":
            unknown = set(fields) - SKILL_FIELDS
            if unknown:
                fails.append(f"неизвестные поля frontmatter: {', '.join(sorted(unknown))} — молча игнорируются")

    if "@" in body:
        for hit in re.findall(r"(?<![\w`])@[\w./-]+\.md", body):
            fails.append(f"ссылка «{hit}» форс-грузится в контекст — используй обычный путь")

    refs = re.findall(r"[`(\[]([^`()\[\]\s]+\.md)[`)\]]", body)
    for ref in set(refs):
        # шаблоны-плейсхолдеры путями не являются
        if ref.startswith(("http", "#")) or re.search(r"[<>{}*]|YYYY|<N>|\bN\b", ref):
            continue
        target = (path.parent / ref).resolve()
        if not target.exists() and not Path(ref.replace("~", str(Path.home()))).exists():
            warns.append(f"путь «{ref}» не существует — битая ссылка или файл переехал")
        elif target.exists() and target.suffix == ".md":
            nested = re.findall(r"[`(\[]([^`()\[\]\s]+\.md)[`)\]]", target.read_text(errors="ignore"))
            if [n for n in nested if not n.startswith(("http", "#"))]:
                warns.append(f"«{ref}» сам ссылается на другие md — вложенность >1 уровня читается частично")

    return genre, lines, words, fails, warns


def main(argv):
    if not argv:
        print(__doc__)
        return 1
    bad = 0
    for arg in argv:
        p = Path(arg).expanduser()
        if not p.exists():
            print(f"✗ {arg}: файла нет")
            bad = 1
            continue
        genre, lines, words, fails, warns = check(p)
        mark = "✗ FAIL" if fails else ("~ WARN" if warns else "✓ PASS")
        print(f"{mark}  {p.name}  [{genre}]  {lines} строк / {words} слов")
        for f in fails:
            print(f"    FAIL: {f}")
        for w in warns:
            print(f"    warn: {w}")
        if fails:
            bad = 1
    return bad


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
