#!/bin/bash
# Network watchdog — reboots if router unreachable for 5 consecutive checks
# Installed at /usr/local/bin/network-watchdog.sh, executed by network-watchdog.timer every 60s
GATEWAY="192.168.86.1"
COUNTER_FILE="/var/run/network-watchdog.count"
LOG_FILE="/var/log/network-watchdog.log"
MAX_FAILURES=5

mkdir -p /var/run
[ -f "$COUNTER_FILE" ] || echo 0 > "$COUNTER_FILE"
COUNT=$(cat "$COUNTER_FILE")

if ping -c 1 -W 3 "$GATEWAY" > /dev/null 2>&1; then
    if [ "$COUNT" -gt 0 ]; then
        echo "$(date -Iseconds) recovered after $COUNT failures" >> "$LOG_FILE"
    fi
    echo 0 > "$COUNTER_FILE"
else
    COUNT=$((COUNT + 1))
    echo "$COUNT" > "$COUNTER_FILE"
    echo "$(date -Iseconds) ping failed (count=$COUNT/$MAX_FAILURES)" >> "$LOG_FILE"
    if [ "$COUNT" -ge "$MAX_FAILURES" ]; then
        echo "$(date -Iseconds) REBOOTING — $MAX_FAILURES consecutive failures" >> "$LOG_FILE"
        /sbin/reboot
    fi
fi
