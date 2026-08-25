#!/usr/bin/env bash
# Заполненность разделов. Порог: THRESHOLD (%).
set -u

THRESHOLD="${THRESHOLD:-80}"

echo "=== диск ($(date)) ==="

df -PTH -x tmpfs -x devtmpfs -x squashfs -x overlay | awk -v th="$THRESHOLD" '
NR==1 { next }
{
  gsub(/%/, "", $6)
  if ($6+0 >= th+0)
    printf "ВНИМАНИЕ  %s  %s  %s%%\n", $1, $7, $6
  else
    printf "ок        %s  %s  %s%%\n", $1, $7, $6
}'

echo
echo "крупное в /home (если есть):"
if [[ -d /home ]]; then
  du -h --max-depth=1 /home 2>/dev/null | sort -hr | head -8
fi

if [[ -d /var/log ]] && [[ -r /var/log ]]; then
  echo
  echo "крупное в /var/log:"
  du -h --max-depth=1 /var/log 2>/dev/null | sort -hr | head -8
fi
