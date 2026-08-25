#!/usr/bin/env bash
# Снимок CPU/RAM и топ процессов. Пороги: CPU_LIMIT, MEM_LIMIT (%).
set -u

CPU_LIMIT="${CPU_LIMIT:-80}"
MEM_LIMIT="${MEM_LIMIT:-90}"
LOG_FILE="${LOG_FILE:-$HOME/load_monitor.log}"

cpu_used() {
  local u1 n1 s1 i1 u2 n2 s2 i2 idle total
  read -r _ u1 n1 s1 i1 _ < /proc/stat
  sleep 0.5
  read -r _ u2 n2 s2 i2 _ < /proc/stat
  idle=$((i2 - i1))
  total=$(( (u2 - u1) + (n2 - n1) + (s2 - s1) + idle ))
  if (( total <= 0 )); then
    echo 0
    return
  fi
  echo $(( 100 * (total - idle) / total ))
}

MEM_USED=$(awk '/MemTotal:/{t=$2} /MemAvailable:/{a=$2} END{if(t>0) printf "%d", (t-a)*100/t; else print 0}' /proc/meminfo)
CPU_USED=$(cpu_used)
NOW=$(date '+%Y-%m-%d %H:%M:%S')

echo "$NOW  CPU ${CPU_USED}%  RAM ${MEM_USED}%"

if (( CPU_USED >= CPU_LIMIT )); then
  echo "порог CPU (${CPU_LIMIT}%) превышен"
fi
if (( MEM_USED >= MEM_LIMIT )); then
  echo "порог RAM (${MEM_LIMIT}%) превышен"
fi

echo
echo "топ CPU:"
ps -eo pid,user,comm,%cpu,%mem --sort=-%cpu | head -n 6
echo
echo "топ RAM:"
ps -eo pid,user,comm,%cpu,%mem --sort=-%mem | head -n 6

if mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null && touch "$LOG_FILE" 2>/dev/null; then
  echo "$NOW | CPU: ${CPU_USED}% | RAM: ${MEM_USED}%" >> "$LOG_FILE"
fi
