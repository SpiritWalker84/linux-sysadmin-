#!/usr/bin/env bash
# Проверка systemd-служб. Перезапуск только с --restart.

set -u

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

RESTART=0
if [[ "${1:-}" == "--restart" ]]; then
  RESTART=1
fi

SERVICES=(ssh nginx apache2 mysql postgresql cron systemd-logind)
ERROR_COUNT=0

echo "=== службы ($(date)) ==="
[[ "$RESTART" -eq 1 ]] && echo "режим: проверка + попытка start"

for SERVICE in "${SERVICES[@]}"; do
  if ! systemctl list-unit-files "${SERVICE}.service" --no-legend 2>/dev/null | grep -q .; then
    echo "$SERVICE: не установлена"
    continue
  fi
  if systemctl is-active --quiet "$SERVICE"; then
    echo -e "${GREEN}$SERVICE: запущена${NC}"
    continue
  fi
  echo -e "${RED}$SERVICE: остановлена${NC}"
  if [[ "$RESTART" -eq 1 ]]; then
    echo "  systemctl start $SERVICE"
    if sudo systemctl start "$SERVICE"; then
      sleep 1
      if systemctl is-active --quiet "$SERVICE"; then
        echo -e "${GREEN}  запущена${NC}"
      else
        echo -e "${RED}  не поднялась${NC}"
        ERROR_COUNT=$((ERROR_COUNT + 1))
      fi
    else
      ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
  else
    ERROR_COUNT=$((ERROR_COUNT + 1))
  fi
done

echo "проблем: $ERROR_COUNT"
[[ "$RESTART" -eq 0 && "$ERROR_COUNT" -gt 0 ]] && echo -e "${YELLOW}перезапуск: $0 --restart${NC}"
exit 0
