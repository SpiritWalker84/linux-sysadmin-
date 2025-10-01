 Zabbix Monitoring Stack - Docker Compose

Полнофункциональная система мониторинга Zabbix в контейнерах Docker. Проект демонстрирует навыки администрирования Linux и работы с контейнеризированными приложениями.

##  Технологии
- Docker & Docker Compose
- Zabbix 6.4 + PostgreSQL 15
- Nginx + Alpine Linux

##  Запуск

1. Отредактируйсте .env файлы с паролями для PostgreSQL и Zabbix
2. Запустите стек:
sudo docker compose up -d

3. Проверьте статус:
sudo docker compose ps


##  Основные команды
# Запуск/остановка
sudo docker compose up -d
sudo docker compose down

# Мониторинг
sudo docker compose logs -f
sudo docker stats


## Доступ
- Web интерфейс: http://localhost
- Логин/пароль по умолчанию: Admin / zabbix

## Данные
- PostgreSQL данные, экспорты и конфигурации сохраняются в Docker volumes
- Автоматический перезапуск контейнеров при сбоях

