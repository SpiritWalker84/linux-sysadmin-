#!/bin/bash

# Скрипт для мониторинга места на дисках в Ubuntu

echo "=== МОНИТОРИНГ ДИСКОВОГО ПРОСТРАНСТВА ==="
echo "Запуск: $(date)"
echo ""

# Пороговое значение в процентах, при котором срабатывает предупреждение
THRESHOLD=80

# Проверяем все диски в системе, исключая временные файловые системы
df -h | grep -v tmpfs | grep -v udev | while read line
do
    # Извлекаем информацию о разделе
    PARTITION=$(echo $line | awk '{print $1}')
    USAGE_PERCENT=$(echo $line | awk '{print $5}' | sed 's/%//')
    MOUNT_POINT=$(echo $line | awk '{print $6}')
    
    # Проверяем, что получили числовое значение (защита от пустых строк)
    if [ ! -z "$USAGE_PERCENT" ] && [ "$USAGE_PERCENT" -eq "$USAGE_PERCENT" ] 2>/dev/null; then
        # Сравниваем с пороговым значением
        if [ "$USAGE_PERCENT" -gt "$THRESHOLD" ]; then
            echo "  ВНИМАНИЕ! Раздел $PARTITION ($MOUNT_POINT) заполнен на $USAGE_PERCENT%"
            echo "   Необходимо очистить место!"
        else
            echo "$PARTITION ($MOUNT_POINT): $USAGE_PERCENT% - норма"
        fi
    fi
done

echo ""
echo "=== ДОПОЛНИТЕЛЬНАЯ ИНФОРМАЦИЯ ==="

# Показываем самые большие папки в домашней директории
echo "Самые большие папки в /home:"
du -h /home --max-depth=1 2>/dev/null | sort -hr | head -10

# Проверяем размер лог-файлов
echo ""
echo "Размер лог-файлов в /var/log:"
sudo du -h /var/log/* 2>/dev/null | sort -hr | head -5

echo ""
echo "Мониторинг завершён: $(date)"

