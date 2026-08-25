#!/usr/bin/env bash
# Архив home + /etc в отдельный каталог (не трогает чужие бэкапы в /var/backups).
# Каталог: BACKUP_DIR (по умолчанию /var/backups/linux-sysadmin).
set -u

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="${BACKUP_DIR:-/var/backups/linux-sysadmin}"
KEEP_DAYS="${KEEP_DAYS:-7}"
USER_NAME="${SUDO_USER:-$(whoami)}"
HOME_DIR=$(getent passwd "$USER_NAME" | cut -d: -f6)
HOME_DIR="${HOME_DIR:-/home/$USER_NAME}"

if ! mkdir -p "$BACKUP_DIR"; then
  echo -e "${RED}не создать $BACKUP_DIR (нужен sudo?)${NC}"
  exit 1
fi

LOG_FILE="$BACKUP_DIR/backup.log"
ok=0
fail=0

log() { echo "$(date -Iseconds) $*" >> "$LOG_FILE"; }

archive() {
  local name=$1 src=$2
  local out="$BACKUP_DIR/${name}_${DATE}.tar.gz"
  if [[ ! -e $src ]]; then
    echo -e "${YELLOW}нет $src, пропуск${NC}"
    return
  fi
  if tar -czf "$out" -C "$(dirname "$src")" "$(basename "$src")" 2>>"$LOG_FILE"; then
    echo -e "${GREEN}$name → $out${NC}"
    log "ok $out"
    ok=$((ok + 1))
  else
    echo -e "${RED}ошибка $name${NC}"
    log "fail $name"
    fail=$((fail + 1))
    rm -f "$out"
  fi
}

log "start user=$USER_NAME"
archive "home" "$HOME_DIR"
archive "etc" "/etc"

if [[ "${EUID:-$(id -u)}" -eq 0 && -d /var/log ]]; then
  archive "varlog" "/var/log"
else
  echo -e "${YELLOW}логи /var/log — только root${NC}"
fi

find "$BACKUP_DIR" -maxdepth 1 \( -name '*.tar.gz' -o -name '*.sql' \) -mtime "+$KEEP_DAYS" -delete 2>>"$LOG_FILE" || true

echo "успешно: $ok  ошибок: $fail  каталог: $BACKUP_DIR"
du -sh "$BACKUP_DIR" 2>/dev/null || true
[[ "$fail" -gt 0 ]] && exit 1
exit 0
