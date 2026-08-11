#!/bin/bash
# Еженедельное напоминание собрать обновления по направлениям.
# Запускается LaunchAgent'ом com.katya.dashboard-weekly по вторникам в 18:00.
# Шлёт сообщение в Telegram-чат, где живёт Claude-сессия, — на пинг можно
# ответить прямо там, и сессия внесёт правки.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$HOME/.claude/channels/telegram/.env"
CHAT_ID="69382851"
PAGE="https://essesum.github.io/digital-avatars/"
LOG="$HOME/Library/Logs/dashboard-weekly.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"; }

if [[ ! -f "$ENV_FILE" ]]; then
  log "ОШИБКА: нет $ENV_FILE — токен взять неоткуда"
  exit 1
fi

TOKEN="$(grep -m1 '^TELEGRAM_BOT_TOKEN=' "$ENV_FILE" | cut -d= -f2- | tr -d "\"' \r\n")"
if [[ -z "$TOKEN" ]]; then
  log "ОШИБКА: TELEGRAM_BOT_TOKEN пуст в $ENV_FILE"
  exit 1
fi

# Текущие даты обновления из index.html — чтобы в пинге было видно, что протухло.
STATUS="$(python3 - "$REPO/index.html" <<'PY'
import re, sys
try:
    src = open(sys.argv[1], encoding="utf-8").read()
except OSError:
    sys.exit(0)
names = {"da": "Digital Avatars", "cgi": "CGI Agent"}
out = []
for track, title in names.items():
    m = re.search(r'<span data-updated="%s">(.*?)</span>' % track, src, re.DOTALL)
    val = (m.group(1).strip() if m else "—") or "—"
    out.append(f"• {title}: {val}")
print("\n".join(out))
PY
)"

TEXT="🗓 Завтра синк по направлениям. Что изменилось за неделю?

Последнее обновление:
${STATUS}

Ответь списком — поправлю дашборд, проставлю дату и запушу.
${PAGE}"

HTTP="$(curl -sS -o /tmp/dashboard-weekly-resp.json -w '%{http_code}' \
  --max-time 20 \
  -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
  --data-urlencode "chat_id=${CHAT_ID}" \
  --data-urlencode "text=${TEXT}" \
  --data-urlencode "disable_web_page_preview=true" || echo "000")"

if [[ "$HTTP" == "200" ]]; then
  log "напоминание отправлено (HTTP 200)"
else
  log "ОШИБКА отправки: HTTP $HTTP — $(head -c 400 /tmp/dashboard-weekly-resp.json 2>/dev/null)"
  exit 1
fi
