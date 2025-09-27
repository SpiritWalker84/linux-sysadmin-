#!/bin/bash

# Скрипт для проверки состояния системных служб в Ubuntu

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== ПРОВЕРКА СИСТЕМНЫХ СЛУЖБ ==="
echo "Запуск: $(date)"
echo ""

# Список служб для проверки (можно добавлять свои)
SERVICES=("ssh" "nginx" "apache2" "mysql" "postgresql" "cron" "systemd-logind")

# Переменная для отслеживания ошибок
ERROR_COUNT=0

# Проверяем каждую службу из списка
for SERVICE in "${SERVICES[@]}"; do
    # Проверяем, установлена ли служба в системе
    if systemctl list-unit-files | grep -q "$SERVICE.service"; then
        # Проверяем статус службы
        if sudo systemctl is-active --quiet $SERVICE; then
            echo -e "${GREEN}$SERVICE: ЗАПУЩЕНА${NC}"
        else
            echo -e "${RED}$SERVICE: ОСТАНОВЛЕНА${NC}"
            echo "   Пытаюсь запустить..."
            
            # Пробуем запустить службу
            sudo systemctl start $SERVICE
            sleep 2
            
            # Проверяем, удалось ли запустить
            if sudo systemctl is-active --quiet $SERVICE; then
                echo -e "${GREEN}   $SERVICE успешно запущена${NC}"
            else
                echo -e "${RED}   Не удалось запустить $SERVICE${NC}"
                ((ERROR_COUNT++))
            fi
        fi
    else
        echo "$SERVICE: не установлена"
    fi
done

echo ""
echo "=== РЕЗУЛЬТАТ ПРОВЕРКИ ==="

if [ $ERROR_COUNT -eq 0 ]; then
    echo -e "${GREEN}Все службы работают нормально${NC}"
else
    echo -e "${RED}Найдено проблем: $ERROR_COUNT${NC}"
    echo "   Требуется вмешательство администратора"
fi

echo ""
echo "Проверка завершена: $(date)"

