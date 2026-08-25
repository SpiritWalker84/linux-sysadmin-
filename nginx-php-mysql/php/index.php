<?php
declare(strict_types=1);

$host = getenv('MYSQL_HOST') ?: 'db';
$user = getenv('MYSQL_USER') ?: 'testuser';
$pass = getenv('MYSQL_PASSWORD') ?: 'testpass';
$db   = getenv('MYSQL_DATABASE') ?: 'testdb';

$mysqli = @new mysqli($host, $user, $pass, $db);

header('Content-Type: text/html; charset=utf-8');
echo '<h1>LEMP стенд</h1>';

if ($mysqli->connect_errno) {
    http_response_code(503);
    echo '<p>MySQL: ошибка (' . $mysqli->connect_errno . ') ' . htmlspecialchars($mysqli->connect_error) . '</p>';
    exit;
}

echo '<p>MySQL: ок, сервер ' . htmlspecialchars($mysqli->server_info) . '</p>';
$mysqli->close();
echo '<hr><p>PHP ' . PHP_VERSION . '</p>';
