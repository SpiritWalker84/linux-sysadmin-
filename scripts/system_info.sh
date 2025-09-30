#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== РАСШИРЕННЫЙ ОТЧЁТ О СИСТЕМЕ ==="
echo "Время формирования: $(date)"
echo "Пользователь: $(whoami)"
echo "----------------------------------------"

echo "1. Имя хоста и UPTIME:"
echo "   Хост: $(hostname)"
echo "   Время работы: $(uptime -p)"
echo "----------------------------------------"

echo "2. Информация об ОС и ядре:"
if [ -f /etc/os-release ]; then
    source /etc/os-release
    echo "   Дистрибутив: $PRETTY_NAME"
    echo "   Версия: $VERSION"
else
    echo "   Дистрибутив: Не удалось определить"
fi
echo "   Ядро: $(uname -r)"
echo "   Архитектура: $(uname -m)"
echo "----------------------------------------"

echo "3. Процессор:"
echo "   Модель: $(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ *//')"
echo "   Ядер: $(nproc)"
echo "   Тактовая частота: $(grep "cpu MHz" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ *//') MHz"
echo "----------------------------------------"

echo "4. Использование диска:"
df -h | grep -E '^/dev/' | awk '{print "   " $1 ": " $3 " из " $2 " (" $5 ")"}'
echo "----------------------------------------"

echo "5. Использование памяти:"
free -h | awk '
NR==2 {printf "   Оперативная память: Использовано %s из %s (%.0f%%)\n", $3, $2, $3/$2*100}
NR==3 {
    if ($2 != 0)
        printf "   Swap: Использовано %s из %s (%.0f%%)\n", $3, $2, $3/$2*100
    else
        print "   Swap: отсутствует или выключен"
}'
echo "----------------------------------------"

echo "6. Загрузка системы:"
echo "   Средняя загрузка (1, 5, 15 мин):$(uptime | awk -F'load average:' '{print $2}')"
echo "----------------------------------------"

echo "7. Сетевые интерфейсы:"
ip -4 addr show | grep inet | awk '{print "   " $2 " на интерфейсе " $7}'
echo "----------------------------------------"

echo "8. Основные системные службы:"
services=("ssh" "nginx" "apache2" "mysql" "postgresql" "docker")
for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo -e "   ${GREEN}RUNNING${NC} $service: запущена"
    elif systemctl is-enabled --quiet "$service" 2>/dev/null; then
        echo -e "   ${YELLOW}STOPPED${NC} $service: установлена, но не запущена"
    else
        echo -e "   ${RED}NOT FOUND${NC} $service: служба не найдена"
    fi
done
echo "----------------------------------------"

echo "9. Температура CPU (если доступно):"
if command -v sensors &> /dev/null; then
    sensors | grep -E "Core|Package" | head -2
else
    echo "   Информация о температуре недоступна (установите пакет lm-sensors)"
fi
echo "----------------------------------------"

echo "Отчёт завершён."

