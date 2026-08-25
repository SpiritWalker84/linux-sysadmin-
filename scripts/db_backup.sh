#!/usr/bin/env bash
# Дамп пользовательских БД, если есть клиент.
# MySQL: ~/.my.cnf или MYSQL_PWD (осторожно: видно в ps).
# Postgres: sudo -u postgres, либо PGUSER/PGPASSWORD/PGHOST.
set -u

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="${BACKUP_DIR:-/var/backups/linux-sysadmin/db}"
KEEP_DAYS="${KEEP_DAYS:-7}"

if ! mkdir -p "$BACKUP_DIR"; then
  echo -e "${RED}не создать $BACKUP_DIR${NC}"
  exit 1
fi

LOG="$BACKUP_DIR/db_backup.log"
ok=0
fail=0
log() { echo "$(date -Iseconds) $*" >> "$LOG"; }

if command -v mysqldump &>/dev/null; then
  echo "=== MySQL ==="
  if mysqldump --all-databases --single-transaction --routines --events \
      > "$BACKUP_DIR/mysql_all_${DATE}.sql" 2>>"$LOG"; then
    echo -e "${GREEN}mysql_all_${DATE}.sql${NC}"
    ok=$((ok + 1))
    log "mysql ok"
  else
    echo -e "${YELLOW}mysqldump не вышло (нет доступа?). Нужен ~/.my.cnf${NC}"
    fail=$((fail + 1))
    rm -f "$BACKUP_DIR/mysql_all_${DATE}.sql"
  fi
else
  echo -e "${YELLOW}mysqldump нет в PATH${NC}"
fi

if command -v pg_dumpall &>/dev/null; then
  echo "=== PostgreSQL ==="
  if [[ "$(id -u)" -eq 0 ]] && getent passwd postgres &>/dev/null; then
    pg_ok=$(sudo -u postgres pg_dumpall > "$BACKUP_DIR/pg_all_${DATE}.sql" 2>>"$LOG" && echo 1 || echo 0)
  else
    pg_ok=$(pg_dumpall > "$BACKUP_DIR/pg_all_${DATE}.sql" 2>>"$LOG" && echo 1 || echo 0)
  fi
  if [[ "$pg_ok" == 1 ]]; then
    echo -e "${GREEN}pg_all_${DATE}.sql${NC}"
    ok=$((ok + 1))
    log "postgres ok"
  else
    echo -e "${YELLOW}pg_dumpall не вышло (роль postgres / PGHOST?)${NC}"
    fail=$((fail + 1))
    rm -f "$BACKUP_DIR/pg_all_${DATE}.sql"
  fi
else
  echo -e "${YELLOW}pg_dumpall нет в PATH${NC}"
fi

find "$BACKUP_DIR" -maxdepth 1 -name '*.sql' -mtime "+$KEEP_DAYS" -delete 2>>"$LOG" || true

echo "готово: $ok  ошибок: $fail  $BACKUP_DIR"
[[ "$ok" -eq 0 ]] && exit 1
exit 0
