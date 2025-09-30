<?php
$mysqli = new mysqli('db', 'testuser', 'testpass', 'testdb');

if ($mysqli->connect_errno) {
    echo "Ошибка подключения к MySQL: (" . $mysqli->connect_errno . ") " . $mysqli->connect_error;
} else {
    echo "Успешное подключение к MySQL!<br>";
}

phpinfo();
?>
