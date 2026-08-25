# Скрипты (Ubuntu / Debian)

Мелкие bash-утилиты для повседневки. Не «система мониторинга предприятия» — проверка диска, служб, бэкап, логи, нагрузка.

Проверялось на Ubuntu 22.04 / Debian 12. Запуск с хоста, не из Windows.

```bash
cd scripts
chmod +x *.sh
./system_info.sh
./disk_monitor.sh
```

| Скрипт | Зачем |
|--------|--------|
| `system_info.sh` | ОС, диск, память, сеть |
| `disk_monitor.sh` | заполненность разделов, крупные каталоги |
| `cpu_load.sh` | пороги CPU/RAM, топ процессов |
| `servicechecker.sh` | статус systemd-служб; перезапуск только с `--restart` |
| `backup.sh` | home + /etc, ротация старше 7 дней (логи — с root) |
| `db_backup.sh` | mysqldump / pg_dump, если утилиты есть |
| `logcleaner.sh` | ротация больших логов, journal (осторожно, лучше на стенде) |

`backup.sh` пишет в `/var/backups` — обычно нужен `sudo`.
