#!/bin/bash

# Параметры порогов
CPU_LIMIT=80           # в процентах
MEM_LIMIT=90           # в процентах
LOG_FILE="/var/log/load_monitor.log"

# Цвета для вывода
RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Проверка прав на запись в лог-файл
if ! touch "$LOG_FILE" &>/dev/null; then
    echo -e "${YELLOW}ВНИМАНИЕ:${NC} Для корректной работы журнала ($LOG_FILE) скрипт нужно запускать с правами sudo!"
fi

# Получение средней загрузки CPU (использовано, а не idle)
CPU_IDLE=$(top -bn1 | grep "%Cpu" | awk '{for(i=1;i<=NF;i++) if ($i ~ /id/) print $(i-1)}' | head -1)
CPU_USED=$(echo "100 - $CPU_IDLE" | bc | awk '{printf("%.0f", $0)}')

# Получение используемой памяти (%)
MEM_USED=$(free | awk '/Mem:/ {printf("%.0f", $3/$2 * 100.0)}')

# Время
NOW=$(date '+%Y-%m-%d %H:%M:%S')

# Проверка порогов и уведомление
if [[ "$CPU_USED" -ge "$CPU_LIMIT" ]]; then
    echo -e "$NOW ${RED}ВЫСОКАЯ ЗАГРУЗКА CPU:${NC} $CPU_USED%" | tee -a "$LOG_FILE"
fi

if [[ "$MEM_USED" -ge "$MEM_LIMIT" ]]; then
    echo -e "$NOW ${RED}ВЫСОКОЕ ИСПОЛЬЗОВАНИЕ ОЗУ:${NC} $MEM_USED%" | tee -a "$LOG_FILE"
fi

# Топ-5 процессов по использованию CPU
echo -e "\n--- ТОП-5 процессов по CPU ---"
ps -eo pid,user,comm,%cpu,%mem --sort=-%cpu | head -n 6

# Топ-5 процессов по использованию памяти
echo -e "\n--- ТОП-5 процессов по ОЗУ ---"
ps -eo pid,user,comm,%cpu,%mem --sort=-%mem | head -n 6

# Итоговый лог
echo "$NOW | CPU: $CPU_USED% | ОЗУ: $MEM_USED%" >> "$LOG_FILE"

