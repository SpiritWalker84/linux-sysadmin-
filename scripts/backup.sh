#!/bin/bash

# Скрипт для резервного копирования важных данных в Ubuntu

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== РЕЗЕРВНОЕ КОПИРОВАНИЕ ==="
echo "Запуск: $(date)"
echo ""

# Проверяем, запущен ли скрипт с sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Внимание: Скрипт требует прав sudo для некоторых операций${NC}"
    echo "Запустите: sudo ./backup.sh"
    echo ""
fi

# Основные настройки
BACKUP_DIR="/home/$(whoami)/backups"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
LOG_FILE="/home/$(whoami)/backup.log"

# Создаем директорию для бэкапов
mkdir -p $BACKUP_DIR

echo "Директория для бэкапов: $BACKUP_DIR"
echo "Файл лога: $LOG_FILE"
echo ""

# Логируем начало процесса
echo "$(date): Начало резервного копирования" >> $LOG_FILE

# 1. Бэкап базы данных MySQL (если установлена)
echo "Проверяем наличие MySQL..."
if command -v mysql &> /dev/null; then
    echo "Создаем бэкап MySQL..."
    if [ "$EUID" -eq 0 ]; then
        mysqldump --all-databases > $BACKUP_DIR/mysql_backup_$DATE.sql 2>> $LOG_FILE
    else
        sudo mysqldump --all-databases > $BACKUP_DIR/mysql_backup_$DATE.sql 2>> $LOG_FILE
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Бэкап MySQL создан успешно${NC}"
        echo "$(date): Бэкап MySQL создан" >> $LOG_FILE
    else
        echo -e "${RED}Ошибка при создании бэкапа MySQL${NC}"
        echo "$(date): Ошибка бэкапа MySQL" >> $LOG_FILE
    fi
else
    echo "MySQL не установлена"
fi

# 2. Бэкап базы данных PostgreSQL (если установлена)
echo "Проверяем наличие PostgreSQL..."
if command -v psql &> /dev/null; then
    echo "Создаем бэкап PostgreSQL..."
    
    # Получаем список всех баз данных PostgreSQL
    if [ "$EUID" -eq 0 ]; then
        DATABASES=$(sudo -u postgres psql -l -t | cut -d'|' -f1 | sed 's/ //g' | grep -v template | grep -v postgres)
    else
        DATABASES=$(sudo sudo -u postgres psql -l -t | cut -d'|' -f1 | sed 's/ //g' | grep -v template | grep -v postgres)
    fi
    
    # Создаем бэкап для каждой базы данных
    for DB in $DATABASES; do
        if [ ! -z "$DB" ]; then
            echo "  Бэкапируем базу: $DB"
            if [ "$EUID" -eq 0 ]; then
                sudo -u postgres pg_dump $DB > $BACKUP_DIR/pgsql_${DB}_backup_$DATE.sql 2>> $LOG_FILE
            else
                sudo sudo -u postgres pg_dump $DB > $BACKUP_DIR/pgsql_${DB}_backup_$DATE.sql 2>> $LOG_FILE
            fi
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}  Бэкап PostgreSQL ($DB) создан успешно${NC}"
            else
                echo -e "${RED}  Ошибка при бэкапе PostgreSQL ($DB)${NC}"
            fi
        fi
    done
    
    # Создаем полный бэкап всех баз
    echo "Создаем полный бэкап PostgreSQL..."
    if [ "$EUID" -eq 0 ]; then
        sudo -u postgres pg_dumpall > $BACKUP_DIR/pgsql_all_backup_$DATE.sql 2>> $LOG_FILE
    else
        sudo sudo -u postgres pg_dumpall > $BACKUP_DIR/pgsql_all_backup_$DATE.sql 2>> $LOG_FILE
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Полный бэкап PostgreSQL создан${NC}"
        echo "$(date): Бэкап PostgreSQL создан" >> $LOG_FILE
    else
        echo -e "${RED}Ошибка при создании полного бэкапа PostgreSQL${NC}"
    fi
else
    echo "PostgreSQL не установлена"
fi

# 3. Бэкап конфигурационных файлов системы
echo "Копируем конфигурационные файлы..."
if [ "$EUID" -eq 0 ]; then
    tar -czf $BACKUP_DIR/etc_backup_$DATE.tar.gz /etc/ 2>> $LOG_FILE
else
    sudo tar -czf $BACKUP_DIR/etc_backup_$DATE.tar.gz /etc/ 2>> $LOG_FILE
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Бэкап конфигов /etc создан${NC}"
else
    echo -e "${RED}Ошибка при бэкапе /etc${NC}"
fi

# 4. Бэкап домашней директории пользователя
echo "Копируем домашнюю директорию..."
tar -czf $BACKUP_DIR/home_backup_$DATE.tar.gz /home/$(whoami)/ 2>> $LOG_FILE
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Бэкап домашней директории создан${NC}"
else

ChatGPT & DeepSeek ♥️, [27.09.2025 16:00]
echo -e "${RED}Ошибка при бэкапе домашней директории${NC}"
fi

# 5. Бэкап лог-файлов (только с sudo)
echo "Копируем важные логи..."
if [ "$EUID" -eq 0 ]; then
    tar -czf $BACKUP_DIR/logs_backup_$DATE.tar.gz /var/log/ 2>> $LOG_FILE
else
    echo -e "${YELLOW}Пропускаем бэкап логов (требуются права root)${NC}"
fi

if [ $? -eq 0 ] && [ "$EUID" -eq 0 ]; then
    echo -e "${GREEN}Бэкап логов создан${NC}"
elif [ "$EUID" -ne 0 ]; then
    true
else
    echo -e "${RED}Ошибка при бэкапе логов${NC}"
fi

# Очистка старых бэкапов (старше 7 дней)
echo "Очищаем старые бэкапы..."
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete

# Показываем информацию о созданных бэкапах
echo ""
echo "=== ИНФОРМАЦИЯ О БЭКАПАХ ==="
echo "Созданные файлы:"
ls -lh $BACKUP_DIR/*$DATE* 2>/dev/null || echo "Файлы не найдены"

echo ""
echo "Общий размер бэкапов:"
du -sh $BACKUP_DIR

echo ""
echo "$(date): Резервное копирование завершено" >> $LOG_FILE
echo -e "${GREEN}Резервное копирование завершено${NC}"
echo "Лог сохранен в: $LOG_FILE"
echo ""
echo -e "${YELLOW}Для полного бэкапа рекомендуется запускать: sudo ./backup.sh${NC}"

