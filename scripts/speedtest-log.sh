#!/bin/bash

LOG="/var/log/speedtest.csv"

if [ ! -f "$LOG" ]; then
  echo "timestamp,ping_ms,download_bps,upload_bps" > "$LOG"
fi

speedtest --accept-license --accept-gdpr -f csv | \
awk -F',' '
{
  gsub(/"/,"",$0)
  printf "%s,%.2f,%d,%d\n",
    strftime("%Y-%m-%dT%H:%M:%S%z"),
    $3,
    $8,
    $9
}' >> "$LOG"

