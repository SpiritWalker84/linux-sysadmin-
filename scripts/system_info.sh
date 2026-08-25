#!/usr/bin/env bash
# Краткий отчёт по хосту (Debian/Ubuntu).
set -u

echo "=== система ($(date)) ==="
echo "хост: $(hostname)   uptime: $(uptime -p 2>/dev/null || uptime)"
echo "user: $(whoami)"

if [[ -r /etc/os-release ]]; then
  # shellcheck source=/dev/null
  . /etc/os-release
  echo "ОС: ${PRETTY_NAME:-?}   ядро: $(uname -r) $(uname -m)"
fi

echo
echo "CPU: $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')  ядер: $(nproc)"
echo
echo "диск:"
df -hT -x tmpfs -x devtmpfs | awk 'NR==1 || /^\/dev\//'
echo
echo "память:"
free -h
echo
echo "сеть (IPv4):"
ip -br -4 addr show 2>/dev/null || ip -4 addr
echo
echo "службы:"
for service in ssh sshd nginx apache2 mysql mariadb postgresql docker; do
  if systemctl list-unit-files "${service}.service" &>/dev/null && \
     systemctl cat "${service}.service" &>/dev/null; then
    if systemctl is-active --quiet "$service"; then
      echo "  $service: запущена"
    else
      echo "  $service: есть unit, не запущена"
    fi
  fi
done

if command -v sensors &>/dev/null; then
  echo
  echo "температура:"
  sensors | grep -E 'Core|Package|Tctl' | head -4
fi
