# Пример docker-compose: nginx + PHP + MySQL

Минимальный стек для тестирования web-приложений на PHP с использованием nginx и MySQL

## Как использовать

1. Клонируйте репозиторий:
    ```
    git clone https://github.com/SpiritWalker84/linux-sysadmin-/tree/main/nginx-php-mysql
    cd nginx-php-mysql
    ```
2. Запустите сервисы:
    ```
    docker compose build
    docker-compose up -d
    ```
3. Откройте в браузере:
    ```
    http://localhost:8080
    ```

## Особенности реализации

- nginx обрабатывает входящие HTTP-запросы и проксирует PHP-файлы на php-fpm.
- php-fpm собран на основе кастомного Dockerfile с предустановленным расширением mysqli (необходим для работы с MySQL в PHP).
- MySQL развёрнут как отдельный сервис, начинается с тестовой базы.

## Демо-страница

- В каталоге /php лежит файл index.php, который показывает подключение к MySQL и выводит phpinfo.

---

 Остановка и удаление:
```
docker-compose down

## Примечание

 Для стабильной работы расширения mysqli оно устанавливается один раз на этапе сборки Docker-образа в Dockerfile, а не каждый раз при запуске контейнера.  
Это предотвращает возможные ошибки запуска в режиме -d и избавляет от 502 Bad Gateway.
