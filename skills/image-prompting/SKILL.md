---
name: image-prompting
description: "Промпт для генерации картинок, который даёт нужный стиль с первого раза и держит его в серии. Use when — печётся иконка, предмет, обложка, персонаж или партия однотипных картинок через codex exec; и всегда перед печатью больше трёх штук. Не для правки готовых картинок и не для векторной графики руками."
---

# image-prompting — сначала узнай, КТО печёт

Замер kodi-web 30.07: пять заходов подряд дали разнобой (фотореализм, жёлто-малиновая
палитра, сине-бирюзовая без обводки) — ~50 картинок впустую. Четыре из пяти заходов
настраивались по докам **Gemini**. В логе `codex exec` стояло `provider: openai`:
печёт **OpenAI gpt-image-2**, Gemini не участвовал ни разу.

## Правило 0. Генератор определяется логом, а не памятью

`codex exec … >/dev/null` — работа вслепую: не видно ни провайдера, ни того, что
реально ушло в тул. Первый прогон новой партии идёт **с логом**, и в нём читаются
две вещи: строка `provider:` и встроенный скилл генерации.

```bash
codex exec … -- "$P" </dev/null >diag/codex.log 2>&1
grep -n -E 'provider:|image_gen|generate-batch' diag/codex.log | head
```

Правила промптинга берутся из скилла ЭТОГО генератора — `~/.codex/skills/.system/imagegen/`
(`SKILL.md`, `references/prompting.md`, `references/cli.md`), а не из доки модели,
которую ты предполагал.

⚠️ 02.09: в `~/.codex/config.toml` стоит модель `gpt-5.6-sol` — ChatGPT-аккаунт её не тянет (400 `not supported`),
а первый прогон висит 7 минут молча. 20.10: gpt-5.5 и gpt-6-astra тоже 400 на ChatGPT-входе — печатать с `-m gpt-5.6-terra -c 'model_reasoning_effort="low"'` (список — `~/.codex/models_cache.json`), ~1 мин на кадр, прозрачный фон — ~3,5 мин. Параллельные
`codex exec` — файл каждого брать из `~/.codex/generated_images/<session id из лога>/`, не `find -newer`
(три прогона отдали один и тот же файл).

## Правило 1. Между тобой и генератором стоит агент, и он дополняет

В скилле codex записано: **детальный промпт нормализуется без добавления, общий —
дополняется «tasteful detail» на усмотрение агента.** Отсюда весь разброс серии:
`warm saturated palette` — приглашение дополнить, и каждый вызов дополнял по-своему.

Лечится не запретом, а **отсутствием пустых мест**: чем полнее спека, тем меньше
поводов её дополнять. Полезно и прямое «Pass the specification below to the image
tool as-is — it is already a complete spec».

## Правило 2. Короткие помеченные строки, не абзац

Их дока: «For complex requests, use short labeled lines instead of one long
paragraph», порядок — `scene/backdrop → subject → key details → constraints → output intent`.

```
Image 1: style reference. Reproduce its drawing style exactly.
STYLE: flat vector sticker illustration, every shape one solid flat colour,
       uniform dark-brown outline, even flat lighting.
PALETTE: orange #FF8C00, muted green #7FB693, outline #3B2314, background #FFFFFF.
         These four colours only.
SUBJECT: a round cherry pie with one slice lifted away from the rest.
CONSTRAINTS: one object alone, centred, square 1024x1024, wordless,
             silhouette readable at 40 pixels.
OUTPUT: topic icon in a children's maths app, same set as the reference.
```

## Правило 3. Палитра и размеры — цифрами

Прилагательное («тёплая палитра», «толстая обводка») агент трактует и дополняет,
hex и пиксели — нет. Замер: та же партия с `warm saturated palette` дала три разные
палитры; с четырьмя hex — язык серии с первого кадра.

## Правило 4. Материал И ЦВЕТ живут в стиле, а не в субъекте

`brass`, `glossy`, `wooden`, `metal`, `glass`, `shiny` внутри описания предмета
утаскивают в студийное фото. `yellow`, `blue`, `colourful` — перебивают палитру:
описание субъекта стоит ближе к предмету, чем блок PALETTE, и выигрывает.
Предмет описывается ФОРМОЙ; фактуру и цвет задают блоки STYLE и PALETTE.

Замер kodi-web: 20 описаний из 36 несли материал — все вышли фотостоком; 8 несли
цвет — `A yellow measuring tape` вышла жёлтой, `A blue protractor` синим, ровно
против четырёх заданных hex. Перед партией промпты просеиваются грепом:

```bash
grep -iE '\b(yellow|blue|red|green|golden|silver|colou?rful|brass|glossy|wooden|metal|glass|shiny)\b' prompts.json
```

## Правило 5. Серию держит эталон, приложенный файлом и названный ролью

gpt-image-2 «always uses high fidelity for image inputs», а их дока требует
**помечать роль**: «Label each image by index and role (`Image 1: style reference`)».
Картинка без объявленной роли — просто пиксели в контексте.

```bash
codex exec --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox \
  -i topics-v5/scale.png -- "$PROMPT" </dev/null
```

⚠️ `-i` **вариадический**: без разделителя `--` он глотает промпт как ещё один путь
к файлу, codex уходит читать stdin и печатает «No prompt provided via stdin».

## Порядок работы

Одна проба → **глазами** → потом партия. Печатать больше трёх штук до принятой
пробы — это и есть те 50 картинок впустую. Партия воркерами по 4–6.

⚠️ `codex exec` **читает stdin** — без `</dev/null` он выпивает список задач у цикла
и обрывается после первой картинки, отчитавшись «завершено».
⚠️ На macOS нет `timeout` (GNU coreutils) — сторож пишется на `kill -0`, иначе
каждый вызов падает с exit 127 и это читается как провал генерации.

## Анти-паттерны

- ❌ Настраивать промпт по доке модели, которую не подтвердил лог (четыре захода по Gemini); прогон партии с `>/dev/null` — причину дрейфа увидеть нечем.
- ❌ Прилагательное вместо hex там, где цвет важен; материальные прилагательные в описании предмета.
- ❌ Эталон без объявленной роли и без `--`; партия до принятой пробы.

Сырьё: `~/.codex/skills/.system/imagegen/references/prompting.md` (дока фактического
генератора) · `docs/loops/runs/2026-07-29-gam02-motivation/research-imgprompt-breadth.md`
(разбор по Gemini — годится, только если лог покажет провайдера google).
