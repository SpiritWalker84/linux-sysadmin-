# nginx + PHP-FPM + MySQL

Минимальный LEMP в Compose: проверка, что php-fpm видит БД, nginx отдаёт PHP.

## Запуск

```bash
cd nginx-php-mysql
docker compose up -d --build
```

Открыть http://localhost:8080 — должно быть «MySQL: ок».

Остановка: `docker compose down` (том с данными БД сохранится). Полный сброс: `docker compose down -v`.

## Состав

- **nginx 1.27** — статика и FastCGI на php:9000  
- **PHP 8.3-FPM** — расширение mysqli  
- **MySQL 8.4** — healthcheck, стендовые пароли только для локалки  

Пароли в compose учебные. В прод так не выкладывать.
