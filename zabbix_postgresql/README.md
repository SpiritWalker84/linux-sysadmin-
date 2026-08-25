# Zabbix + PostgreSQL

Стенд мониторинга в Compose: сервер, веб (nginx внутри образа Zabbix), агент, Postgres.

## Запуск

```bash
cd zabbix_postgresql
cp .env.postgresql.example .env.postgresql
cp .env.zabbix-server.example .env.zabbix-server
cp .env.zabbix-agent.example .env.zabbix-agent
# один и тот же пароль в postgresql и zabbix-server
docker compose up -d
```

Веб: http://localhost:8081  
Логин по умолчанию Zabbix: `Admin` / `zabbix` (сменить после входа).

Первый старт БД может занять минуту-две.

## Что смотреть на собесе

- `docker compose ps` / `logs`
- volumes: данные Postgres живут между `down`/`up`
- агент в той же сети, без `privileged` — метрики контейнера, не всего хоста

Остановка: `docker compose down`. Сброс данных: `docker compose down -v`.
