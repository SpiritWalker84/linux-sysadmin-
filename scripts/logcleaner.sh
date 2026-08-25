#!/usr/bin/env bash
# Ротация больших логов через копирование + truncate.
# Не заменяет logrotate. По умолчанию только показывает, что превысило лимит.
# Резать файлы: $0 --rotate
set -u

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ROTATE=0
[[ "${1:-}" == "--rotate" ]] && ROTATE=1

LOG_DIR="${LOG_DIR:-/var/log}"
MAX_MB="${MAX_SIZE_MB:-100}"
KEEP_DAYS="${RETENTION_DAYS:-30}"
BACKUP_DIR="${BACKUP_LOGS_DIR:-$HOME/log_backups}"

size_mb() {
  du -m "$1" 2>/dev/null | awk '{print $1}'
}

echo "=== логи ($(date))  лимит ${MAX_MB}M  rotate=$ROTATE ==="

FILES=(
  "$LOG_DIR/syslog"
  "$LOG_DIR/auth.log"
  "$LOG_DIR/kern.log"
  "$LOG_DIR/nginx/access.log"
  "$LOG_DIR/nginx/error.log"
  "$LOG_DIR/apache2/access.log"
  "$LOG_DIR/apache2/error.log"
)

over=0
for f in "${FILES[@]}"; do
  [[ -f "$f" ]] || continue
  mb=$(size_mb "$f")
  [[ -n $mb ]] || continue
  if (( mb > MAX_MB )); then
    echo -e "${YELLOW}$f  ${mb}M${NC}"
    over=$((over + 1))
    if [[ "$ROTATE" -eq 1 ]]; then
      mkdir -p "$BACKUP_DIR"
      dest="$BACKUP_DIR/$(basename "$f")_$(date +%Y-%m-%d_%H-%M-%S).bak"
      if cp "$f" "$dest" && truncate -s 0 "$f"; then
        echo -e "${GREEN}  → $dest + truncate${NC}"
      else
        echo -e "${RED}  не вышло (нужен root на $f)${NC}"
      fi
    fi
  else
    echo -e "${GREEN}$f  ${mb}M${NC}"
  fi
done

if [[ "$ROTATE" -eq 1 && -d $BACKUP_DIR ]]; then
  find "$BACKUP_DIR" -maxdepth 1 -name '*.bak' -mtime "+$KEEP_DAYS" -delete || true
fi

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo
  echo "journal disk: $(journalctl --disk-usage 2>/dev/null | tr -d '\n')"
  if [[ "$ROTATE" -eq 1 ]]; then
    journalctl --vacuum-time=7d >/dev/null
    echo "journal vacuum 7d: $(journalctl --disk-usage 2>/dev/null | tr -d '\n')"
  fi
fi

[[ "$ROTATE" -eq 0 && "$over" -gt 0 ]] && echo -e "${YELLOW}срезать: $0 --rotate${NC}"
exit 0
