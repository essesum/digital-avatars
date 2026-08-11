#!/bin/bash
# Проставляет дату «Обновлено» для направления во всех HTML-файлах дашборда.
#
#   bin/bump-date.sh da            → сегодняшняя дата для Digital Avatars
#   bin/bump-date.sh cgi           → сегодняшняя дата для CGI Agent
#   bin/bump-date.sh da 2026-08-05 → конкретная дата
#
# Меняет содержимое всех <span data-updated="<направление>">…</span>,
# то есть и на титуле, и на странице направления сразу.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRACK="${1:-}"
DATE_ISO="${2:-}"

if [[ "$TRACK" != "da" && "$TRACK" != "cgi" ]]; then
  echo "usage: $(basename "$0") <da|cgi> [YYYY-MM-DD]" >&2
  exit 1
fi

python3 - "$REPO" "$TRACK" "$DATE_ISO" <<'PY'
import sys, re, glob, os
from datetime import date

repo, track, iso = sys.argv[1], sys.argv[2], sys.argv[3]

MONTHS = ["января","февраля","марта","апреля","мая","июня",
          "июля","августа","сентября","октября","ноября","декабря"]

if iso:
    y, m, d = (int(x) for x in iso.split("-"))
    day = date(y, m, d)
else:
    day = date.today()

human = f"{day.day} {MONTHS[day.month - 1]} {day.year}"
pattern = re.compile(
    r'(<span data-updated="%s">)(.*?)(</span>)' % re.escape(track),
    re.DOTALL,
)

touched = []
for path in sorted(glob.glob(os.path.join(repo, "*.html"))):
    src = open(path, encoding="utf-8").read()
    new, n = pattern.subn(lambda m: m.group(1) + human + m.group(3), src)
    if n and new != src:
        open(path, "w", encoding="utf-8").write(new)
        touched.append(f"{os.path.basename(path)} ({n})")

if not touched:
    print(f"нечего менять: маркер data-updated=\"{track}\" уже равен «{human}» или отсутствует")
else:
    print(f"{track} → {human}: " + ", ".join(touched))
PY
