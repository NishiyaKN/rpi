#!/bin/sh

LOG="/var/log/speedtest.csv"
COUNT="${1:-10}"

awk -F',' '
NR>1 {
  printf "%-25s  ↓ %6.2f Mbps  ↑ %6.2f Mbps  ping %5.1f ms\n",
  $1, $3/1000000, $4/1000000, $2
}
' "$LOG" | tail -n "$COUNT"

