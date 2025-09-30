#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Настройки
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="/var/backups"
LOG_FILE="$BACKUP_DIR/backup.log"
HOME_USER=$(whoami)

# Создание директории для бэкапов
echo "Создаем директорию для бэкапов..."
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR" 2>> "$LOG_FILE"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Директория $BACKUP_DIR создана${NC}"
    else
        echo -e "${RED}Ошибка создания директории $BACKUP_DIR${NC}"
        exit 1
    fi
fi

# Логирование начала процесса
echo "$(date): Начало резервного копирования" >> "$LOG_FILE"

# 1. Бэкап домашней директории пользователя
echo "Копируем домашнюю директорию пользователя $HOME_USER..."

# Проверка существования домашней директории
if [ ! -d "/home/$HOME_USER/" ]; then
    echo -e "${RED}Домашняя директория /home/$HOME_USER/ не найдена${NC}"
    echo "$(date): Ошибка - домашняя директория не найдена" >> "$LOG_FILE"
else
    tar -czf "$BACKUP_DIR/home_backup_$DATE.tar.gz" -C /home "$HOME_USER" 2>> "$LOG_FILE"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Бэкап домашней директории создан${NC}"
        echo "$(date): Бэкап домашней директории завершен успешно" >> "$LOG_FILE"
    else
        echo -e "${RED}Ошибка при бэкапе домашней директории${NC}"
        echo "$(date): Ошибка при бэкапе домашней директории" >> "$LOG_FILE"
    fi
fi

# 2. Бэкап системных конфигов
echo "Копируем системные конфигурации..."
tar -czf "$BACKUP_DIR/etc_backup_$DATE.tar.gz" /etc/ 2>> "$LOG_FILE"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Бэкап конфигураций создан${NC}"
else
    echo -e "${RED}Ошибка при бэкапе конфигураций${NC}"
fi

# 3. Бэкап лог-файлов (только с правами root)
echo "Копируем важные логи..."
if [ "$EUID" -eq 0 ]; then
    # Проверка существования директории логов
    if [ -d "/var/log/" ]; then
        tar -czf "$BACKUP_DIR/logs_backup_$DATE.tar.gz" /var/log/ 2>> "$LOG_FILE"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Бэкап логов создан${NC}"
            echo "$(date): Бэкап логов завершен успешно" >> "$LOG_FILE"
        else
            echo -e "${RED}Ошибка при бэкапе логов${NC}"
            echo "$(date): Ошибка при бэкапе логов" >> "$LOG_FILE"
        fi
    else
        echo -e "${YELLOW}Директория /var/log/ не найдена${NC}"
    fi
else
    echo -e "${YELLOW}Пропускаем бэкап логов (требуются права root)${NC}"
    echo "$(date): Бэкап логов пропущен (недостаточно прав)" >> "$LOG_FILE"
fi

# 4. Очистка старых бэкапов (старше 7 дней)
echo "Очищаем старые бэкапы..."
OLD_BACKUPS_COUNT=$(find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 | wc -l)
OLD_SQL_COUNT=$(find "$BACKUP_DIR" -name "*.sql" -mtime +7 | wc -l)

if [ "$OLD_BACKUPS_COUNT" -gt 0 ] || [ "$OLD_SQL_COUNT" -gt 0 ]; then
    find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete 2>> "$LOG_FILE"
    find "$BACKUP_DIR" -name "*.sql" -mtime +7 -delete 2>> "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Старые бэкапы очищены${NC}"
        echo "Удалено: $OLD_BACKUPS_COUNT архивов, $OLD_SQL_COUNT SQL-файлов"
        echo "$(date): Удалено старых бэкапов: $OLD_BACKUPS_COUNT архивов, $OLD_SQL_COUNT SQL-файлов" >> "$LOG_FILE"
    else
        echo -e "${YELLOW}Ошибка при очистке старых бэкапов${NC}"
    fi
else
    echo -e "${GREEN}Старые бэкапы для очистки не найдены${NC}"
fi

# 5. Информация о созданных бэкапах
echo ""
echo "=== ИНФОРМАЦИЯ О БЭКАПАХ ==="
echo "Созданные файлы:"
ls -lh "$BACKUP_DIR"/*"$DATE"* 2>/dev/null || echo "Файлы не найдены"

echo ""
echo "Общий размер бэкапов:"
du -sh "$BACKUP_DIR"

echo ""
echo "Свободное место в системе:"
df -h "$BACKUP_DIR" | tail -1

# Завершение
echo ""
echo "$(date): Резервное копирование завершено" >> "$LOG_FILE"
echo -e "${GREEN}Резервное копирование завершено${NC}"
echo "Лог сохранен в: $LOG_FILE"
echo "Директория бэкапов: $BACKUP_DIR"

if [ "$EUID" -ne 0 ]; then
    echo ""
echo -e "${YELLOW}Для полного бэкапа (включая логи) рекомендуется запускать: sudo $0${NC}"
fi
