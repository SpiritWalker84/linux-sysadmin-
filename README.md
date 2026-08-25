# Linux / инфраструктура

Стенды и скрипты с практики администрирования: Docker Compose, nginx, БД, Zabbix, bash.

Это **свой контур**, не прод заказчика. Задача — показать, что стек поднимается, логи читаются, бэкап и мониторинг не «из туториала на одну команду».

## Что внутри

| Каталог | Что это | Запуск |
|---------|---------|--------|
| [`nginx-php-mysql/`](nginx-php-mysql/) | nginx + PHP-FPM + MySQL, страница с проверкой БД | `docker compose up -d` → http://localhost:8080 |
| [`zabbix_postgresql/`](zabbix_postgresql/) | Zabbix 7 + PostgreSQL + агент | скопировать `.env*.example` → `docker compose up -d` → http://localhost:8081 |
| [`scripts/`](scripts/) | bash: диск, службы, бэкап, логи, CPU | на Ubuntu/Debian, см. README в папке |

## Стек

Linux (Debian/Ubuntu) · Docker Compose · nginx · PHP-FPM · MySQL · PostgreSQL · Zabbix · bash

Чего **нет** в этом репозитории (и не надо приписывать в резюме): Ansible, Terraform, Grafana, репликация Postgres, «enterprise production».

## Быстрый старт

```bash
git clone https://github.com/SpiritWalker84/linux-sysadmin-.git
cd linux-sysadmin-/nginx-php-mysql
docker compose up -d --build
```

Zabbix: в `zabbix_postgresql/` скопировать example-файлы в `.env.*`, поменять пароль, затем `docker compose up -d`.

## Зачем так

На собесе открывают репозиторий. Здесь можно пройтись по compose, конфигу nginx и скриптам — без «готовой к балансировке архитектуры» в README.
