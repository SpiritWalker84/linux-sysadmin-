#!/bin/bash

# Скрипт бэкапа баз данных MySQL и PostgreSQL
# Автор: Junior Administrator

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Настройки
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="/var/backups/databases"
LOG_FILE="$BACKUP_DIR/db_backup.log"

# Создание директории для бэкапов
echo "Создаем директорию для бэкапов баз данных..."
mkdir -p "$BACKUP_DIR" 2>/dev/null

if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${RED}Ошибка: Не удалось создать директорию $BACKUP_DIR${NC}"
    echo "Возможно, недостаточно прав. Попробуйте запустить с sudo:"
    echo "sudo mkdir -p $BACKUP_DIR"
    echo "sudo chown $(whoami) $BACKUP_DIR"
    exit 1
fi

# Логирование начала
echo "$(date): Начало бэкапа баз данных" >> "$LOG_FILE"

# Функция для проверки установленных утилит
check_commands() {
    local missing_commands=()
    
    if ! command -v mysqldump &> /dev/null; then
        missing_commands+=("mysqldump")
    fi
    
    if ! command -v pg_dump &> /dev/null; then
        missing_commands+=("pg_dump")
    fi
    
    if ! command -v pg_dumpall &> /dev/null; then
        missing_commands+=("pg_dumpall")
    fi
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        echo -e "${YELLOW}Предупреждение: Не найдены утилиты: ${missing_commands[*]}${NC}"
        echo "Установите их командами:"
        echo "MySQL: sudo apt-get install mysql-client"
        echo "PostgreSQL: sudo apt-get install postgresql-client"
        return 1
    fi
    return 0
}

# Проверяем доступные утилиты
echo "Проверяем доступные утилиты для бэкапа..."
check_commands

# 1. Бэкап MySQL баз данных
echo ""
echo "=== БЭКАП MYSQL БАЗ ДАННЫХ ==="

if command -v mysqldump &> /dev/null; then
    # Способ 1: Бэкап всех баз (требует права root)
    if [ "$EUID" -eq 0 ]; then
        echo "Создаем полный бэкап всех MySQL баз..."
        mysqldump --all-databases > "$BACKUP_DIR/mysql_full_$DATE.sql" 2>> "$LOG_FILE"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Полный бэкап MySQL создан: mysql_full_$DATE.sql${NC}"
            echo "$(date): Полный бэкап MySQL завершен успешно" >> "$LOG_FILE"
        else
            echo -e "${RED}Ошибка при создании полного бэкапа MySQL${NC}"
            echo "$(date): Ошибка полного бэкапа MySQL" >> "$LOG_FILE"
        fi
    else
        echo -e "${YELLOW}Пропускаем полный бэкап MySQL (требуются права root)${NC}"
    fi
    
    # Способ 2: Бэкап конкретных баз (можно указать вручную)
    echo "Бэкап отдельных MySQL баз..."
    
    # Список баз для бэкапа (можно изменить под свои нужды)
    MYSQL_DATABASES=("information_schema" "mysql" "performance_schema")
    
    for db in "${MYSQL_DATABASES[@]}"; do
        echo "Бэкап базы: $db"
        mysqldump "$db" > "$BACKUP_DIR/mysql_${db}_$DATE.sql" 2>> "$LOG_FILE"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}  ✓ Бэкап $db создан${NC}"
        else
            echo -e "${RED}  ✗ Ошибка бэкапа $db${NC}"
        fi
    done
    
else
    echo -e "${YELLOW}MySQL утилиты не найдены, пропускаем бэкап${NC}"
fi

# 2. Бэкап PostgreSQL баз данных
echo ""
echo "=== БЭКАП POSTGRESQL БАЗ ДАННЫХ ==="

if command -v pg_dump &> /dev/null; then
    # Способ 1: Бэкап всех баз (требует права postgres)
    echo "Создаем полный бэкап PostgreSQL..."
    
    if sudo -u postgres pg_dumpall > "$BACKUP_DIR/postgresql_full_$DATE.sql" 2>> "$LOG_FILE"; then
        echo -e "${GREEN}Полный бэкап PostgreSQL создан: postgresql_full_$DATE.sql${NC}"
        echo "$(date): Полный бэкап PostgreSQL завершен успешно" >> "$LOG_FILE"
    else
        echo -e "${RED}Ошибка при создании полного бэкапа PostgreSQL${NC}"
        echo "Попробуйте вручную: sudo -u postgres pg_dumpall > backup.sql"
        echo "$(date): Ошибка полного бэкапа PostgreSQL" >> "$LOG_FILE"
    fi
    
    # Способ 2: Бэкап конкретных баз
    echo "Бэкап отдельных PostgreSQL баз..."
    
    # Получаем список баз от пользователя postgres
if command -v psql &> /dev/null; then
        PGSQL_DATABASES=$(sudo -u postgres psql -l -t | cut -d'|' -f1 | sed 's/ //g' | grep -v '^$' | grep -v 'template' | grep -v 'postgres')
        
        for db in $PGSQL_DATABASES; do
            if [ -n "$db" ]; then
                echo "Бэкап базы: $db"
                sudo -u postgres pg_dump "$db" > "$BACKUP_DIR/postgresql_${db}_$DATE.sql" 2>> "$LOG_FILE"
                
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}  ✓ Бэкап $db создан${NC}"
                else
                    echo -e "${RED}  ✗ Ошибка бэкапа $db${NC}"
                fi
            fi
        done
    fi
    
else
    echo -e "${YELLOW}PostgreSQL утилиты не найдены, пропускаем бэкап${NC}"
fi

# 3. Очистка старых бэкапов
echo ""
echo "=== ОЧИСТКА СТАРЫХ БЭКАПОВ ==="

OLD_FILES_COUNT=$(find "$BACKUP_DIR" -name "*.sql" -mtime +7 | wc -l)

if [ "$OLD_FILES_COUNT" -gt 0 ]; then
    echo "Удаляем бэкапы старше 7 дней..."
    find "$BACKUP_DIR" -name "*.sql" -mtime +7 -delete
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Удалено старых бэкапов: $OLD_FILES_COUNT файлов${NC}"
        echo "$(date): Удалено старых бэкапов: $OLD_FILES_COUNT" >> "$LOG_FILE"
    else
        echo -e "${YELLOW}Ошибка при удалении старых бэкапов${NC}"
    fi
else
    echo -e "${GREEN}Старые бэкапы для удаления не найдены${NC}"
fi

# 4. Итоговая информация
echo ""
echo "=== ИТОГИ БЭКАПА ==="
echo "Созданные файлы:"
ls -lh "$BACKUP_DIR"/*"$DATE"* 2>/dev/null || echo "Файлы не найдены"

echo ""
echo "Общий размер бэкапов:"
du -sh "$BACKUP_DIR"

echo ""
echo "Лог сохранен в: $LOG_FILE"
echo "$(date): Бэкап баз данных завершен" >> "$LOG_FILE"
echo -e "${GREEN}Бэкап баз данных завершен!${NC}"

# 5. Рекомендации для junior администратора
echo ""
echo "=== РЕКОМЕНДАЦИИ ==="
echo "1. Для автоматизации добавьте в cron:"
echo "   0 2 * * * /путь/к/скрипту/db_backup.sh"
echo ""
echo "2. Проверьте права доступа к файлам:"
echo "   ls -la $BACKUP_DIR/*.sql"
echo ""
echo "3. Для восстановления базы используйте:"
echo "   MySQL: mysql -u user -p database < backup_file.sql"
echo "   PostgreSQL: psql -U user -d database -f backup_file.sql"    
