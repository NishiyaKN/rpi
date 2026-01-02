#!/bin/bash

# CONFIGURATION
TARGET_IP="<YOUR_IP>" # VPN Tunnel IP is recommended
TOKEN="<YOUR_BOT_TOKEN>"
CHAT_ID="<YOUR_CHAT_ID>"
STATE_FILE="/tmp/home_server_state"

# Ping the server (3 attempts, 1s timeout)
if ping -c 3 -W 1 "$TARGET_IP" > /dev/null; then
    # If reachable, check if it was previously down
    if [ -f "$STATE_FILE" ]; then
        MESSAGE="✅Server is back ONLINE."
        curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="$MESSAGE"
        rm "$STATE_FILE"
    fi
else
    # If unreachable, check if we already sent an alert
    if [ ! -f "$STATE_FILE" ]; then
        MESSAGE="⚠️ ALERT: Server is UNREACHABLE from OCI."
        curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="$MESSAGE"
        touch "$STATE_FILE"
    fi
fi
