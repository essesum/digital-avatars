# Дашборд направлений

Живёт на GitHub Pages: https://essesum.github.io/digital-avatars/

```
index.html            титул: две кнопки направлений + даты обновления
digital-avatars.html  Digital Avatars — проекты, демо, финмодель
cgi-agent.html        CGI Agent — каркас, наполняется
assets/style.css      общие стили всех трёх страниц
assets/murino.jpg     скриншот стенда Школы Мурино
assets/video/         видео с площадок + постеры (кадр из первой секунды)
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
   `paid` (платный), `wait` (ждём данных), `cpu` (CPU), `live` (запущено),
   `upd` (обновлено), `new` (новое).

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
недели, секция `.focus` (фиолетовая рамка). Внутри `.focus-split`: слева
вертикальное видео с площадки, справа `.timeline` из строк `.tl` — программа
события. Текущий день помечается классом `.tl.now`. Ниже — строка `.next` с
ближайшей задачей.

Чтобы сменить фокус: переписать заголовок секции `.focus`, подставить своё
видео в `.vid`, переписать строки `.tl` и `.next`.

## Запущено

Секция «Запущено» — проекты, которые уже работают на площадке. Формат: сначала
компактный `.list` со строками и датой запуска (метка `live`), под ним по
карточке `article.launch` на проект с видео (`.vid-grid`), живым стендом и
строкой «Дальше».

Когда проект переезжает из «Сейчас в работе» в «Запущено» — строку из списка
работ удалить, чтобы он не считался дважды в счётчиках вверху.

## Видео с площадок

Исходники с телефона в репозиторий не кладём: `.MOV` с айфона в HEVC, Chrome
его в `<video>` не играет, и весит он в разы больше нужного. Перед коммитом
перегоняем в h264 и снимаем постер:

```bash
ffmpeg -i ~/Downloads/IMG_XXXX.MOV -vf "scale=1280:-2" -c:v libx264 -crf 26 \
  -preset slow -pix_fmt yuv420p -movflags +faststart -c:a aac -b:a 96k \
  assets/video/имя.mp4
ffmpeg -ss 1 -i assets/video/имя.mp4 -frames:v 1 -vf "scale=960:-2" \
  assets/video/имя.jpg
```

Вертикальное видео масштабируем в `scale=720:-2`. У всех `<video>` стоит
`preload="none"` и `poster` — до нажатия на play не грузится ни байта, поэтому
страница остаётся лёгкой независимо от числа роликов.

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
