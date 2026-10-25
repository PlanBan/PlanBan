# CutForge AI · Node.js + Cloudflare Tunnel (личный HTTPS)

## Запуск без Python

Нужно **Node.js 20+** и **FFmpeg с ffprobe**. NPM и загрузка зависимостей **не нужны**: сервер написан на встроенных модулях Node.js.

- Windows: распакуй ZIP → `cutforge-ai` → двойной клик `START_NODE_WINDOWS.cmd`.
- macOS / Linux: открой Terminal → `cd cutforge-ai && bash start-node.sh`.
- В браузере: `http://127.0.0.1:8000`.
- Если отсутствует FFmpeg на Windows: `winget install --id Gyan.FFmpeg -e` в Windows Terminal; **перезапусти терминал после установки**.

Видео хранятся на компьютере в `cutforge-ai/data/`. Исходники не изменяются. Node и старая версия Python используют тот же формат сохранённых проектов.

## Личный HTTPS-домен через Cloudflare (рекомендуется)

Cloudflare Pages сам по себе не является сервером FFmpeg. В этой схеме Node обрабатывает видео на твоём компьютере, а Cloudflare Tunnel даёт HTTPS-доступ снаружи. Компьютер должен оставаться включённым.

**ПЕРЕД публикацией обязательно настрой Cloudflare Access.** Если просто открыть Tunnel, любой с адресом сможет отправлять видео, скачивать файлы и запускать FFmpeg.

1. Добавь свой домен в Cloudflare (если ещё не добавлен).
2. Cloudflare Zero Trust → **Access controls → Applications → Add application → Self-hosted** → создай приложение для `studio.ТВОЙ-ДОМЕН`. В Access Policy Allow укажи **только свой email**, протестируй вход. Рекомендуется включить Protect with Access / проверку токена Tunnel на origin.
3. Cloudflare Dashboard → **Networking → Tunnels → Create Tunnel** → назови `cutforge-ai`, установи `cloudflared` на свой компьютер.
4. В Tunnel добавь **Published application**: hostname `studio.ТВОЙ-ДОМЕН` → Service URL `http://127.0.0.1:8000`.
5. **Перед запуском Node** укажи разрешённый внешний hostname (без HTTPS и слеша):

Windows CMD (в папке `cutforge-ai`):
```cmd
set CUTFORGE_PUBLIC_HOST=studio.example.com
node node-server\server.mjs
```

PowerShell:
```powershell
$env:CUTFORGE_PUBLIC_HOST='studio.example.com'
node .\node-server\server.mjs
```

Linux / macOS:
```bash
CUTFORGE_PUBLIC_HOST=studio.example.com node node-server/server.mjs
```

6. Запусти `cloudflared` по инструкции, которую покажет Cloudflare; открой **https://studio.ТВОЙ-ДОМЕН** и убедись, что сначала запрашивается вход через Access.

Заменяй `studio.example.com` своим настоящим доменом. **Не публикуй tunnel token и email-коды доступа на GitHub или в чате.**

## Тестовый HTTPS без постоянного домена

Для теста подходит Quick Tunnel `trycloudflare.com`. Он временный и меняет адрес при перезапуске. Запуск без защиты **небезопасен**, поэтому используй только режим с подтверждением почты (`--allowed-mail` — см. официальную документацию) и соответствующую настройку `CUTFORGE_ALLOW_QUICK_TUNNEL=1`. Для долгосрочной личной ссылки предпочтительнее Access + постоянный hostname.

## Ограничения, особенно для 30–60-минутных видео

- Через Cloudflare есть лимит размера **одного** запроса: часто 100 MB на Free/Pro; Node загружает видео кусками по 8 MiB, чтобы не превышать его.
- Для обычных публичных HTTP-хостнеймов Cloudflare действуют специальные условия доставки больших видеофайлов: длительное потоковое видео/выдачу очень больших MP4 может потребоваться обслуживать локально, через Cloudflare Stream или **частный маршрут (WARP/Zero Trust)**. Смотри официальные условия в Cloudflare Tunnel Routing docs. Для надёжной работы с большими видео рекомендуем запускать локально и экспорт скачивать локально.
- Большой FFmpeg-анализ через публичный HTTPS может упираться в прокси-таймауты. Пользуйся локальным адресом для часовых роликов; следующий этап — перенести анализ в фоновую задачу с прогрессом.
- Одновременно работает один рендер проекта. После перезапуска текущий рендер нужно начать заново; сохранённые правки останутся.
- ПК должен быть включён, Node и `cloudflared` должны работать. Если нужен сайт 24/7 без компьютера, потребуется VPS/вычислительный сервер с Node и FFmpeg (другая архитектура и расходы).

## Безопасность и диагностика

- Node слушает только `127.0.0.1:8000` (не `0.0.0.0`) и отклоняет неизвестные Host-заголовки. Внешний hostname разрешается **только** через `CUTFORGE_PUBLIC_HOST`.
- Защита Access обязательна; перед публикацией проверь, что в режиме инкогнито без авторизации **нельзя** открыть видео/API.
- Не используй Quick Tunnel без ограничений доступа, даже для личного проекта.
- Проверки: `node --check node-server/server.mjs`; `cd node-server && node --test` (нужен FFmpeg).
- Официально: https://developers.cloudflare.com/tunnel/get-started/ , https://developers.cloudflare.com/cloudflare-one/access-controls/applications/http-apps/self-hosted-public-app/ , https://developers.cloudflare.com/support/troubleshooting/http-status-codes/4xx-client-error/error-413/