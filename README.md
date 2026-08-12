# Дашборд направлений

Живёт на GitHub Pages: https://essesum.github.io/digital-avatars/

```
index.html            титул: две кнопки направлений + даты обновления
digital-avatars.html  Digital Avatars — проекты, демо, финмодель
cgi-agent.html        CGI Agent — каркас, наполняется
assets/style.css      общие стили всех трёх страниц
assets/murino.jpg     скриншот стенда Школы Мурино
bin/bump-date.sh      проставить дату «Обновлено» по направлению
bin/weekly-ping.sh    напоминание в Telegram (запускает LaunchAgent)
launchd/              копия plist'а, установленного в ~/Library/LaunchAgents/
```

## Как обновлять

1. Правишь строки проектов прямо в HTML. Формат строки:
   ```html
   <div class="row"><span class="name">Название проекта</span><span class="tag cross">кроссцели</span></div>
   ```
   Метки: `cross` (кроссцели), `docs` (документы), `dev` (в разработке),
   `paid` (платный), `wait` (ждём данных), `cpu` (CPU).

2. Проставляешь дату — она обновится и на титуле, и на странице направления:
   ```bash
   ./bin/bump-date.sh da      # Digital Avatars
   ./bin/bump-date.sh cgi     # CGI Agent
   ```

3. Пушишь. Pages подхватывает за минуту.
   ```bash
   git add -A && git commit -m "апдейт DA" && git push
   ```

Счётчики вверху страницы и «19 проектов» на титуле правятся руками — это витрина, а не расчёт.

## Напоминание по средам

LaunchAgent `com.katya.dashboard-weekly` шлёт напоминание **по вторникам в 18:00**
в Telegram-чат с Claude-сессией. В сообщении видно, когда каждое направление
обновлялось последний раз. На пинг можно ответить прямо в чате.

```bash
# проверить, что агент загружен
launchctl print gui/$(id -u)/com.katya.dashboard-weekly | head -20

# отправить напоминание прямо сейчас (проверка)
./bin/weekly-ping.sh && tail -1 ~/Library/Logs/dashboard-weekly.log

# поменять день/время: Weekday 1=пн … 2=вт … 5=пт
vi launchd/com.katya.dashboard-weekly.plist
cp launchd/com.katya.dashboard-weekly.plist ~/Library/LaunchAgents/
launchctl bootout gui/$(id -u)/com.katya.dashboard-weekly
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.katya.dashboard-weekly.plist
```

Токен бота берётся из `~/.claude/channels/telegram/.env`, в репозитории его нет.
Если ноут спал во вторник вечером — launchd выполнит задачу при пробуждении,
напоминание не потеряется.

## Фокус недели

Блок «Фокус недели» на странице Digital Avatars — выделенный проект текущей
недели. Внутри: свежий кадр стенда, живой iframe и строка «Дальше» с ближайшей
задачей. Чтобы сменить фокус — переписать заголовок секции `.focus`, картинку и
строку `.next`, а метку `фокус недели` перенести на другую строку в списке.

Кадр стенда снимается заново, а не берётся из чужих скриншотов:

```bash
B=~/.claude/skills/gstack/browse/dist/browse
$B viewport 1400x840 --scale 2
$B header "Authorization:Basic $(printf 'space:Fuu0thae9ilu' | base64)"
$B goto https://school.digitalavatars.ru/
# дождаться загрузки стенда, затем
$B screenshot /tmp/stand.png --viewport
```

## Известное

**Пароль от стенда лежит в открытом виде** на публичной странице
(`digital-avatars.html`, блок `.creds`) и в истории git. Решение осознанное —
для этой реализации так договорились. Если стенд понадобится закрыть, менять
доступ придётся на стороне `school.digitalavatars.ru`, удаления из репозитория
недостаточно.

Живой стенд грузится **по клику**, а не сразу: до авторизации сайт отдаёт 401,
и без кнопки во фрейме была бы белая страница «401 Authorization Required».
Подставить логин с паролем прямо в `src` фрейма нельзя — Chrome блокирует
`логин:пароль@адрес` для всего, что грузится внутри страницы. В ссылке
«Открыть в новой вкладке» они работают: это переход верхнего уровня.

Блок «Демо: аватар на CPU» пустой: iframe тянет
`sdk-avatar2d-browser-stage.digitalavatars.ru`, стенд не отрисовывается внутри
панели. Кнопка «Открыть демо» под ним работает. У `.demo-fallback` стоит
`z-index: -1`, то есть фолбэк лежит под фреймом — чинить оттуда.
