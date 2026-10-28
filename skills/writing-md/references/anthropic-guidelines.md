# Anthropic 2026: авторинг инструкций для агентов + дизайн флоу (только первоисточники)

Собрано 2026-07-27. Ключи источников (полные URL — здесь, дальше по ключу):
[BP] https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (был docs.claude.com, 302→platform) ·
[OV] https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview ·
[CCS] https://code.claude.com/docs/en/skills ·
[CCM] https://code.claude.com/docs/en/memory ·
[CCSA] https://code.claude.com/docs/en/sub-agents ·
[CCFO] https://code.claude.com/docs/en/features-overview ·
[REPO] https://github.com/anthropics/skills · [SPEC] https://agentskills.io/specification ·
[STEER] https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more ·
далее всё на https://www.anthropic.com/engineering/ : [CCBP] claude-code-best-practices ·
[BEA] building-effective-agents (Dec 19, 2024) · [CE] effective-context-engineering-for-ai-agents (Sep 29, 2025) ·
[MAS] multi-agent-research-system (Jun 13, 2025) · [SK] equipping-agents-for-the-real-world-with-agent-skills (Oct 16, 2025, upd Dec 18, 2025) ·
[HD] harness-design-long-running-apps (Mar 24, 2026) · [MA] managed-agents (Apr 08, 2026)

## 1. Авторинг SKILL.md — правила

1. Контекст — общий ресурс, а не твой: «The context window is a public good.» [BP]
2. Считай Claude умным по умолчанию: «**Default assumption:** Claude is already very smart» / «Only add context Claude doesn't already have.» [BP]
3. Гейт на каждый абзац: «"Does this paragraph justify its token cost?"» [BP]
4. Степень свободы = хрупкость задачи: «Match the level of specificity to the task's fragility and variability.» [BP]
5. Жёстко предписывай только на «узком мосту»: «**Narrow bridge with cliffs on both sides:** There's only one safe way forward.» [BP]
6. Тело ≤500 строк: «Keep SKILL.md body under 500 lines for optimal performance» [BP]; «Keep `SKILL.md` under 500 lines. Move detailed reference material to separate files.» [CCS]
7. Ссылки на файлы — один уровень: «**Keep references one level deep from SKILL.md**. All reference files should link directly from SKILL.md» [BP]
8. Reference >100 строк → оглавление: «For reference files longer than 100 lines, include a table of contents at the top.» [BP]
9. Имена — герундий: «Consider using **gerund form** (verb + -ing) for Skill names» [BP]
10. Одна терминология: «Choose one term and use it throughout the Skill» / «Consistency helps Claude parse and follow instructions.» [BP]
11. Сложный воркфлоу → чеклист внутрь скилла: «provide a checklist that Claude can copy into its response and check off as it progresses.» [BP]
12. Петля валидации сильнее прозы: «**Common pattern:** Run validator → fix errors → repeat / This pattern greatly improves output quality.» [BP]
13. В Claude Code тело скилла — ПОВТОРЯЮЩАЯСЯ трата: «Once a skill loads, its content stays in context across turns, so every line is a recurring token cost. State what to do rather than narrating how or why» [CCS]
14. Тесты: evals ПЕРЕД текстом — «**Create evaluations BEFORE writing extensive documentation.**» + «At least three evaluations created», «Tested with Haiku, Sonnet, and Opus» [BP]
15. Схема тестирования: «Work with one instance of Claude ("Claude A") to create a Skill that is used by other instances ("Claude B")» [BP]
16. Скилл «как писать скиллы» НЕ нужен: «You don't need special system prompts or a "writing skills" skill to get Claude to help create Skills.» [BP]
17. Наблюдай за реальным использованием, а не за гипотезами: «Iterate based on these observations rather than assumptions.» [BP]
18. Формально скилл прост: «Skills are a simple concept with a correspondingly simple format.» [SK]

## 2. Frontmatter: поля, обязательность, лимиты

| Поле | Обязательно? | Лимит | Назначение / источник |
|---|---|---|---|
| `name` | API/спека: ДА; Claude Code: НЕТ | ≤64 симв., только lowercase/цифры/дефис, без XML-тегов, без слов «anthropic»/«claude» | [BP][OV]. В CC: «Display name shown in skill listings. Defaults to the directory name.» — «All fields are optional. Only `description` is recommended» [CCS] |
| `description` | API: ДА (non-empty); CC: «Recommended» | API: ≤1024 симв.; CC: `description`+`when_to_use` обрезаются на 1536 симв. в листинге | «The `description` field enables Skill discovery and should include both what the Skill does and when to use it.» [BP]; «Put the key use case first» [CCS] |
| `when_to_use` | Нет (только Claude Code) | входит в тот же кап 1536 | «trigger phrases or example requests» [CCS] |
| `allowed-tools` / `disallowed-tools` | Нет | — | пре-апрув / запрет тулов на ход инвокации [CCS] |
| `disable-model-invocation` | Нет (default `false`) | — | «Use for workflows you want to trigger manually» — deploy/commit [CCS] |
| `user-invocable` | Нет (default `true`) | — | спрятать из `/`-меню (фоновые знания) [CCS] |
| `model` / `effort` | Нет | effort: low/medium/high/xhigh/max | оверрайд на время активности скилла [CCS] |
| `context: fork` / `agent` / `background` | Нет | — | запуск скилла в субагенте [CCS] |
| `paths` | Нет | бюджет 1000 развёрнутых паттернов / 4 MiB | автозагрузка только при работе с матчащими файлами [CCS] |
| `argument-hint`, `arguments`, `hooks`, `shell` | Нет | — | [CCS] |

Спека Agent Skills переехала: «The spec is now located at <https://agentskills.io/specification>» [REPO/spec]. В шаблоне репо ровно два поля: «The frontmatter requires only two fields: `name` … `description`» [REPO].

## 3. Прогрессивное раскрытие и длина

- Три уровня и их цена: L1 метаданные — «Always (at startup)», «~100 tokens per Skill»; L2 тело SKILL.md — «When Skill is triggered», «**Under 5k tokens**»; L3 ресурсы — «As needed», «None until accessed» [OV].
- Бандл практически безлимитен: «**No practical limit on bundled content:** Files don't consume context until accessed» [OV]; «the amount of context that can be bundled into a skill is effectively unbounded» [SK].
- Когда выносить: «Split content into separate files when approaching this limit» (500 строк) [BP]; «If certain contexts are mutually exclusive or rarely used together, keeping the paths separate will reduce the token usage.» [SK].
- Разделяй по доменам, а не по «доп. материалам»: «organize content by domain to avoid loading irrelevant context» [BP].
- Скрипты дешевле прозы: «Utility scripts can be executed through bash without loading their full contents into context. Only the script's output consumes tokens» [BP].
- Листинг скиллов в CC имеет бюджет: «if you have many skills, Claude Code shortens descriptions to fit the listing's character budget, which can strip the keywords Claude needs to match your request. The budget scales at 1% of the model's context window.» [CCS]
- После компакции: «keeping the first 5,000 tokens of each. Re-attached skills share a combined budget of 25,000 tokens … older skills can be dropped entirely after compaction if you have invoked many in one session.» [CCS]

## 4. description-поле — как писать, чтобы срабатывало

- Что + когда: «Include both what the Skill does and specific triggers/contexts for when to use it.» [BP]
- Только третье лицо: «**Always write in third person**. The description is injected into the system prompt, and inconsistent point-of-view can cause discovery problems.» [BP]
- Это единственный отбор среди сотни: «The description is critical for skill selection: Claude uses it to choose the right Skill from potentially 100+ available Skills.» [BP]
- Эталон: «description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.» [BP]
- Антиэталоны дословно: «Helps with documents», «Processes data», «Does stuff with files» [BP]
- name+description решают триггер: «Claude uses these when determining whether to trigger the Skill in response to the current task.» [BP]
- Ключевой кейс — первым: «Put the key use case first: the combined `description` and `when_to_use` text is truncated at 1,536 characters» [CCS]

## 5. Анти-паттерны авторинга

- Многословие/объяснение известного — «Bad example: Too verbose (approximately 150 tokens)» [BP]
- Много вариантов вместо дефолта — «**Avoid offering too many options** … "You can use pypdf, or pdfplumber, or PyMuPDF, or pdf2image, or…"» [BP]
- Вложенные ссылки (файл→файл→файл) — «Claude may partially read files when they're referenced from other referenced files … resulting in incomplete information.» [BP]
- Время-зависимые формулировки — «Don't include information that will become outdated» [BP]
- Windows-пути — «Always use forward slashes in file paths, even on Windows» [BP]
- «Voodoo constants» — «If you don't know the right value, how will Claude determine it?» [BP]
- Скрипт, который сваливает ошибку на Claude — «**Solve, don't defer**» [BP]
- Допущение, что пакет установлен — «**Avoid assuming tools are installed**» [BP]
- Короткие имена MCP-тулов — «always use fully qualified tool names to avoid "tool not found" errors» [BP]
- Расплывчатые имена скиллов — «Vague names: `helper`, `utils`, `tools`» [BP]
- Раздутый CLAUDE.md — «**Bloated CLAUDE.md files cause Claude to ignore your actual instructions!**» [CCBP]
- Процедура внутри CLAUDE.md — «If an entry is a multi-step procedure or only matters for one part of the codebase, move it to a skill or a path-scoped rule instead.» [CCM]
- Противоречащие правила — «if two rules contradict each other, Claude may pick one arbitrarily.» [CCM]

## 6. Дизайн флоу: за простоту

- Базовый принцип: «find the simplest solution possible, and only increasing complexity when needed» и «you should consider adding complexity **only** when it demonstrably improves outcomes.» [BEA]
- «When implementing agents, we try to follow three core principles: Maintain **simplicity** in your agent's design.» [BEA]
- Один судья бьёт много судей: «We experimented with multiple judges to evaluate each component, but found that **a single LLM call with a single prompt** outputting scores from 0.0-1.0 and a pass-fail grade **was the most consistent and aligned with human judgements**.» [MAS]
- Переусложнение оркестрации — задокументированный фейл: «Early agents made errors like spawning 50 subagents for simple queries» [MAS]
- Масштабируй усилие под сложность: «Simple fact-finding requires just 1 agent with 3-10 tool calls … These explicit guidelines … prevent overinvestment in simple queries, which was a common failure mode in our early versions.» [MAS]
- Цена мультиагента: «multi-agent systems use about 15× more tokens than chats. For economic viability, multi-agent systems require tasks where the value of the task is high enough» и «most coding tasks involve fewer truly parallelizable tasks than research» [MAS]
- Лестница верификации (4 ступени, «Each step trades setup for attention»): в промпте → `/goal`-условие → Stop-хук → «**By a second opinion**: a verification subagent … has a fresh model try to refute the result, so the agent doing the work isn't the one grading it.» [CCBP] — второе мнение ОДНО, и это самая дорогая ступень.
- Проверка должна быть машинной, а не «на глаз»: «Give Claude something that produces a pass or fail, and the loop closes on its own.» [CCBP]
- Отдельный судья оправдан — но не всегда: «Separating the agent doing the work from the agent judging it proves to be a strong lever» [HD], И ЖЕ: «for tasks within that boundary, **the evaluator became unnecessary overhead**. But for the parts of the build that were still at the edge of the generator's capabilities, the evaluator continued to give real lift. **The practical implication is that the evaluator is not a fixed yes-or-no decision. It is worth the cost when the task sits beyond what the current model does reliably solo.**» [HD]
- Самооценка не работает — но и судья по умолчанию мягок: «agents tend to respond by confidently praising the work»; «Out of the box, Claude is a poor QA agent. In early runs, I watched it identify legitimate issues, then talk itself into deciding they weren't a big deal and approve the work anyway.» [HD]
- Критерии важнее судьи: «"Is this design beautiful?" is hard to answer consistently, but "does this follow our principles for good design?" gives Claude something concrete to grade against.» [HD]
- Как чистить харнес: «every component in a harness encodes an assumption about what the model can't do on its own, and those assumptions are worth stress testing … they can quickly go stale as models improve»; метод — «removing one component at a time and reviewing what impact it had on the final result» [HD]
- Когда субагент НЕ нужен (использовать основной диалог): «The task needs frequent back-and-forth or iterative refinement / Multiple phases share significant context / You're making a quick, targeted change / Latency matters. Subagents start fresh and may need time to gather context» [CCSA]
- Когда субагент нужен: «The task produces verbose output you don't need in your main context / You want to enforce specific tool restrictions / The work is self-contained and can return a summary» [CCSA]; веер судей стоит контекста: «Running many subagents that each return detailed results can consume significant context.» [CCSA]
- Контекст: «good context engineering means finding the smallest possible set of high-signal tokens that maximize the likelihood of some desired outcome» и «right altitude … Goldilocks zone»: с одной стороны «hardcoding complex, brittle logic in their prompts … creates fragility and increases maintenance complexity», с другой — «vague, high-level guidance» [CE]
- Субагент возвращает сжатое: «returns only a condensed, distilled summary of its work (often 1,000-2,000 tokens)» [CE]

## 7. Что нового за 2026

- **Mar 24, 2026 [HD]** — единственный пост Anthropic прямо про generator/evaluator-лупы: 3-агентная схема planner→generator→evaluator; с Opus 4.6 автор УБРАЛ спринт-декомпозицию и свёл evaluator к одному проходу в конце вместо оценки каждого спринта; харнес «was over 20x more expensive»; «5 to 15 iterations» — только для субъективного фронтенд-дизайна, не для кода.
- **Apr 08, 2026 [MA]** — та же мысль про устаревание лесов: context resets, добавленные под Sonnet 4.5, на Opus 4.5 «had become dead weight». Вывод: «when a new model lands, it is generally good practice to re-examine a harness, stripping away pieces that are no longer load-bearing» [HD].
- **Claude Code v2.1.215** — `/verify` и `/code-review` больше НЕ запускаются моделью самостоятельно: «run only when you invoke them, which keeps you in control of when these longer-running checks spend time and tokens. Before v2.1.215, Claude could also run `/verify` and `/code-review` on its own.» [CCS] — вендор сам убрал автогейты.
- Спека Agent Skills вынесена в открытый стандарт agentskills.io [REPO][SPEC]; кастомные команды слиты со скиллами: «Custom commands have been merged into skills.» [CCS]
- Дока переехала: docs.claude.com/en/docs/agents-and-tools/... → platform.claude.com/docs/en/agents-and-tools/... (302).
- Новые ручки под «много скиллов»: `skillListingBudgetFraction`, `skillListingMaxDescChars`, `skillOverrides: "name-only"` [CCS].
- Не найдено: официального лимита на число скиллов, рекомендации «N судей», рубрик судейства, guidance про «раунды до планки» вне [HD].

## 8. Конфликты с нашим флоу

1. **Глобальный CLAUDE.md 20KB.** Anthropic: «**Size**: target under 200 lines per CLAUDE.md file. Longer files consume more context and reduce adherence.» [CCM]; «Keep CLAUDE.md under 200 lines, give it an owner, and review changes to it like code» [STEER]; и прямой диагноз нашего симптома: «If Claude keeps doing something you don't want despite having a rule against it, the file is probably too long and the rule is getting lost.» [CCBP]. 20KB ≈ 10× планки.
2. **Процедуры (конвейер, кворум, ralph-цикл, роутинг) живут в CLAUDE.md.** «CLAUDE.md is loaded every session, so only include things that apply broadly. For domain knowledge or workflows that are only relevant sometimes, use skills instead. Claude loads them on demand without bloating every conversation.» [CCBP]; «Instructions that are procedural … belong in a skill rather than in CLAUDE.md.» [STEER]
3. **30 скиллов.** Их описания молча режутся: «if you have many skills, Claude Code shortens descriptions … which can strip the keywords Claude needs to match your request» [CCS] — то есть часть наших скиллов, скорее всего, уже не триггерится по задуманным словам. Проверяемо через `/doctor` и `/context` [CCS].
4. **2 независимых судьи на UI-задачу.** Единственный замер Anthropic на эту тему говорит обратное: «a single LLM call with a single prompt … was the most consistent and aligned with human judgements» [MAS]. Панель из двух судей у Anthropic нигде не рекомендована — не найдено.
5. **2 круга/итерации как дефолт.** [HD] прямо: evaluator — «not a fixed yes-or-no decision», он окупается только когда задача «sits beyond what the current model does reliably solo»; иначе — «unnecessary overhead». Наш «конвейер + judge-панель для любого существенного UI» фиксирует то, что Anthropic сделал переменным.
6. **Единый режим исполнения для всех задач.** [MAS]: «Scale effort to query complexity … prevent overinvestment in simple queries, which was a common failure mode in our early versions.» Наш кворум-по-риску это частично ловит, но judge-панель объявлена ДЕФОЛТОМ, а не функцией сложности.
7. **Правила-простыни вместо проверяемых критериев.** [CE] называет наш стиль одним из двух провалов: «hardcoding complex, brittle logic in their prompts to elicit exact agentic behavior. This approach creates fragility and increases maintenance complexity over time.» Рабочая замена — критерии, по которым можно грейдить ([HD]: «does this follow our principles for good design?»), и pass/fail-чек ([CCBP]).
8. **Леса не пересматриваются при смене модели.** Мы обновили роутинг под Opus 5, но структуру гейтов оставили. [HD]/[MA]: компоненты харнеса «encode an assumption about what the model can't do on its own» и «can quickly go stale as models improve»; метод — снимать по одному компоненту и мерить.
