# Свежая позиция Anthropic по авторингу инструкций (замер 27.07.2026)

Только первоисточники Anthropic. Страницы docs не имеют штампа даты — датирую по релизу модели, к которой привязан текст (даты взяты из `platform.claude.com/docs/en/release-notes/overview` и changelog Claude Code).

## 1. Найденные свежие источники

| Документ | Дата | URL | Суть одной строкой |
|---|---|---|---|
| Prompting Claude Fable 5 | 09.06.2026 (релиз Fable 5) | platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5 | Главный источник фразы «too prescriptive»; целая секция scaffolding-изменений |
| Prompting Claude Opus 5 | 24.07.2026 (релиз Opus 5) | platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5 | Удалить verification-инструкции, ограничить scope и субагентов, явно просить краткость |
| What's new in Claude Opus 5 | 24.07.2026 | platform.claude.com/docs/en/about-claude/models/whats-new-opus-5 | Те же поведенческие дельты + API-изменения |
| Migration guide (Opus 4.8 → Opus 5) | 24.07.2026 | platform.claude.com/docs/en/about-claude/models/migration-guide#migrating-to-claude-opus-5 | Пункт 6: «Remove carried-over verification instructions and constrain scope» |
| Prompting best practices (общий) | обновлён ≥24.07.2026 (перечисляет Fable 5 / Opus 5 / Sonnet 5) | platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices | «Prefer general instructions over prescriptive steps», «Remove over-prompting» |
| Prompting Claude Sonnet 5 | 30.06.2026 (релиз Sonnet 5) | platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5 | Модель сама гоняет self-verification loops; в code review просить полноту, фильтровать отдельно |
| Claude Platform release notes | записи 01.05–24.07.2026 | platform.claude.com/docs/en/release-notes/overview | Даты релизов Fable 5 / Sonnet 5 / Opus 5 |
| Claude Code changelog | записи 01.05–25.07.2026 | code.claude.com/docs/en/changelog | v2.1.206 (09.07): `/doctor` предлагает резать CLAUDE.md; v2.1.215 (19.07): Клод больше не запускает `/verify` и `/code-review` сам |

**НЕ найдено:**
- Отдельного гайда по авторингу *скиллов* под новые модели — нет. `agents-and-tools/agent-skills/best-practices` не упоминает ни Fable 5, ни Opus 5 (0 совпадений на 27.07.2026): страница не обновлялась под новое поколение.
- `code.claude.com/docs/en/best-practices` и `.../skills` — те же 0 упоминаний новых моделей.
- Постов anthropic.com/engineering за май–июль 2026 нет вообще: свежайший — 23.04.2026 «An update on recent Claude Code quality reports». Гайд claude.com/blog/best-practices-for-prompt-engineering датирован 10.11.2025 (старее нашего текущего ресёрча).
- Страницы docs-changelog / whats-new-fable-5 не существуют (404).

## 2. «Too prescriptive» — расшифровка

Первоисточник — секция **Recommended scaffolding changes** гайда Fable 5 (09.06.2026), дословно:

> **Refactor existing prompts and skills.** Skills developed for prior models are often too prescriptive for Claude Fable 5 and can degrade output quality. Review and consider removing older instructions if default performance is better. Claude Fable 5 also does a good job of updating skills on the fly based on what it learns from the task at hand.

Что именно объявлено «too prescriptive» — по конкретным секциям тех же документов:

1. **Перечисление каждого поведения по имени.** Fable 5, «Strong instruction following»: «Instruction-following is improved enough that you can steer most behaviors with a brief instruction rather than enumerating each behavior by name.» И там же про конкретный список паттернов многословия: «A short brevity instruction is as effective as listing each pattern». Про чекпойнты: «there is no need to enumerate every case».
2. **Пошаговый план вместо цели.** Общий best-practices: «**Prefer general instructions over prescriptive steps.** A prompt like "think thoroughly" often produces better reasoning than a hand-written step-by-step plan. Claude's reasoning frequently exceeds what a human would prescribe.»
3. **Инструкции верификации и перепроверки.** Opus 5, «Task scope and over-verification»: «If your prompt contains explicit verification instructions ("include a final verification step for any non-trivial task," "use a subagent to verify"), remove them: instructions like these cause over-verification on Claude Opus 5, and removing them reduces wasted tokens with no loss in quality. The same applies to legacy harness scaffolding that adds separate verification steps.» Opus 5, «Self-correction»: «Avoid instructing re-checks it already performs ("double-check your answer," "re-verify before responding"); like verification instructions, these compound with the model's own behavior and add cost without improving results.»
4. **Формулировки через запрет вместо образца.** Opus 5, «User-facing progress updates»: «Positive examples of the communication style you want tend to be more effective than instructions about what not to do.» Там же, про XML-теги: «Instructions that call out thinking tags by name are less effective than the general form, so avoid naming them specifically.»
5. **Страховочные «на всякий случай» вокруг тулов.** Общий best-practices: «**Remove over-prompting.** Tools that undertriggered in previous models are likely to trigger appropriately now. Instructions like "If in doubt, use [tool]" will cause overtriggering.» И рядом: «**Replace blanket defaults with more targeted instructions.**»
6. **Консервативные фильтры внутри задачи.** Opus 5, «Capability improvements»: «If your review prompt says "only report high-severity issues" or "be conservative," the model may follow that instruction literally and report less; ask it to report everything and filter in a separate pass instead.»
7. **Требование показать рассуждения — теперь опасно.** Fable 5: «**Don't instruct Claude to reproduce its reasoning in the response.** Prompts, skills, or harness instructions that tell the model to echo, transcribe, or explain its internal reasoning as response text can trigger the `reasoning_extraction` refusal category… Audit existing skills and system prompts for reflection or show-your-thinking instructions when migrating.»

**Что рекомендуется вместо** (дословно): цель + причина + границы + способ проверки.
- Причина: Fable 5, «Give the reason, not only the request»: «Claude Fable 5 tends to perform better when it understands the intent behind a request: context lets it connect the task to relevant information rather than inferring intent on its own.» Общий best-practices, «Add context to improve performance»: «Claude is smart enough to generalize from the explanation.»
- Границы: Fable 5, «State the boundaries»: «Define explicit constraints on what Claude Fable 5 should and should not do.» Opus 5: «For narrow tasks, constrain scope explicitly.»
- Заземление на факты вместо процедур: Fable 5, «Ground progress claims during long runs»: «Before reporting progress, audit each claim against a tool result from this session… In Anthropic's testing, this nearly eliminated fabricated status reports.»
- Метод удаления: «Review and consider removing older instructions **if default performance is better**» (Fable 5) — то есть снимать и замерять, а не выбрасывать пачкой.

**Важное расхождение между моделями, его нельзя сглаживать.** Fable 5 (09.06.2026) советует верификаторов: «Separate, fresh-context verifier subagents tend to outperform self-critique». Opus 5 (24.07.2026) — обратное, в sample-промпте: «do not use subagents to verify or double-check your own work». Правило зависит от модели главного цикла, а не универсально.

## 3. Что изменилось против старых рекомендаций

| Раньше советовали | Теперь | Дата · источник |
|---|---|---|
| «Ask Claude to self-check»: «Before you finish, verify your answer against [test criteria]» | На Opus 5 — удалить, а не переписать: «remove these instructions rather than rewriting them» | 24.07.2026 · claude-prompting-best-practices (секция Thinking) + prompting-claude-opus-5 |
| Перечислять в скилле каждый нежелательный паттерн | Одна короткая инструкция даёт тот же эффект | 09.06.2026 · prompting-claude-fable-5 |
| Прописывать пошаговый план рассуждения | «Prefer general instructions over prescriptive steps» | ≥24.07.2026 · claude-prompting-best-practices |
| «Default to using [tool]» / «If in doubt, use [tool]» | Убрать: вызовет overtriggering; заменить на условие «when it would…» | ≥24.07.2026 · claude-prompting-best-practices |
| Просить в ревью «только высокую критичность» | Просить полноту, фильтровать отдельным проходом | 24.07.2026 · prompting-claude-opus-5 |
| Просить модель показать/объяснить своё рассуждение в ответе | Запрещено: триггерит `reasoning_extraction` refusal на Fable 5 | 09.06.2026 · prompting-claude-fable-5 |
| Effort как рычаг длины ответа | Effort меняет объём мышления, не длину ответа: длину просить словами | 24.07.2026 · prompting-claude-opus-5 + build-with-claude/effort |
| Клод сам запускал `/verify` и `/code-review` | Больше не запускает сам — только по явному вызову | 19.07.2026 · changelog Claude Code v2.1.215 |

## 4. Что НЕ изменилось (подтверждено и в свежих источниках)

- **SKILL.md ≤500 строк** — формулировка «Keep SKILL.md body under 500 lines for optimal performance» стоит и в `agent-skills/best-practices`, и в `code.claude.com/docs/en/skills` (проверено 27.07.2026).
- **Лимиты frontmatter:** `name` ≤64 символов, `description` ≤1024 символов, description = что делает + когда звать. Без изменений.
- **Progressive disclosure** — по-прежнему основной механизм: SKILL.md как оглавление, детали в отдельных файлах.
- **Короткий CLAUDE.md** — «Bloated CLAUDE.md files cause Claude to ignore your actual instructions!» и «For each line, ask: "Would removing this cause Claude to make mistakes?" If not, cut it» (code.claude.com/docs/en/best-practices). Усилено машинно: `/doctor` с 09.07.2026 сам предлагает резать CLAUDE.md.
- **Degrees of freedom** — low freedom (точные команды, «Do not modify the command») всё ещё явно рекомендован для хрупких и необратимых операций (`agent-skills/best-practices`). Отмены нет.
- **Верифицируемость как таковая** — не отменена: code.claude.com/docs/en/best-practices по-прежнему требует «Give Claude a way to verify its work» (тесты, скриншоты, evidence). Отменены *текстовые инструкции «перепроверь»*, а не наличие проверяемого критерия.
- **Один дефолт вместо списка вариантов** — «Avoid offering too many options» на месте.

## 5. Приговор нашим правилам

1. **Таблица лимитов по жанрам — оставить, но честно разделить происхождение.** Anthropic подтверждает только ≤500 строк для SKILL.md и «короче = выше adherence» для CLAUDE.md. Остальные цифры (≤1400 слов CLAUDE.md, ≤120 строк агент, ≤60 спека) — наши эвристики, в первоисточниках не найдены. Вреда нет, но выдавать их за правило Anthropic нельзя.
2. **«Пиши ЧТО делать, а не почему» — устарело, менять.** Прямо противоречит Fable 5 («Give the reason, not only the request») и общему best-practices («Claude is smart enough to generalize from the explanation»). Экономить надо на нарративе-истории («как я до этого додумался»), а причину-intent в одну строку — писать.
3. **Длинные списки анти-паттернов с ❌ — сокращать.** «Positive examples… more effective than instructions about what not to do» (Opus 5) + «A short brevity instruction is as effective as listing each pattern» (Fable 5). Наш п.5 «Запрет там, где нужен рецепт» правильный — его надо распространить на сам список анти-паттернов, а не держать список из восьми запретов.
4. **Императив — оставить как есть.** Ни одного свежего источника против императивной формы не найдено; сами гайды Anthropic написаны императивом.
5. **Пре-сейв валидатор — разделить надвое.** Скрипт `check_md.py` как детерминированный гейт остаётся (docs явно противопоставляют детерминированные проверки advisory-инструкциям). А вот текстовое требование модели «обязательно прогони проверку перед сохранением» — ровно тот класс, который Opus 5 велит удалять. Проверка должна висеть на хуке/скрипте, а не на строчке в скилле.
6. **Пошаговые процедуры (такты 1–8) — главный кандидат на переписывание.** Это и есть «too prescriptive» в чистом виде. Оставлять точный порядок только там, где шаг хрупкий или необратимый (миграции, конкретные команды) — low freedom для этого не отменён. Всё остальное → цель + границы + критерий готовности.
7. **Добавить недостающее правило: аудит на «покажи рассуждения».** Любые формулировки вида «объясни ход мысли в ответе» в скиллах и агентах надо вычистить — на Fable 5 это триггерит refusal `reasoning_extraction` и роняет прогон в fallback.
8. **Наш п.6 «Смена поколения модели → пересмотреть инструкции, снимая по одной» — подтверждён дословно** («Review and consider removing older instructions if default performance is better»). Единственное уточнение: правила про верификацию и субагентов зависят от модели цикла — на Opus 5 их удаляют, на Fable 5 верификаторы-субагенты, наоборот, рекомендованы.

## 6. Дополнение 02.09.2026 — Fable 5.1 стала моделью главного цикла

| Документ | Дата | URL | Суть одной строкой |
|---|---|---|---|
| Prompting Claude Fable 5.1 | 01.09.2026 | platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1 | Эффорт-свип с high; verification-инструкции ОСТАВИТЬ (правило Opus 5 не применяется); де-прескрайб; батчинг; меньше нарратива и форматирования |
| What's new in Claude Fable 5.1 | 01.09.2026 | platform.claude.com/docs/en/models/fable-5-1/whats-new-fable-5-1 | Поведенческие дельты от Fable 5, кэш ×4 дешевле, per-message effort |
| Effort | ≥01.09.2026 | platform.claude.com/docs/en/build-with-claude/effort | high дефолт; max — без лимита токенов; xhigh — долгие прогоны |
| Claude Code model-config | ≥01.09.2026 | code.claude.com/docs/en/model-config | Порядок разрешения эффорта: env/--effort//effort → hold (не у 5.1) → settings → дефолт high; max в settings не принимается |

Расхождение из §2 закрыто для нашей связки: главный цикл Fable 5.1 — инструкции «проверь прогоном» остаются; пакеты implementer (Opus 5) — без верификационных лесов. Claude Code 2.1.258 вшивает патчи 5.1 (progress-line, автономия, delivering work, батчинг) в системный промпт — в харнесе их не дублировать. Один дом правила — Skill `harness`, раздел «Модели».
