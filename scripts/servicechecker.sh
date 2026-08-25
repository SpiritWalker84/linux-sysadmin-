#!/usr/bin/env bash
# Проверка systemd-служб. Перезапуск только с --restart.
# Код выхода 1, если что-то из найденных unit'ов не запущено.
set -u

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

RESTART=0
[[ "${1:-}" == "--restart" ]] && RESTART=1

# пары: что ищем / как называется unit
UNITS=(ssh sshd nginx apache2 mysql mysqld mariadb postgresql cron crond)

unit_exists() {
  systemctl cat "${1}.service" &>/dev/null
}

ERROR_COUNT=0
SEEN=""

echo "=== службы ($(date)) ==="
[[ "$RESTART" -eq 1 ]] && echo "режим: start при остановке"

for SERVICE in "${UNITS[@]}"; do
  unit_exists "$SERVICE" || continue
  case " $SEEN " in
    *" $SERVICE "*) continue ;;
  esac
  SEEN+=" $SERVICE"

  if systemctl is-active --quiet "$SERVICE"; then
    echo -e "${GREEN}$SERVICE: запущена${NC}"
    continue
  fi
  echo -e "${RED}$SERVICE: остановлена${NC}"
  if [[ "$RESTART" -eq 1 ]]; then
    if sudo systemctl start "$SERVICE" && sleep 1 && systemctl is-active --quiet "$SERVICE"; then
      echo -e "${GREEN}  запущена${NC}"
    else
      echo -e "${RED}  не поднялась${NC}"
      ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
  else
    ERROR_COUNT=$((ERROR_COUNT + 1))
  fi
done

if [[ -z "${SEEN// /}" ]]; then
  echo "из списка ничего не установлено (ssh/nginx/mysql/postgres/cron…)"
fi

echo "остановлено: $ERROR_COUNT"
[[ "$RESTART" -eq 0 && "$ERROR_COUNT" -gt 0 ]] && echo -e "${YELLOW}перезапуск: $0 --restart${NC}"
[[ "$ERROR_COUNT" -gt 0 ]] && exit 1
exit 0
