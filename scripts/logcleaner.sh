#!/bin/bash

# Скрипт для очистки и ротации лог-файлов в Ubuntu
# Автор: Junior System Administrator

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== ОЧИСТКА И РОТАЦИЯ ЛОГ-ФАЙЛОВ ==="
echo "Запуск: $(date)"
echo ""

# Проверяем, запущен ли скрипт с sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Внимание: Для полной функциональности требуется sudo${NC}"
    echo "Некоторые операции будут пропущены"
    echo ""
fi

# Основные настройки
LOG_DIR="/var/log"
MAX_SIZE_MB=100  # Максимальный размер лог-файла в МБ
RETENTION_DAYS=30  # Хранить логи не более 30 дней
BACKUP_LOGS_DIR="/home/$(whoami)/log_backups"

# Создаем директорию для бэкапа логов
mkdir -p $BACKUP_LOGS_DIR

echo "Директория логов: $LOG_DIR"
echo "Максимальный размер файла: $MAX_SIZE_MB MB"
echo "Хранение логов: $RETENTION_DAYS дней"
echo "Директория бэкапов: $BACKUP_LOGS_DIR"
echo ""

# Функция для проверки размера файла
check_file_size() {
    local file=$1
    if [ -f "$file" ]; then
        if [ "$EUID" -eq 0 ]; then
            local size_mb=$(du -m "$file" 2>/dev/null | cut -f1)
        else
            local size_mb=$(sudo du -m "$file" 2>/dev/null | cut -f1)
        fi
        
        if [ ! -z "$size_mb" ] && [ "$size_mb" -gt $MAX_SIZE_MB ]; then
            return 0  # Файл слишком большой
        else
            return 1  # Файл в норме
        fi
    else
        return 2  # Файл не существует
    fi
}

# Функция для ротации лог-файла
rotate_log_file() {
    local logfile=$1
    local backup_name=$(basename $logfile)_$(date +%Y-%m-%d_%H-%M-%S).bak
    
    echo "Ротируем файл: $logfile"
    
    # Создаем бэкап текущего лога
    if [ "$EUID" -eq 0 ]; then
        cp "$logfile" "$BACKUP_LOGS_DIR/$backup_name"
        truncate -s 0 "$logfile"
    else
        sudo cp "$logfile" "$BACKUP_LOGS_DIR/$backup_name"
        sudo truncate -s 0 "$logfile"
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Файл $logfile успешно ротирован${NC}"
    else
        echo -e "${RED}Ошибка при ротации $logfile${NC}"
    fi
}

# Проверяем критически важные лог-файлы
IMPORTANT_LOGS=("syslog" "auth.log" "kern.log" "dpkg.log" "messages")

echo "=== ПРОВЕРКА РАЗМЕРА ЛОГ-ФАЙЛОВ ==="
for LOGFILE in "${IMPORTANT_LOGS[@]}"; do
    FULL_PATH="$LOG_DIR/$LOGFILE"
    
    if check_file_size "$FULL_PATH"; then
        echo -e "${YELLOW}Файл $LOGFILE превысил размер ${MAX_SIZE_MB}MB${NC}"
        rotate_log_file "$FULL_PATH"
    elif [ $? -eq 1 ]; then
        echo -e "${GREEN}Файл $LOGFILE в норме${NC}"
    else
        echo "Файл $LOGFILE не найден"
    fi
done

# Проверяем логи приложений
echo ""
echo "=== ПРОВЕРКА ЛОГОВ ПРИЛОЖЕНИЙ ==="
APP_LOGS=("nginx/access.log" "nginx/error.log" "apache2/access.log" "apache2/error.log")

for APP_LOG in "${APP_LOGS[@]}"; do
    FULL_PATH="$LOG_DIR/$APP_LOG"
    
    if check_file_size "$FULL_PATH"; then
        echo -e "${YELLOW}Файл $APP_LOG превысил размер ${MAX_SIZE_MB}MB${NC}"
        rotate_log_file "$FULL_PATH"
    elif [ -f "$FULL_PATH" ]; then
        echo -e "${GREEN}Файл $APP_LOG в норме${NC}"
    fi
done

# Удаляем старые сжатые логи
echo ""
echo "=== УДАЛЕНИЕ СТАРЫХ ЛОГОВ ==="
if [ "$EUID" -eq 0 ]; then
    OLD_LOGS_COUNT=$(find $LOG_DIR -name "*.gz" -type f -mtime +$RETENTION_DAYS | wc -l)
    find $LOG_DIR -name "*.gz" -type f -mtime +$RETENTION_DAYS -delete
    echo -e "${GREEN}Удалено старых логов из /var/log: $OLD_LOGS_COUNT${NC}"
    
    # Очищаем старые бэкапы логов
    OLD_BACKUPS_COUNT=$(find $BACKUP_LOGS_DIR -name "*.bak" -type f -mtime +$RETENTION_DAYS | wc -l)
    find $BACKUP_LOGS_DIR -name "*.bak" -type f -mtime +$RETENTION_DAYS -delete
    echo -e "${GREEN}Удалено старых бэкапов: $OLD_BACKUPS_COUNT${NC}"
else
    echo -e "${YELLOW}Пропускаем удаление старых логов (требуются права root)${NC}"
fi

# Очищаем journald логи (только с sudo)
echo ""
echo "=== ОЧИСТКА SYSTEMD JOURNAL ==="
if [ "$EUID" -eq 0 ]; then

ChatGPT & DeepSeek ♥️, [27.09.2025 16:26]
JOURNAL_SIZE_BEFORE=$(journalctl --disk-usage | head -1)
    journalctl --vacuum-time=7d
    JOURNAL_SIZE_AFTER=$(journalctl --disk-usage | head -1)
    echo "Размер journal до: $JOURNAL_SIZE_BEFORE"
    echo "Размер journal после: $JOURNAL_SIZE_AFTER"
    echo -e "${GREEN}Systemd journal очищен${NC}"
else
    echo -e "${YELLOW}Пропускаем очистку journal (требуются права root)${NC}"
fi

# Показываем итоговую информацию
echo ""
echo "=== ИТОГОВАЯ ИНФОРМАЦИЯ ==="
echo "Директория бэкапов логов: $BACKUP_LOGS_DIR"
if [ -d "$BACKUP_LOGS_DIR" ]; then
    echo "Содержимое бэкапов:"
    ls -lh $BACKUP_LOGS_DIR/*.bak 2>/dev/null | head -5 || echo "Бэкапы не найдены"
fi

echo ""
echo -e "${GREEN}Очистка логов завершена${NC}"
echo "Завершено: $(date)"
echo ""
echo -e "${YELLOW}Для полной функциональности запускайте: sudo ./logcleaner.sh${NC}"
