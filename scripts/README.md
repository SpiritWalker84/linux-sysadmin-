# Скрипты (Ubuntu / Debian)

Утилиты для стенда: диск, службы, бэкап, логи, нагрузка. Не замена Zabbix/logrotate/cron из коробки.

Проверялось на Ubuntu 22.04 / Debian 12. Запуск **на Linux**, не в PowerShell.

```bash
cd scripts
chmod +x *.sh
./system_info.sh
./disk_monitor.sh
./cpu_load.sh
./servicechecker.sh
```

| Скрипт | Что делает | Осторожно |
|--------|------------|-----------|
| `system_info.sh` | ОС, диск, RAM, сеть, наличие служб | — |
| `disk_monitor.sh` | `%` по разделам, крупное в `/home` | порог `THRESHOLD=80` |
| `cpu_load.sh` | CPU за 0.5 с, RAM, топ процессов | лог в `~/load_monitor.log` |
| `servicechecker.sh` | статус unit'ов; код 1 если что-то лежит | start только `--restart` |
| `backup.sh` | tar home + `/etc` | каталог `/var/backups/linux-sysadmin` (не всё `/var/backups`) |
| `db_backup.sh` | `mysqldump` / `pg_dumpall` если есть клиент | нужен доступ к БД |
| `logcleaner.sh` | кто больше `MAX_SIZE_MB` | truncate только с `--rotate` |

Примеры:

```bash
sudo BACKUP_DIR=/var/backups/linux-sysadmin ./backup.sh
./servicechecker.sh --restart
./logcleaner.sh --rotate    # только если понимаешь, что режешь логи
```
